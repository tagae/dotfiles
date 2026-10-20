#!/bin/sh
# Claude Code status line, exhaustive edition: every documented field, nothing computed.
#
# One jq program and no shell arithmetic. Each field prints as `name=value`, exactly as
# Claude Code reported it: tokens as bare integers, ratios as fractions, percentages as
# given. Absent and null fields are skipped. The one conversion is epoch seconds to a
# local clock time, since a bare epoch is unreadable. There is no colour, because colour
# would mean a threshold, and a threshold is a calculation.
#
# Fields: https://code.claude.com/docs/en/statusline#available-data

jq -r '
def v: if type == "string" then . else tojson end;
def f($l; $x): if $x == null then empty else "\($l)=\($x | v)" end;
def clock($l; $x): if $x == null then empty else "\($l)=\($x | strflocaltime("%a %H:%M:%S"))" end;
def line($p; items): [items] | if length == 0 then empty else "\($p) " + join(" ") end;

line("session";
  f("model"; .model.display_name), f("id"; .model.id), f("effort"; .effort.level),
  f("fast"; .fast_mode), f("thinking"; .thinking.enabled), f("style"; .output_style.name),
  f("agent"; .agent.name), f("vim"; .vim.mode), f("name"; .session_name),
  f("v"; .version), f("session"; .session_id), f("prompt"; .prompt_id)),

line("ctx";
  f("input"; .context_window.total_input_tokens), f("output"; .context_window.total_output_tokens),
  f("size"; .context_window.context_window_size),
  f("used%"; .context_window.used_percentage), f("left%"; .context_window.remaining_percentage),
  f("over200k"; .exceeds_200k_tokens),
  f("in"; .context_window.current_usage.input_tokens),
  f("out"; .context_window.current_usage.output_tokens),
  f("cache_write"; .context_window.current_usage.cache_creation_input_tokens),
  f("cache_read"; .context_window.current_usage.cache_read_input_tokens)),

line("cache";
  f("warm"; .prompt_cache.warm), f("observed"; .prompt_cache.caching_observed),
  f("ttl"; .prompt_cache.ttl), clock("expires"; .prompt_cache.expires_at),
  f("requests"; .prompt_cache.requests), f("hit"; .prompt_cache.hit_ratio),
  f("written"; .prompt_cache.cache_write_tokens),
  f("cold_rewrite"; .prompt_cache.recache_tokens_if_cold),
  f("expected_rebuilds"; .prompt_cache.expected_rebuilds)),

line("miss";
  f("n"; .prompt_cache.misses), f("rewrote"; .prompt_cache.miss_recache_tokens),
  clock("last"; .prompt_cache.last_miss_at),
  f("cause"; .prompt_cache.last_miss_cause.causes), f("tools+"; .prompt_cache.last_miss_cause.tools_added),
  f("tools-"; .prompt_cache.last_miss_cause.tools_removed),
  f("system_chars"; .prompt_cache.last_miss_cause.system_char_delta),
  f("causes"; .prompt_cache.miss_causes)),

line("cost";
  f("usd"; .cost.total_cost_usd), f("wall_ms"; .cost.total_duration_ms),
  f("api_ms"; .cost.total_api_duration_ms),
  f("+lines"; .cost.total_lines_added), f("-lines"; .cost.total_lines_removed)),

line("quota";
  f("5h%"; .rate_limits.five_hour.used_percentage), clock("5h_resets"; .rate_limits.five_hour.resets_at),
  f("7d%"; .rate_limits.seven_day.used_percentage), clock("7d_resets"; .rate_limits.seven_day.resets_at),
  f("spend%"; .rate_limits.spend_limit.used_percentage),
  f("spend_usd"; .rate_limits.spend_limit.used_usd), f("spend_limit"; .rate_limits.spend_limit.limit_usd),
  f("period"; .rate_limits.spend_limit.period), clock("spend_resets"; .rate_limits.spend_limit.resets_at)),

line("where";
  f("cwd"; .workspace.current_dir // .cwd), f("project"; .workspace.project_dir),
  f("added"; (.workspace.added_dirs | if length == 0 then null else . end)),
  f("repo"; [.workspace.repo.host, .workspace.repo.owner, .workspace.repo.name] | if .[2] == null then null else join("/") end),
  f("linked_worktree"; .workspace.git_worktree),
  f("worktree"; .worktree.name), f("wt_path"; .worktree.path), f("wt_branch"; .worktree.branch),
  f("from"; .worktree.original_cwd), f("from_branch"; .worktree.original_branch),
  f("pr"; .pr.number), f("pr_state"; .pr.review_state), f("pr_kind"; .pr.kind), f("pr_url"; .pr.url),
  f("transcript"; .transcript_path))
' 2>/dev/null
