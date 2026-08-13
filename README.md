# shck

ShellCheck with fix suggestions. Runs 'shellcheck --format json1 -s sh FILE' and enriches each SCxxxx comment with 'fix`, 'rationale`, 'correctCode`, 'problematicCode' looked up from 'shellcheck-fixes.json`. Output is the enriched JSON array on stdout.

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
