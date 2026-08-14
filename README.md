# shck


[ShellCheck](https://github.com/koalaman/shellcheck) is great at finding problems in shell scripts - but it often tells you *what's* wrong without telling you *how to fix it*. shck fills that gap: for every warning it also shows you the fix, the reason behind it, the code that caused it, and the corrected version.

## You need

- [`shellcheck`](https://github.com/koalaman/shellcheck#installing) - The checker itself
- [`jq`](https://stedolan.github.io/jq/download/) - Used behind the scenes for formatting

## How to use it

Point it at a script:

```sh
sh shck my-script.sh
```

That's it. You'll get a list of findings with suggested fixes. Need fancy formatting?

- 'sh shck -f markdown my-script.sh' - Nice for sharing or documentation
- 'sh shck -f ansi my-script.sh' - Colored output for the terminal

You can also paste a script in without saving it to a file:

```sh
printf '%s\n' 'echo "hi" $USER' | sh shck
```

## What the exit code means

- 0 - no problems found, you're good
- 1 - problems found in script (check the output)
- 2 - something went wrong with the shck or its usage

## Try it yourself

This runs a tiny test script through the tool so you can see it in action:

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

## For the curious: rebuilding the fix database

shck's fix suggestions are bundled right inside the script - nothing extra to download. If you want to refresh them from the official ShellCheck wiki:

```sh
git clone --depth 1 https://github.com/koalaman/shellcheck.wiki /tmp/opencode/shellcheck.wiki
sh regen.sh                 # rebuild and update shck in one go
sh regen.sh /path/to/wiki   # if you cloned it somewhere else
```

The rebuild plays it safe: if the wiki looks broken (no pages, or too few entries), it stops instead of overwriting the working data.
