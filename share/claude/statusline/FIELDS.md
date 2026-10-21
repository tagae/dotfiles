# Status line fields

Every field Claude Code passes to a status line command on stdin, as documented at
<https://code.claude.com/docs/en/statusline#available-data>. Fields marked "absent" or `null` are
skipped by the script here rather than printed empty.

- **Short name**: a label for display, short enough for a one-line status line.
- Timestamps are Unix epoch seconds. Token counts are integers. Percentages are 0 to 100, ratios 0 to 1.

MAINTENANCE RULE: when the script here starts or stops showing a field, update this file in the same commit.

## Session

| Field                | Meaning                                                                                                                                          | Short name |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| `model.display_name` | Display name of the current model.                                                                                                               | `model`    |
| `model.id`           | Model identifier, such as `claude-sonnet-5-5`. Adds nothing beyond the display name.                                                             | `model-id` |
| `effort.level`       | Reasoning effort: `low`, `medium`, `high`, `xhigh` or `max`. Follows mid-session `/effort` changes. Absent when the model has no effort setting. | `effort`   |
| `thinking.enabled`   | Whether extended thinking is on.                                                                                                                 | `think`    |
| `fast_mode`          | Whether fast mode is on.                                                                                                                         | `fast`     |
| `output_style.name`  | Name of the active output style (`default` unless changed).                                                                                      | `style`    |
| `agent.name`         | Agent name when started with `--agent` or configured by agent settings. Absent otherwise.                                                        | `agent`    |
| `vim.mode`           | `NORMAL`, `INSERT`, `VISUAL` or `VISUAL LINE`. Present only when vim mode is enabled.                                                            | `vim`      |
| `session_name`       | Name from `--name` or `/rename`, otherwise the AI-generated title. Absent when neither exists.                                                   | `name`     |
| `session_id`         | Unique session identifier (UUID). It is also the transcript file name.                                                                           | `sid`      |
| `prompt_id`          | UUID of the user prompt being processed; matches `prompt.id` on OpenTelemetry events. Absent until the first input.                              | `prompt`   |
| `transcript_path`    | Path to the conversation transcript file.                                                                                                        | `log`      |
| `version`            | Claude Code version.                                                                                                                             | `ver`      |

## Context window

| Field                                                      | Meaning                                                                                                                                      | Short name    |
|------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `context_window.context_window_size`                       | Maximum window size in tokens: 200000 by default, 1000000 for extended-context models.                                                       | `size`        |
| `context_window.used_percentage`                           | Share of the window used, from input tokens only (no output). `null` early in a session.                                                     | `used%`       |
| `context_window.remaining_percentage`                      | Share of the window left; 100 minus `used_percentage`. `null` early in a session.                                                            | `left%`       |
| `context_window.total_input_tokens`                        | Input tokens in the context from the latest response: fresh input plus cache reads plus cache writes. `0` before the first response.         | `ctx`         |
| `context_window.total_output_tokens`                       | Output tokens of the most recent response. `0` before the first response.                                                                    | `out`         |
| `context_window.current_usage.input_tokens`                | Fresh, uncached input tokens of the last API call. `current_usage` is `null` before the first call and after `/compact` until the next call. | `in`          |
| `context_window.current_usage.output_tokens`               | Output tokens generated by the last API call (same figure as `total_output_tokens`).                                                         | `out`         |
| `context_window.current_usage.cache_read_input_tokens`     | Input tokens served from the prompt cache.                                                                                                   | `cache-read`  |
| `context_window.current_usage.cache_creation_input_tokens` | Input tokens written to the prompt cache.                                                                                                    | `cache-write` |
| `exceeds_200k_tokens`                                      | Whether the latest response's input, cache and output tokens combined exceed 200k. A fixed threshold, whatever the window size.              | `>200k`       |

## Cost and activity

| Field                        | Meaning                                                                                                                                        | Short name |
|------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| `cost.total_cost_usd`        | Estimated session cost in USD, computed client-side at list price (or from `modelPricing`). May differ from the bill. Resets to 0 on `/clear`. | `cost`     |
| `cost.total_duration_ms`     | Wall-clock time the session has run, in milliseconds. Accumulates across resumes; excludes time while not running.                             | `wall`     |
| `cost.total_api_duration_ms` | Time spent waiting for API responses, in milliseconds.                                                                                         | `api`      |
| `cost.total_lines_added`     | Lines of code added.                                                                                                                           | `+lines`   |
| `cost.total_lines_removed`   | Lines of code removed.                                                                                                                         | `-lines`   |

## Rate limits

| Field                                     | Meaning                                                                                                                                             | Short name    |
|-------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `rate_limits.five_hour.used_percentage`   | Share of the 5-hour limit consumed, 0 to 100. Pro and Max only; appears after the first response. Cached per session, so stale in an idle terminal. | `5h`          |
| `rate_limits.five_hour.resets_at`         | Epoch seconds when the 5-hour window resets.                                                                                                        | `5h-reset`    |
| `rate_limits.seven_day.used_percentage`   | Share of the weekly limit consumed, 0 to 100. Same availability as the 5-hour figure.                                                               | `7d`          |
| `rate_limits.seven_day.resets_at`         | Epoch seconds when the weekly window resets.                                                                                                        | `7d-reset`    |
| `rate_limits.spend_limit.used_percentage` | Behind a Claude apps gateway: share of your spend limit used. Needs v2.1.251+.                                                                      | `spend%`      |
| `rate_limits.spend_limit.used_usd`        | Estimated spend in USD against the limit. May be absent. Needs v2.1.284+ on both Claude Code and the gateway.                                       | `spent`       |
| `rate_limits.spend_limit.limit_usd`       | Your spend limit in USD. May be absent; same version needs.                                                                                         | `limit`       |
| `rate_limits.spend_limit.period`          | The spend limit's period. May be absent.                                                                                                            | `period`      |
| `rate_limits.spend_limit.resets_at`       | Epoch seconds when the spend period resets.                                                                                                         | `spend-reset` |

## Prompt cache (main conversation; v2.1.251+, absent until the first response)

| Field                                            | Meaning                                                                                                                                                                                              | Short name    |
|--------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `prompt_cache.warm`                              | The cached prefix is still within its TTL. `false` when the last response reported no cache tokens.                                                                                                  | `warm`        |
| `prompt_cache.caching_observed`                  | Any response this session reported cache tokens. `false` means caching is off or the provider does not report it.                                                                                    | `cached`      |
| `prompt_cache.ttl`                               | Lifetime of the current cached prefix: `5m` or `1h`.                                                                                                                                                 | `ttl`         |
| `prompt_cache.expires_at`                        | Epoch seconds when the prefix goes cold. `null` when the last response had no cache tokens.                                                                                                          | `expires`     |
| `prompt_cache.requests`                          | API requests recorded for the main conversation this session.                                                                                                                                        | `reqs`        |
| `prompt_cache.hit_ratio`                         | Cache-read tokens as a 0–1 fraction of all input tokens this session. `null` while the counts are zero.                                                                                              | `hit`         |
| `prompt_cache.cache_write_tokens`                | All tokens written to the cache this session, the first write included.                                                                                                                              | `written`     |
| `prompt_cache.recache_tokens_if_cold`            | Tokens the next request re-caches if the cache has gone cold by then. `null` right after a compaction or tool-result clearing.                                                                       | `if-cold`     |
| `prompt_cache.expected_rebuilds`                 | Rebuilds that followed a compaction or a clearing of old tool results, so they do not count as misses.                                                                                               | `rebuilds`    |
| `prompt_cache.misses`                            | Requests that re-processed content the cache held: over 5% and at least 2,000 tokens of what could have been read, with no compaction to explain it.                                                 | `misses`      |
| `prompt_cache.miss_recache_tokens`               | Tokens written to the cache by the requests counted as misses.                                                                                                                                       | `miss-tokens` |
| `prompt_cache.last_miss_at`                      | Epoch seconds of the last miss. `null` while there are none.                                                                                                                                         | `miss-at`     |
| `prompt_cache.last_miss_cause.causes`            | Likely cause(s) of the last miss, such as `ttl_expired_5m`, `tools_changed`, `system_prompt_changed`, `likely_server_side`. `null` until the first miss or when no cause was found. Needs v2.1.260+. | `cause`       |
| `prompt_cache.last_miss_cause.tools_added`       | With `tools_changed`: how many tools were added.                                                                                                                                                     | `tools+`      |
| `prompt_cache.last_miss_cause.tools_removed`     | With `tools_changed`: how many tools were removed.                                                                                                                                                   | `tools-`      |
| `prompt_cache.last_miss_cause.system_char_delta` | With `system_prompt_changed`: change in the system prompt length, in characters.                                                                                                                     | `sys-chars`   |
| `prompt_cache.miss_causes`                       | Counts of this session's diagnosed misses by cause, keyed like `last_miss_cause`. Needs v2.1.260+.                                                                                                   | `causes`      |

## Workspace

| Field                          | Meaning                                                                                                          | Short name       |
|--------------------------------|------------------------------------------------------------------------------------------------------------------|------------------|
| `cwd`, `workspace.current_dir` | Current working directory; both hold the same value.                                                             | `cwd`            |
| `workspace.project_dir`        | Directory where Claude Code was launched; differs from the current directory if it changes during the session.   | `project`        |
| `workspace.added_dirs`         | Extra directories from `/add-dir` or `--add-dir`; empty array if none.                                           | `+dirs`          |
| `workspace.repo.host`          | Host of the `origin` remote, such as `github.com`. Absent outside a git repo or without `origin`.                | `host`           |
| `workspace.repo.owner`         | Owner of the repo; for GitLab subgroups, the full namespace path.                                                | `owner`          |
| `workspace.repo.name`          | Repository name.                                                                                                 | `repo`           |
| `workspace.git_worktree`       | Name of the linked git worktree when inside one. Absent in the main working tree.                                | `worktree`       |
| `worktree.name`                | Name of the active worktree session. Present only in a worktree session.                                         | `wt`             |
| `worktree.path`                | Absolute path of the worktree directory.                                                                         | `wt-path`        |
| `worktree.branch`              | Branch of the worktree. Absent for hook-based worktrees.                                                         | `wt-branch`      |
| `worktree.original_cwd`        | Directory Claude was in before entering the worktree.                                                            | `wt-from`        |
| `worktree.original_branch`     | Branch checked out before entering the worktree. Absent for hook-based worktrees.                                | `wt-from-branch` |
| `pr.number`                    | Open pull request (or GitLab merge request) for the current branch. Absent when none, and once merged or closed. | `pr`             |
| `pr.url`                       | URL of that pull request. Repeats the host, owner, repo and number.                                              | `pr-url`         |
| `pr.review_state`              | `approved`, `pending`, `changes_requested` or `draft`. May be absent even when `pr` exists.                      | `pr-state`       |
| `pr.kind`                      | `mr` for a GitLab merge request; absent for GitHub.                                                              | `pr-kind`        |
