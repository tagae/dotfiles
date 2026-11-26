Git Usage
---------

If a remote is based on github.com, the remote name should be `github`, not `origin`.
If not, propose to rename the remote.

I need to touch my YubiKey for commits to be signed, and for pushes to succeed.
If a commit or push fails, present a dialog asking to retry.
Avoid reporting on the failed attempts and retries. I know they happened.

Tool Use
--------

If you need to create temp files, use `$TMPDIR/claude/` as base.

Markdown
--------

Prefer ASCII art:
* H1 and H2 titles must be underlined with `=` and `-` (avoid `#` and `##`).
* Format tables so that column markers align across rows.

Subagents
---------

I ask you to use subagents, in every session, without waiting for me to say so. In the main
session, delegate any task that matches the description of `designer`, `coder`, `cleaner`,
`optimizer`, `styler`, `hardener`, `documenter` or `tester` to that agent, including where the
description applies after a change. A subagent does its task itself and spawns no other.
