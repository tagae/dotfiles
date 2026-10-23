Claude Code status line
=======================

One line of numbers, coloured only where something needs attention: how full the context is, what
the prompt cache will cost, what the session has cost, and how much quota is left. It makes no API
calls and is coloured for dark terminals.

Two editions show the same facts. Use whichever reads better to you.

```
clear    Opus 5.5·xh | in: 87K/200K (+478, ttl: 42m, miss: 202K ttl_expired_5m) out: 340 | $0.12 ⊂ $1.23 | up: 12m api: 4m | 5h: ↑37% ↻2h10 7d: ↗48% ↻4d3h
compact  O5.5xh ↑87K/200K (+478, ◕42m, miss: 202K ttl_expired_5m) ↓340 $0.12 ⊂ $1.23 ⚙4m/12m ⧖ 37%↑ ↻2h10 ▦ 48%↗ ↻4d3h
```

Clear spells everything out with labels and `|` dividers. Compact swaps the labels for icons, drops
the dividers, shortens the model to its initial, and draws the cache countdown with a pie.

Reading the line
----------------

| Clear             | Compact         | Meaning                                                                                                                                                      |
|-------------------|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Opus 5.5·xh`     | `O5.5xh`        | Model, then the reasoning effort: `l`, `m`, `h`, `xh` or `x` (max). No suffix when the model has none.                                                       |
| `in: 87K/200K`    | `↑87K/200K`     | Input tokens in the context, and the window size. Clear colours the tokens yellow from 60% of the window, orange from 80%, red from 90%; compact fades them. |
| `(+478, …)`       | `(+478, …)`     | The prompt cache; see below.                                                                                                                                 |
| `out: 340`        | `↓340`          | Output tokens of the last response.                                                                                                                          |
| `$0.12 ⊂ $1.23`   | `$0.12 ⊂ $1.23` | The turn's cost, contained in the session's. The last turn's stands until the new one bills something.                                                       |
| `up: 12m api: 4m` | `⚙4m/12m`       | How long the session has run, and the time spent waiting on the API. Compact gives the API time first, then the session's.                                   |
| `5h: ↑37% ↻2h10`  | `⧖ 37%↑ ↻2h10`  | Five-hour quota used, and the time until it resets.                                                                                                          |
| `7d: ↗48% ↻4d3h`  | `▦ 48%↗ ↻4d3h`  | Weekly quota used, and the time until it resets.                                                                                                             |

Durations read `45s`, `12m`, `3h05` or `2d4h`. A part with no data is left out.

The prompt cache
----------------

`+478` is how much the last response added to the context: the tokens it wrote to the cache. The
countdown is the time left before the cache expires, after which the next message has to write the
whole context again. It follows the lifetime Claude Code reports, so it holds for the 5-minute and
the 1-hour cache alike; if the lifetime is not reported, the countdown stays plain.

The countdown changes colour as the lifetime runs out:

- Clear stays plain while half the lifetime or more is left, then steps through light yellow, yellow
  and light orange (below 50%, 38% and 26% left) to orange below 15%. It never reaches red. Once
  expired it shows by how much, in orange: `ttl: -3m`.
- Compact fades it, as described below. Once expired it shows by how much, in red: `○-3m`.

Compact also draws a pie before the countdown that empties as the cache runs out: `●` `◕` `◔` `○`.

A turn that rebuilt part of the cache adds `miss: 11K ttl_expired_5m` to the bracket: the tokens
re-cached, and the likely cause. It shows on that turn only, and is never plain: yellow, orange from
50% of the context re-cached, red from 80%.

The compact fade
----------------

Compact colours the cache countdown, the input tokens and the 5h and 7d quota percentages with one
fade, and nothing else. A figure stays plain for roughly the first 40% of its range (the cache
lifetime run out, the context window or the quota used), brightens to white by about 60%, then moves
through yellow and orange, and is red from 95%. The change speeds up towards the end, so a figure
that is half full still looks calm. For the countdown, red means 5% of the lifetime is left.

Quota
-----

Percentages are quota used. Clear colours them plain below 70%, yellow from 70%, orange from 80%,
red from 90%; compact fades them. The arrow, before the figure in clear and after it in compact,
compares the share of quota left with the share of the window left, in calendar time:

| Arrow  | Quota left, against time left | Colour      |
|--------|-------------------------------|-------------|
| `↑`    | at least 1.5 times as much    | light green |
| `↗`    | 1.15 to 1.5 times as much     | light green |
| (none) | 0.87 to 1.15 times: on pace   |             |
| `↘`    | 0.67 to 0.87 times            | yellow      |
| `↓`    | under 0.67 times              | red         |

The quota belongs to the account, and other sessions spend it. This session only learns the figure
when it gets a response, so after 15 minutes without one it turns grey, gains a `?` and loses its
arrow (`5h: 32%? ↻56m`); so does a figure whose window has ended.

Setup
-----

Needs `jq`. Point the `statusLine` setting of Claude Code at the edition you want:

```json
"statusLine": {
  "type": "command",
  "command": "/path/to/statusline-compact.sh",
  "refreshInterval": 5
}
```

The countdowns only tick if the status line refreshes, which is what `refreshInterval` (in seconds)
is for. The cache figures need Claude Code 2.1.251, and the miss cause 2.1.260.

Two environment variables adjust the behaviour:

- `CLAUDE_QUOTA_STALE_SECS` changes the 15 minutes after which a quota figure goes grey.
- `CLAUDE_STATUSLINE_STATE_DIR` changes where the status line keeps what it remembers between
  renders: one small file per session, in `/tmp` by default. It is created when missing.

What is here
------------

| File                               | What it is                                                                                                                          |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `statusline-clear.sh`              | The clear edition.                                                                                                                  |
| `statusline-compact.sh`            | The compact edition.                                                                                                                |
| `test-clear.sh`, `test-compact.sh` | Their tests: run `./test-clear.sh` or `./test-compact.sh`.                                                                          |
| `fade-preview.sh`                  | Shows the fade in your terminal, on the cache countdown, the input tokens and the quota percentage. Takes a lifetime, such as `5m`. |
| `FIELDS.md`                        | Every field Claude Code passes to a status line command, with a short name for each.                                                |
