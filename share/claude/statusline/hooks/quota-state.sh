#!/bin/sh
# Shared 5h/7d-quota state across every Claude Code terminal on this machine.
#
# WHY THIS EXISTS: `rate_limits` in the statusLine payload is not a live feed --
# it is a cache of the headers from *that session's* last API response. A
# terminal that has been idle shows frozen numbers, which is why two terminals
# disagree about how much quota is left. This file is the union of what all
# terminals have seen.
#
# MERGE RULE, and why it needs a clock. The original rule was purely
# value-based: within one window `used` only increases and across windows
# `resets_at` increases, so (resets_at, used) compared lexicographically is a
# total "which reading is newer" order -- no timestamps needed. That is true of
# any two readings *of the same account state*, and it is still the tie-break
# below. What it cannot survive is a reading that is simply WRONG-BUT-AHEAD: one
# whose resets_at sits a few minutes past the real window boundary. Nothing can
# ever outrank it (every honest reading has a smaller resets_at), so it pins
# BOTH numbers -- the percentage and the countdown -- for every terminal on the
# machine, for the rest of the window. The observed failure was exactly that
# signature: "78% left / 19m" while the account was at 100% used with 14m to go.
#
# So a reading now also carries WHEN IT WAS OBSERVED LIVE, and freshness
# outranks value: a reading a caller just saw arrive beats a stored one that no
# terminal has re-confirmed in $STALE seconds. That is the only rule that can
# walk a wrong value back down; the value order alone is monotone by
# construction and therefore cannot.
#
# `measured_at` is NOT the time we wrote the file -- it is the time some
# terminal saw these numbers change, i.e. the moment an API response actually
# carried them. The caller says so with the <fresh> flag (the statusline sets it
# when the payload differs from what that session published last). Readings that
# merely repeat what the caller already had do not refresh the clock, because
# re-reading a frozen cache is not evidence of anything.
#
# TWO KINDS OF READING. A *session* reading is what a status line lifted off its
# own payload -- a cache of that session's last response headers. A *probe*
# reading is what quota-probe.sh got by asking the account's usage endpoint
# directly, the one Claude Code's /usage screen reads. The probe is the only
# reading in here that is not a cache of something, and each window remembers
# which kind it holds (`source`: "probe" / "session").
#
# WHY THE PROBE OUTRANKS FROZEN SESSIONS: the rules above can only ever walk
# `used` UP inside one window, and a plan change walks it DOWN. On 2026-09-11
# the account went Max 5x -> Max 20x mid-window: the site said 5% used, this
# file held 94% with the very same resets_at, and every idle terminal kept
# re-publishing its frozen 94% payload -- non-fresh, but ahead by value, so it
# won the merge again and again. Neither the value order nor the stale hatch
# can express "the allowance grew", so the bar sat on the old plan's number
# ("6% left / 10h") until the window reset. The same happens on any
# Pro <-> Max 5x <-> Max 20x switch in either direction, and whenever Anthropic
# adjusts limits mid-window. Hence the rule: while a window's stored reading
# came from the probe and is younger than 2 x $PROBE_SECS, no session reading
# displaces it. The status line can mark a frozen payload as "fresh" on its
# first render, so that flag cannot establish that the session knows the current
# plan. After the probe ages out, session readings are the fallback.
#
# CONCURRENCY: every statusline writes this ~2x/sec with no lock. Two writers
# can interleave and one update can be lost, but the merge is monotone-or-fresher
# and re-runs a second later, so a lost update self-heals. A lock would cost more
# than the race does.
#
#   quota-state.sh publish <u5> <r5> <u7> <r7> <fresh>
#                                       -> echoes merged
#                                          "u5 r5 u7 r7 measured5 usScoped labelScoped rScoped"
#   quota-state.sh set <u5> <r5> <u7> <r7>
#                                       -> the probe's write: replaces both windows
#                                          unconditionally, measured_at=now, source=probe,
#                                          and stamps a top-level probed_at. A non-numeric
#                                          (or -1) <used> keeps that window's stored
#                                          reading instead of blanking it.
#                                          Echoes the same line as publish.
#   quota-state.sh read                 -> echoes stored "u5 r5 m5 source"  (five_hour)
#   quota-state.sh read7                -> echoes stored "u7 r7 m7 source"  (seven_day)
#   quota-state.sh reads                -> echoes stored "us rs ms label" (weekly_scoped)
#
# THE THIRD WINDOW. An account can carry more than one weekly cap: `weekly_all`
# plus a `weekly_scoped` one per model with its own allowance (Fable has had one
# since 2026-09). They are different budgets and only one of them is yours to
# spend on the model in play, so they are stored apart -- `seven_day` is always
# the ACCOUNT-WIDE weekly, and `weekly_scoped` holds the tightest per-model cap
# with the model's name in `label` (the bar renders it as "(F14%)"). Collapsing
# the two into one field, which is what the probe used to do by writing whichever
# was higher into `seven_day`, made the bar read 14% while /usage said 8% and
# gave no way to tell which budget the number belonged to.
#
# The scoped window has NO merge rule and no session reading to merge with: a
# session payload's `rate_limits` carries only the two account-wide windows, so
# the probe is the only thing that can ever know this figure. `publish` therefore
# passes it through untouched and `set` simply overwrites it.
#
# Both windows are merged independently by the rule above: the weekly reading
# goes stale in exactly the same way as the 5h one, and it is the *slower* of the
# two to refresh (a terminal can sit idle for hours), so sharing matters more
# there, not less. Both share ONE <fresh> flag because both come off the same
# response headers -- if one moved, the response was new, and the other was
# re-confirmed by that same response even when its value did not change.

F="${CLAUDE_QUOTA_FILE:-$HOME/.claude/quota.json}"
# How long a reading stays believable without any terminal re-confirming it.
# 15 minutes: long enough that a genuinely quiet machine does not flap (nobody
# working means nobody burning, so an old reading is still a correct one), short
# enough that a window cannot run to its end on a number seen once at the start.
STALE="${CLAUDE_QUOTA_STALE_SECS:-900}"
# How often quota-probe.sh asks the account (its own default, repeated here so
# the two agree on how long a probe reading stays authoritative: twice this, so
# one missed probe does not hand the bar back to the frozen caches).
PROBE_SECS="${CLAUDE_QUOTA_PROBE_SECS:-${CLAUDE_WEEKLY_QUOTA_PROBE_SECS:-300}}"
case "$PROBE_SECS" in ''|*[!0-9]*|0) PROBE_SECS=300 ;; esac

# load: every stored field in ONE jq, into o5* (5h), o7* (weekly), oS* (the
# scoped cap) and o_probed. `publish` runs on every render of every terminal, so
# a jq per window was three processes a second each. A missing or unreadable
# file leaves the defaults: -1 used means "nothing stored".
load() {
  o5u=-1 o5r=0 o5m=0 o5s=session o7u=-1 o7r=0 o7m=0 o7s=session
  oSu=-1 oSr=0 oSm=0 oSl=- o_probed=0
  [ -f "$F" ] || return 0
  eval "$(jq -r '@sh "o5u=\(.five_hour.used? // -1) o5r=\(.five_hour.resets_at? // 0)
o5m=\(.five_hour.measured_at? // 0) o5s=\(.five_hour.source? // "session")
o7u=\(.seven_day.used? // -1) o7r=\(.seven_day.resets_at? // 0)
o7m=\(.seven_day.measured_at? // 0) o7s=\(.seven_day.source? // "session")
oSu=\(.weekly_scoped.used? // -1) oSr=\(.weekly_scoped.resets_at? // 0)
oSm=\(.weekly_scoped.measured_at? // 0) oSl=\(.weekly_scoped.label? // "-")
o_probed=\(.probed_at? // 0)"' "$F" 2>/dev/null)"
}

# merge <used> <resets> <fresh> <old_used> <old_resets> <old_measured> <old_source> <now>
#   -> sets m_u m_r m_m m_s, "used resets measured source" of the winner
# Sets variables rather than echoing, so the caller need not fork a subshell.
# A non-numeric/absent new reading always loses, so a terminal that has never
# seen a header cannot blank out what the others know.
merge() {
  _u=$1; _r=${2:-0}; _f=$3; _ou=$4; _or=$5; _om=$6; _os=${7:-session}; _now=$8
  m_u=$_ou m_r=$_or m_m=$_om m_s=$_os
  case "$_u" in ''|*[!0-9.]*) return ;; esac
  case "$_r" in ''|*[!0-9]*) _r=0 ;; esac
  case "$_om" in ''|*[!0-9]*) _om=0; m_m=0 ;; esac
  # A probe reading younger than two probe intervals is an account measurement.
  # Even a "fresh" session value may be an old-plan cache on first render.
  if [ "$_os" = probe ] && [ "$((_now - _om))" -lt "$((2 * PROBE_SECS))" ]; then
    return
  fi
  # Take the new reading when it is newer BY VALUE (the original order), or when
  # it is FRESH and what we hold has gone unconfirmed past $STALE. The second
  # clause is the escape hatch: it is the only way a stored reading whose
  # resets_at is ahead of reality can ever be displaced.
  _take=$(awk -v u="$_u" -v r="$_r" -v f="$_f" -v ou="$_ou" -v orr="$_or" \
               -v om="$_om" -v now="$_now" -v st="$STALE" 'BEGIN{
    if (ou < 0)                        { print 1; exit }   # nothing stored yet
    if (r > orr)                       { print 1; exit }
    if (r == orr && u > ou)            { print 1; exit }
    if (f == 1 && (now - om) > st)     { print 1; exit }   # stale gets overruled
    print 0 }')
  if [ "$_take" = 1 ]; then
    # Only a FRESH reading may advance the clock. Winning on value alone proves
    # the reading is newer than ours, but not by how much -- and a timestamp we
    # cannot justify is worse than an old one we can, because it is the number
    # the display uses to decide whether to trust itself.
    m_u=$_u m_r=$_r m_s=session
    if [ "$_f" = 1 ]; then m_m=$_now; fi
  elif [ "$_f" = 1 ] && [ "$_u" = "$_ou" ] && [ "$_r" = "$_or" ]; then
    # Losing on value does not mean the caller learnt nothing: if it re-observed
    # the very numbers we hold, they are confirmed as of now. The provenance
    # stays -- the value is still the probe's, it has merely been seen again.
    m_m=$_now
  fi
}

# write_state <u5> <r5> <m5> <s5> <u7> <r7> <m7> <s7> <probed_at> <now> \
#             <us> <rs> <ms> <label>
# Built from arguments, not by editing the file in place, so a corrupt file is
# overwritten by the next write instead of wedging every terminal.
write_state() {
  tmp="$F.tmp.$$"
  if jq -n --argjson u "$1" --argjson r "$2" --argjson m "$3" --arg s "$4" \
          --argjson u7 "$5" --argjson r7 "$6" --argjson m7 "$7" --arg s7 "$8" \
          --argjson p "$9" --argjson n "${10}" \
          --argjson us "${11}" --argjson rs "${12}" --argjson ms "${13}" --arg ls "${14}" \
       '{five_hour:{used:$u,resets_at:$r,measured_at:$m,source:$s},
         seven_day:{used:$u7,resets_at:$r7,measured_at:$m7,source:$s7},
         weekly_scoped:{used:$us,resets_at:$rs,measured_at:$ms,label:$ls},
         probed_at:$p, updated_at:$n}' \
       > "$tmp" 2>/dev/null; then
    mv -f "$tmp" "$F"
  else
    rm -f "$tmp"
  fi
}

case "$1" in
  read)
    load; echo "$o5u $o5r $o5m $o5s"
    ;;
  read7)
    load; echo "$o7u $o7r $o7m $o7s"
    ;;
  reads)
    load; echo "$oSu $oSr $oSm $oSl"
    ;;
  publish)
    now=$(date +%s)
    fresh=${6:-0}
    case "$fresh" in 1) ;; *) fresh=0 ;; esac

    load
    merge "$2" "${3:-0}" "$fresh" "$o5u" "$o5r" "$o5m" "$o5s" "$now"
    used=$m_u resets=$m_r meas=$m_m src=$m_s
    merge "$4" "${5:-0}" "$fresh" "$o7u" "$o7r" "$o7m" "$o7s" "$now"
    used7=$m_u resets7=$m_r meas7=$m_m src7=$m_s

    if [ "$used $resets $meas $src $used7 $resets7 $meas7 $src7" != \
         "$o5u $o5r $o5m $o5s $o7u $o7r $o7m $o7s" ]; then
      write_state "$used" "$resets" "$meas" "$src" \
                  "$used7" "$resets7" "$meas7" "$src7" "$o_probed" "$now" \
                  "$oSu" "$oSr" "$oSm" "$oSl"
    fi
    echo "$used $resets $used7 $resets7 $meas $oSu $oSl $oSr"
    ;;
  set)
    now=$(date +%s)
    load
    u5=$2; r5=${3:-0}; u7=$4; r7=${5:-0}
    # The scoped triple is optional: a caller that does not know it (an older
    # probe, a test harness) leaves the stored one alone rather than erasing it.
    uS=${6:--}; rS=${7:-0}; lS=${8:--}
    case "$r5" in ''|*[!0-9]*) r5=0 ;; esac
    case "$r7" in ''|*[!0-9]*) r7=0 ;; esac
    case "$rS" in ''|*[!0-9]*) rS=0 ;; esac
    case "$lS" in ''|*[!A-Za-z0-9]*) lS=- ;; esac
    case "$uS" in
      ''|*[!0-9.]*) usedS=$oSu resetsS=$oSr measS=$oSm labelS=$oSl ;;
      *)            usedS=$uS  resetsS=$rS  measS=$now labelS=$lS ;;
    esac
    case "$u5" in
      ''|*[!0-9.]*) used=$o5u resets=$o5r meas=$o5m src=$o5s ;;
      *)            used=$u5  resets=$r5  meas=$now src=probe ;;
    esac
    case "$u7" in
      ''|*[!0-9.]*) used7=$o7u resets7=$o7r meas7=$o7m src7=$o7s ;;
      *)            used7=$u7  resets7=$r7  meas7=$now src7=probe ;;
    esac
    write_state "$used" "$resets" "$meas" "$src" \
                "$used7" "$resets7" "$meas7" "$src7" "$now" "$now" \
                "$usedS" "$resetsS" "$measS" "$labelS"
    echo "$used $resets $used7 $resets7 $meas $usedS $labelS $resetsS"
    ;;
  *)
    echo "usage: $0 {publish <u5> <r5> <u7> <r7> <fresh>|set <u5> <r5> <u7> <r7> [<us> <rs> <label>]|read|read7|reads}" >&2
    exit 64
    ;;
esac
