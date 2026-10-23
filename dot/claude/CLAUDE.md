Git Usage
---------

If a remote is based on github.com, the remote name will be `github`, not `origin`.
If this is not the case, propose to rename the remote.

I need to touch my YubiKey for commits to be signed, and for pushes to succeed.
If a commit or push fails, present a dialog to ask whether to retry.
Avoid reporting on the failed attempts and retries. I know they happened.

Tool Use
--------

If you need to create temp files, use `$TMPDIR/claude/` as base.

Markdown
--------

Prefer ASCII art:
* H1 and H2 titles must be underlined with `=` and `-` (avoid `#` and `##`).
* Format tables so that column markers align across rows.
