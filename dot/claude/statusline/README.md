Claude Code status line
=======================

One line of numbers, coloured only where something needs attention: how full the context is, what
the prompt cache will cost, what the session has cost, and how much quota is left. It makes no API
calls and is coloured for dark terminals.

```
Sonnet 5.5·h | in: 295K/1M (+1.7K, ttl: 59m) out: 393 | $0.12 ⊂ $3.62 | up: 2h00 api: 15m | 5h: ↑32% ↻56m 7d: ↑56% ↻1d2h
```

Reading the line
----------------

| Part                | Meaning                                                                                                                                            |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `Sonnet 5.5·h`      | Model, then the reasoning effort: `l`, `m`, `h`, `xh` or `x` (max). No suffix when the model has none; a level it does not know is shown as it is. |
| `in: 295K/1M`       | Input tokens in the context, and the window size. Yellow from 60% of the window, orange from 80%, red from 90%.                                    |
| `(+1.7K, ttl: 59m)` | The prompt cache; see below.                                                                                                                       |
| `out: 393`          | Output tokens of the last response.                                                                                                                |
| `$0.12 ⊂ $3.62`     | The turn's cost, contained in the session's. The last turn's stands until the new one bills something.                                             |
| `up: 2h00`          | How long the session has run.                                                                                                                      |
| `api: 15m`          | Time spent waiting on the API.                                                                                                                     |
| `5h: ↑32% ↻56m`     | Five-hour quota used, and the time until it resets.                                                                                                |
| `7d: ↑56% ↻1d2h`    | Weekly quota used, and the time until it resets.                                                                                                   |

A `|` divides the model and effort from the input, the output from the cost, the cost from the times,
and the times from the quotas. Durations read `45s`, `12m`, `3h05` or `2d4h`. A part with no data
is left out.

The prompt cache
----------------

`+1.7K` is how much the last response added to the context: the tokens it wrote to the cache.
`ttl` is the time left before the cache expires, after which the next message has to write
the whole context to the cache again. It stays plain while half the lifetime or more is left, then
steps through light yellow, yellow and light orange (below 50%, 38% and 26% left) to orange
(below 15%), never red. Once it has expired it shows by how much, in orange: `ttl: -3m`.

A turn that rebuilt part of the cache adds `miss: 11K ttl_expired_5m` to the bracket: the tokens
re-cached, and the likely cause. It shows on that turn only, and is never plain: yellow, orange
from 50% of the context re-cached, red from 80%.

Quota
-----

Percentages are quota used: plain below 70%, yellow from 70%, orange from 80%, red from 90%.
The arrow compares the share of quota left with the share of the window left, in calendar time:

| Arrow  | Quota left, against time left | Colour      |
|--------|-------------------------------|-------------|
| `↑`    | at least 1.5 times as much    | light green |
| `↗`    | 1.15 to 1.5 times as much     | light green |
| (none) | 0.87 to 1.15 times: on pace   |             |
| `↘`    | 0.67 to 0.87 times            | yellow      |
| `↓`    | under 0.67 times              | red         |

The quota belongs to the account, and other sessions spend it. This session only learns the
figure when it gets a response, so after 15 minutes without one it turns grey, gains a `?` and
loses its arrow (`5h: 32%? ↻56m`); so does a figure whose window has ended.
`CLAUDE_QUOTA_STALE_SECS` changes the 15 minutes.

Setup
-----

Needs `jq`. The countdowns only tick if the status line refreshes: set `refreshInterval` in the
`statusLine` setting (5 seconds here). The cache figures need Claude Code 2.1.251, and the miss
cause 2.1.260.

The turn's cost and the staleness check need a little memory between renders: one small file per
session, `/tmp/claude-statusline-clear-<session id>.txt`. `./test-clear.sh` runs the tests.
