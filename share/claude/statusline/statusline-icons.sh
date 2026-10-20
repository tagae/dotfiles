#!/bin/sh
# Claude Code status line, exhaustive edition: every documented field, nothing computed.
#
# One jq program and no shell arithmetic. Fields print as `key=value`, exactly as Claude
# Code reported them: tokens as bare integers, ratios as fractions, percentages as given.
# Absent and null fields are skipped, and so is the default output style. The exceptions are three icons for the fields read
# most: the model, the effort and, when true, thinking. The one conversion is epoch
# seconds to a local clock time. There is no colour: colour means a threshold, and a
# threshold is a calculation.
#
# Left out because another shown field already says it: model.id, remaining_percentage,
# total_input_tokens, exceeds_200k_tokens, session_id, pr.url. Left out as opaque or
# noise: prompt_id, version, workspace.current_dir, workspace.project_dir.
#
# Needs a Nerd Font (JetBrains Mono Nerd Font). Glyphs, as Nerd Fonts v3 codepoints:
#   󰚩  model    U+F06A9  nf-md-robot
#   󰊚  effort   U+F029A  nf-md-gauge
#   󰧑  think    U+F09D1  nf-md-brain
#
# Fields: https://code.claude.com/docs/en/statusline#available-data

jq -r '
def v: if type == "string" then . else tojson end;
def f($k; $x): if $x == null then empty else "\($k)=\($x | v)" end;
def icon($i; $x): if $x == null then empty else "\($i) \($x | v)" end;
def clock($k; $x): if $x == null then empty else "\($k)=\($x | strflocaltime("%a %H:%M:%S"))" end;
def line(items): [items] | if length == 0 then empty else join("  ") end;

line(
  icon("󰚩"; .model.display_name), icon("󰊚"; .effort.level),
  (.thinking.enabled | if . == true then "󰧑" else empty end),
  f("fast"; .fast_mode), f("style"; .output_style.name | if . != null and ascii_downcase == "default" then null else . end), f("agent"; .agent.name),
  f("vim"; .vim.mode), f("name"; .session_name)),

line(
  f("used%"; .context_window.used_percentage), f("size"; .context_window.context_window_size),
  f("in"; .context_window.current_usage.input_tokens),
  f("out"; .context_window.total_output_tokens),
  f("cache_read"; .context_window.current_usage.cache_read_input_tokens),
  f("cache_write"; .context_window.current_usage.cache_creation_input_tokens)),

line(
  f("warm"; .prompt_cache.warm), f("observed"; .prompt_cache.caching_observed),
  f("ttl"; .prompt_cache.ttl), clock("expires"; .prompt_cache.expires_at),
  f("requests"; .prompt_cache.requests), f("hit"; .prompt_cache.hit_ratio),
  f("written"; .prompt_cache.cache_write_tokens),
  f("cold_rewrite"; .prompt_cache.recache_tokens_if_cold),
  f("expected_rebuilds"; .prompt_cache.expected_rebuilds)),

line(
  f("misses"; .prompt_cache.misses), f("rewrote"; .prompt_cache.miss_recache_tokens),
  clock("last_miss"; .prompt_cache.last_miss_at),
  f("cause"; .prompt_cache.last_miss_cause.causes),
  f("tools+"; .prompt_cache.last_miss_cause.tools_added),
  f("tools-"; .prompt_cache.last_miss_cause.tools_removed),
  f("system_chars"; .prompt_cache.last_miss_cause.system_char_delta),
  f("causes"; .prompt_cache.miss_causes)),

line(
  f("usd"; .cost.total_cost_usd), f("wall_ms"; .cost.total_duration_ms),
  f("api_ms"; .cost.total_api_duration_ms),
  f("+lines"; .cost.total_lines_added), f("-lines"; .cost.total_lines_removed),
  f("5h%"; .rate_limits.five_hour.used_percentage), clock("5h_resets"; .rate_limits.five_hour.resets_at),
  f("7d%"; .rate_limits.seven_day.used_percentage), clock("7d_resets"; .rate_limits.seven_day.resets_at),
  f("spend%"; .rate_limits.spend_limit.used_percentage),
  f("spend_usd"; .rate_limits.spend_limit.used_usd), f("spend_limit"; .rate_limits.spend_limit.limit_usd),
  f("period"; .rate_limits.spend_limit.period), clock("spend_resets"; .rate_limits.spend_limit.resets_at)),

line(
  f("added_dirs"; (.workspace.added_dirs | if length == 0 then null else . end)),
  f("repo"; [.workspace.repo.host, .workspace.repo.owner, .workspace.repo.name] | if .[2] == null then null else join("/") end),
  f("worktree"; .workspace.git_worktree // .worktree.name), f("wt_path"; .worktree.path),
  f("wt_branch"; .worktree.branch), f("from"; .worktree.original_cwd),
  f("from_branch"; .worktree.original_branch),
  f("pr"; .pr.number), f("pr_state"; .pr.review_state), f("pr_kind"; .pr.kind),
  f("transcript"; .transcript_path))
' 2>/dev/null
