Git Usage
---------

If a remote is based on github.com, the remote name will be `github`, not `origin`.
If this is not the case, propose to rename the remote.

I need to touch my YubiKey for commits to be signed, and for pushes to succeed.

Never add Co-Authored-By Git commit message trailers.

Sandbox
-------

Bash runs in a sandbox that only lets it write to the working directory, `$TMPDIR`,
`/tmp/claude` and `~/.settle`. Writing anywhere else in `/tmp` fails with "Operation not
permitted".

* For temporary files, scripts and test fixtures, use `$TMPDIR` or `$TMPDIR/claude` (fall back to
  `/tmp/claude` if `TMPDIR` is unset), never a bare `/tmp/...` path.

* When code under test must write to `/tmp`, make the location configurable by an environment
  variable and point it at `$TMPDIR/claude` in the test, as `CLAUDE_STATUSLINE_STATE_DIR` does.

* These shell tricks are blocked or misbehave, so avoid them:

  - Process substitution (`diff <(a) <(b)`): `/dev/fd` is denied. Write to files in `$TMPDIR`.
  - `sed -i ''`: `sed` is GNU's here, so use `sed -i` with no empty suffix argument.
  - `rm` is interactive: use `rm -f`.
  - `open` and `osascript`: blocked. Give me the command to run with the `!` prefix.

* Do not edit files that the sandbox protects (`~/.claude/settings.json`, this file, skills and
  hooks). Change their source in `~/.settle` and tell me to provision, or tell me what to add.

Markdown
--------

Prefer ASCII art:

* H1 and H2 titles must be underlined with `=` and `-` (avoid `#` and `##`).

* Format tables so that column markers align across rows.
