# shck

[ShellCheck](https://github.com/koalaman/shellcheck) wrapper with fix suggestions. Runs 'shellcheck --format json1 -s sh FILE' and enriches each SCxxxx comment with 'fix`, 'rationale`, 'correctCode`, 'problematicCode' looked up from the dataset embedded in the script. Output is the enriched JSON array on stdout.

## Requirements

- 'shellcheck`
- 'jq`

## Usage

```sh
sh shck FILE
```

Or read a script from stdin (FILE is '-' or omitted):

```sh
printf '%s\n' 'echo "hi $USER"' | sh shck
sh shck -
```

## Exit codes

- '0' - no issues found
- '1' - issues found
- '2' - usage or tool error

## Rebuilding the fix dataset

The fix dataset is embedded in `shck` between the `#__SHCK_FIXES_BEGIN__` / `#__SHCK_FIXES_END__` markers. Rebuild it from the ShellCheck wiki:

```sh
git clone --depth 1 https://github.com/koalaman/shellcheck.wiki /tmp/opencode/shellcheck.wiki
sh regen.sh                 # rebuild from /tmp/opencode/shellcheck.wiki and splice into shck
sh regen.sh /path/to/wiki   # custom wiki clone location
```

The rebuild aborts (exit 2) if the wiki clone has no `SC*.md` pages or yields fewer than 100 entries, to avoid overwriting the embedded dataset with a broken one.

## Demo

Run a test script through the tool:

```sh
TEST_SCRIPT=$(mktemp /tmp/sc_test_XXXXXX.sh)
cat >"$TEST_SCRIPT" <<'EOF'
#/bin/sh
echo "scriptname: $0"
echo "args: '$@'"
EOF
printf ">_ sh %s\n" "$TEST_SCRIPT"
sh "$TEST_SCRIPT"
printf "\n%s\n" ">_ sh shck $TEST_SCRIPT"
sh shck "$TEST_SCRIPT"
rm -f "$TEST_SCRIPT"
```
