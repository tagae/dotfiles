# Claude Code status line

Answers three questions without leaving the terminal: what is this session costing, how much quota is left, and
is it about to get expensive?

Example:

```
Opus 5.5xh 50K 98% / 4h46 $0.1 -3m ⊂ $25 myproject +49=70% / 1wd
```

It refreshes every second and works the same on macOS and Linux.

## Reading the line

| Part             | Meaning                                                                                                                              |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `Opus 5.5xh`     | Model, with the reasoning effort as a lower-case suffix: `l`, `m`, `h`, `xh` or `max`.                                               |
| `50K`            | Context used so far. On models with a smaller window it reads `80K/200K • 40%`. It turns orange at 70% of the window and red at 90%. |
| `98% / 4h46`     | Five-hour quota left, and the time until it resets.                                                                                  |
| `$0.1 -3m ⊂ $25` | The last turn cost $0.10 and finished 3 minutes ago. It is part of a $25 session.                                                    |
| `myproject`      | The repository you are in, on a coloured block. `@branch` follows when you are not on `main` or `master`.                            |
| `+49=70% / 1wd`  | Weekly quota: 70% left, 49 points ahead of an even pace, and a working day to go.                                                    |

The quota figures come from your account, using Claude Code's own login, and
are refreshed about every five minutes.

### The five-hour quota

An arrow says how you are doing against the clock: `↑` or `↗` means more quota
than time, `↘` or `↓` means you are burning faster than the window allows, and
no arrow means on pace. The block changes colour when quota runs low, amber
under 15% and maroon under 5%. A grey `?` means nobody has seen the figure
change for a while, so treat it as old.

### The weekly quota

The number in front of `=` is the pace: positive means you are ahead, negative
means you are using the week up too fast, and nothing at all means exactly on
pace. Time left counts working days only, so weekends do not make Friday look
worse than it is. When you are on a model with its own weekly cap, it appears
as a small chip such as `(F22%)`.

### Spend

While Claude is working, a flower animates in place of the `$` in front of the
turn cost. Right after you press Enter, before anything has been billed, four
stars hold its place. A red `(202K⏱)` after the turn cost means that this many
tokens of the turn were spent rebuilding the prompt cache, and the glyph is the
cause Claude Code identified: `⏱` the cache had expired, `⇄` you switched model
(each model has its own cache), `↻` something else, such as the tools or the
system prompt changing. No glyph means Claude Code could not tell. A compaction
is an expected rebuild, not a miss, so it gets no tag.

### The prompt-cache warning

Claude keeps your conversation cached for a while, and the next message is much
cheaper while that lasts. Step away long enough and the cache is gone. The line
tells you how much will have to be rebuilt before it happens:

```
Opus 5.5xh 220K 87% / 4h46 $0.1 (>1h⇒+=203K) ⊂ $23 myproject +49=70% / 1wd
```

`+=203K` is how many tokens your next message will have to write to the cache
again. The clock turns orange in the last fifth of the cache's lifetime and red
once it has expired. When that is more than 200K tokens, the context count and
the clock blink so you notice; `CLAUDE_MISS_FLOOR` changes that threshold (in
tokens).

All cache figures, the miss tag above included, are Claude Code's own
statistics (the same ones `/usage` shows), so they need Claude Code 2.1.251 or
later; the miss cause needs 2.1.260.

### Subagents

While subagents are running, the model segment ends with what they are running
on: `+{O5h×2,S5m}` is two Opus 5 agents at high effort and one Sonnet 5 at
medium. The letter is the model family's initial: `O` Opus, `S` Sonnet, `F`
Fable, `H` Haiku.

## Light and dark terminals

The colours follow Claude Code's own theme, so a light theme gets deeper
colours and pastel blocks. With the `auto` theme the status line cannot ask the
terminal as Claude Code does, so it goes by `$COLORFGBG` when the terminal sets
it, else by the macOS appearance, else dark. Set `CLAUDE_STATUSLINE_LIGHT=1` or
`0` to force one.
