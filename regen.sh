#!/bin/sh
# Rebuild shellcheck-fixes.json from scratch from a clone of the shellcheck wiki
# and splice it into shck between the #__SHCK_FIXES_ markers.
# Usage: regen.sh [WIKI_DIR] [OUT]
#   WIKI_DIR  clone of https://github.com/koalaman/shellcheck.wiki (shallow clone suffices: git clone --depth 1; default: /tmp/opencode/shellcheck.wiki)
#   OUT       output dataset (default: /tmp/opencode/shellcheck-fixes.json; the real product is the splice into shck)
# Schema per entry: { code, title, fix, rationale, problematicCode, correctCode }.
# fix is the wiki page title (the repair rule used for the hand-set entries).
# Pages without Problematic/Correct/Rationale sections (parser-error codes) yield empty entries.
set -eu

PROGDIR="$(realpath -m "$0")"
PROGDIR="${PROGDIR%/*}"

WIKI="${1:-/tmp/opencode/shellcheck.wiki}"
OUT="${2:-/tmp/opencode/shellcheck-fixes.json}"

case "${1:-}" in
    -h|--help)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
esac

if ! ls "$WIKI"/SC*.md >/dev/null 2>&1; then
    echo "regen: no SC*.md pages in $WIKI (clone it first: git clone --depth 1 https://github.com/koalaman/shellcheck.wiki)" >&2
    exit 2
fi

section() {
    tr -d '\r' < "$2" | awk -v sec="$1" '
        /^#{2,4} *Problematic code/ { mode=(sec=="pc"); next }
        /^#{2,4} *Correct code/     { mode=(sec=="cc"); next }
        /^#{2,4} *Rationale/        { mode=(sec=="rat"); next }
        /^#{2,4} / { mode=0 }
        mode {
            if (sec=="rat") {
                if ($0=="") { if (started) print; next }
                started=1; print; next
            }
            if ($0 ~ /^```/) { infence = !infence; next }
            if (infence) print
        }
    '
}

: > "$OUT.jsonl"
for f in "$WIKI"/SC*.md; do
    key="${f##*/}"
    key="${key%.md}"
    title="$(tr -d '\r' < "$f" | sed -n 's/^#\{1,3\} *//p' | head -1)"
    pc="$(section pc "$f")"
    cc="$(section cc "$f")"
    rat="$(section rat "$f")"
    jq -n -c --arg k "$key" --arg t "$title" --arg p "$pc" --arg c "$cc" --arg r "$rat" \
        '{key: $k, title: $t, pc: $p, cc: $c, rat: $r}' >> "$OUT.jsonl"
done

jq -n --slurpfile wiki "$OUT.jsonl" '
    ($wiki | sort_by(.key) | map({
        key: .key,
        value: {
            code: .key,
            correctCode: .cc,
            fix: .title,
            problematicCode: .pc,
            rationale: .rat,
            title: .title
        }
    }) | from_entries)
' > "$OUT"

count="$(jq 'length' "$OUT")"
if [ "$count" -lt 100 ]; then
    echo "regen: only $count entries in $OUT - aborting (refusing to overwrite the dataset)" >&2
    rm -f "$OUT"
    exit 2
fi

rm -f "$OUT.jsonl"

SHCK="$PROGDIR/shck"
awk -v f="$OUT" '
    /^#__SHCK_FIXES_BEGIN__$/ { print; while ((getline l < f) > 0) print l; close(f); ins=1; next }
    /^#__SHCK_FIXES_END__$/ { ins=0; print; next }
    !ins { print }
' "$SHCK" > "$SHCK.new"
mv "$SHCK.new" "$SHCK"
