#!/bin/sh
# shckj.sh - ShellCheck with fix suggestions (pipe-based)
set -eu

PROGPATH="$(realpath -m "$0")"
PROGDIR="${PROGPATH%/*}"
PROGNAME="${PROGPATH##*/}"

FIXES_FILE="$PROGDIR/shellcheck-fixes.json"

merge_fixes() {
    shellcheck --format json1 -s sh "$1" |
        jq --slurpfile fixes "$FIXES_FILE" '
    .comments | map(
        . as $c |
            ("SC" + ($c.code|tostring)) as $k |
            $fixes[0][$k] as $f |
            $c + {
                fix: ($f.fix//""),
                rationale: ($f.rationale//""),
                correctCode: ($f.correctCode//""),
                problematicCode: ($f.problematicCode//"")})'
}

# TODO wd(): Move demo to README.md
# TODO wd(): Them remove Commands section in usage
set - demo
demo() {
    printf "%s\n\n" "# Running demo with test script"
    TEST_SCRIPT=$(mktemp /tmp/sc_test_XXXXXX.sh)
    trap "rm -f $TEST_SCRIPT" EXIT
    cat >"$TEST_SCRIPT" <<'EOF'
#/bin/sh
echo "scriptname: $0"
echo "args: '$@'"
EOF
printf ">_ sh %s\n" "$TEST_SCRIPT"
sh "$TEST_SCRIPT"
printf "\n%s\n" ">_ sh shckj.sh $TEST_SCRIPT"
merge_fixes "$TEST_SCRIPT"
}
[ "$*" = "demo" ] && demo

if [ "$#" -eq 0 ]; then
    echo "Usage: $PROGNAME FILE"
    echo "$PROGNAME demo" # to run the demo script"
    exit 1
fi
