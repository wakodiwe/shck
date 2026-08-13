#!/bin/sh
# shckj.sh - ShellCheck with fix suggestions (pipe-based)
set -eu

PROGPATH="$(realpath -m "$0")"
PROGDIR="${PROGPATH%/*}"
PROGNAME="${PROGPATH##*/}"

FIXES_FILE="$PROGDIR/shellcheck-fixes.json"

merge_fixes() {
    shellcheck --format json1 --shell sh "$1" |
        jq --slurpfile fixes "$FIXES_FILE" --rawfile src "$1" '
    .comments | map(
        . as $c |
            ("SC" + ($c.code|tostring)) as $k |
            $fixes[0][$k] as $f |
            ($src | split("\n") | .[($c.line)-1]) as $ln |
            $c + {
                codeLine: ($ln // ""),
                fix: ($f.fix//""),
                rationale: ($f.rationale//""),
                correctCode: ($f.correctCode//""),
                problematicCode: ($f.problematicCode//"")})'
}

# shellcheck disable=SC3043
render() {
    local format="$1"
    local columns="$2"
    shift 2

    case "$format" in
        markdown|ansi) ;;
        json)
            for f in "$@"; do
                merge_fixes "$f"
            done
            return 0
            ;;
        *)
            echo "unknown format: $format (markdown|ansi|json)" >&2
            exit 1
            ;;
    esac

    filter='.[] | '
    for col in $(printf '%s' "$columns" | tr '|' '\n'); do
        case "$col" in
            message)
                if [ "$format" = ansi ]; then
                    filter="$filter"'.message + "\n" + ("-" * 79) + "\n" + '
                else
                    filter="$filter"'"# " + .message + "\n\n" + '
                fi
                ;;
            file)
                filter="$filter"'"> " + .file + " - " + (.line|tostring) + "/" + (.column|tostring) + "\n" + '
                ;;
            codeLine)
                filter="$filter"'"> " + (.line|tostring) + " " + .codeLine + "\n" + '
                ;;
            caret)
                filter="$filter"'(((" " * .column)|tostring) + "   ־\n") + '
                ;;
            disable)
                filter="$filter"'"## Disable\n\n```sh\n# shellcheck disable=SC" + (.code|tostring) + "\n" + (.codeLine|trim) + "\n```\n\n" + '
                ;;
            fix)
                filter="$filter"'"## Fix\n\n```sh\n" + .fix + "\n```\n\n" + '
                ;;
            correctCode)
                filter="$filter"'"## Correct code\n\n```sh\n" + .correctCode + "\n```\n\n" + '
                ;;
            problematicCode)
                filter="$filter"'"## Problematic code\n\n```sh\n" + .problematicCode + "\n```\n\n" + '
                ;;
            rationale)
                filter="$filter"'"## Rationale\n\n" + .rationale + "\n\n--\n" + '
                ;;
            *)
                echo "unknown field: $col (message|file|codeLine|caret|disable|fix|correctCode|problematicCode|rationale)" >&2
                exit 1
                ;;
        esac
    done
    filter="${filter% + }"

    for f in "$@"; do
        merge_fixes "$f" | jq -r "$filter" | fmt -s -w 79
    done
}

format=json
columns="message|file|codeLine|caret|disable|fix|correctCode|problematicCode|rationale"
while [ "$#" -gt 0 ]; do
    case "$1" in
        -f|--format)
            format="${2:-json}"
            [ "$#" -ge 2 ] && shift 2 || shift
            ;;
        -c|--columns)
            columns="${2:-$columns}"
            [ "$#" -ge 2 ] && shift 2 || shift
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -eq 0 ]; then
    echo "Usage: $PROGNAME [-f|--format markdown|ansi|json] [-c|--columns field1|field2...] FILE..." >&2
    exit 1
fi

render "$format" "$columns" "$@"
