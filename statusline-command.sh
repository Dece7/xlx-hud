#!/usr/bin/env bash
input=$(cat)

# Colors
reset=$'\033[0m'
green=$'\033[32m'
red=$'\033[31m'
yellow=$'\033[33m'
cyan=$'\033[36m'

# Config
config_file="$HOME/.claude/hud-config.json"
cfg() {
  local key=$1
  local val
  val=$(jq -r ".$key // false" "$config_file" 2>/dev/null)
  [ "$val" = "true" ]
}

# --- Model ---
if cfg model; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  model_info="🤖 ${model}"
fi

# --- Git ---
work_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
if cfg git; then
  branch=$(git -C "$work_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    diff_stats=$(git -C "$work_dir" diff --shortstat HEAD 2>/dev/null)
    added=$(echo "$diff_stats" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
    deleted=$(echo "$diff_stats" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
    [ -z "$added" ] && added=0
    [ -z "$deleted" ] && deleted=0
    git_info="🌿 ${branch} ${green}+${added}${reset}/${red}-${deleted}${reset}"
  else
    git_info="🌿 no git"
  fi
fi

# --- Context bar ---
if cfg context; then
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
  used_int=${used_pct%.*}
  used_int=${used_int:-0}
  bar_filled=$(( (used_int + 9) / 10 ))
  bar_empty=$(( 10 - bar_filled ))
  bar=""
  for ((i=0; i<bar_filled; i++)); do bar+="█"; done
  for ((i=0; i<bar_empty; i++)); do bar+="░"; done
  if [ "$used_int" -lt 50 ]; then
    bar_color=$green
  elif [ "$used_int" -lt 80 ]; then
    bar_color=$yellow
  else
    bar_color=$red
  fi
  context_bar="💭 ${bar_color}${bar}${reset} ${used_int}%"
fi

# --- Folder ---
if cfg folder; then
  folder_name=$(basename "$work_dir" 2>/dev/null)
  [ -z "$folder_name" ] && folder_name="—"
  folder_info="📁 ${folder_name}"
fi

# --- Session cache hit rate ---
if cfg cache; then
  transcript=$(echo "$input" | jq -r '(.transcript_path // "") | gsub("\\\\"; "/")' | cygpath -f - 2>/dev/null)
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    totals=$(grep -o '"usage":{[^}]*}' "$transcript" 2>/dev/null | \
      awk -F',' '{
        cr=0; inp=0
        for(i=1;i<=NF;i++){
          if($i ~ /cache_read_input_tokens/){gsub(/[^0-9]/,"",$i); cr+=$i}
          if($i ~ /"input_tokens"/){gsub(/[^0-9]/,"",$i); inp+=$i}
        }
        total_cr+=cr; total_inp+=inp
      }END{print total_cr+0, total_inp+0}')
    session_cr=$(echo "$totals" | awk '{print $1}')
    session_inp=$(echo "$totals" | awk '{print $2}')
    session_total=$(( session_cr + session_inp ))
    if [ "$session_total" -gt 0 ]; then
      session_pct=$(awk "BEGIN{printf \"%.2f\", $session_cr * 100 / $session_total}")
      session_int=${session_pct%.*}
      if [ "$session_int" -ge 80 ]; then
        sc_color=$green
      elif [ "$session_int" -ge 50 ]; then
        sc_color=$yellow
      else
        sc_color=$red
      fi
      cache_info="🎯 ${sc_color}${session_pct}%${reset}"
    else
      cache_info="🎯 —"
    fi
  else
    cache_info="🎯 —"
  fi
fi

# --- Code changes ---
if cfg lines; then
  lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
  lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
  lines_info="📝 ${green}+${lines_added}${reset}/${red}-${lines_removed}${reset}"
fi

# --- Effort level ---
if cfg effort; then
  effort_level=$(echo "$input" | jq -r '.effort.level // "unknown"')
  effort_info="⚡${effort_level}"
fi

# --- Cumulative input tokens ---
if cfg tokens; then
  total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
  if [ "$total_in" -ge 1000000 ]; then
    tokens_display=$(awk "BEGIN{printf \"%.1fM\", $total_in/1000000}")
  elif [ "$total_in" -ge 1000 ]; then
    tokens_display=$(awk "BEGIN{printf \"%.0fk\", $total_in/1000}")
  else
    tokens_display="${total_in}"
  fi
  tokens_info="📥${tokens_display}"
fi

# --- Session duration ---
if cfg duration; then
  duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
  if [ "$duration_ms" -gt 0 ]; then
    duration_sec=$(( duration_ms / 1000 ))
    if [ "$duration_sec" -ge 3600 ]; then
      duration_h=$(( duration_sec / 3600 ))
      duration_m=$(( (duration_sec % 3600) / 60 ))
      duration_display="${duration_h}h${duration_m}m"
    elif [ "$duration_sec" -ge 60 ]; then
      duration_m=$(( duration_sec / 60 ))
      duration_display="${duration_m}m"
    else
      duration_display="${duration_sec}s"
    fi
    duration_info="⏱️${duration_display}"
  fi
fi

# --- Thinking mode ---
if cfg thinking; then
  thinking_on=$(echo "$input" | jq -r '.thinking.enabled // false')
  if [ "$thinking_on" = "true" ]; then
    thinking_info="${cyan}🧠on${reset}"
  else
    thinking_info="🧠off"
  fi
fi

# --- Assemble output ---
parts=()
[ -n "$model_info" ] && parts+=("$model_info")
[ -n "$git_info" ] && parts+=("$git_info")
[ -n "$context_bar" ] && parts+=("$context_bar")
[ -n "$folder_info" ] && parts+=("$folder_info")
[ -n "$cache_info" ] && parts+=("$cache_info")
[ -n "$lines_info" ] && parts+=("$lines_info")
[ -n "$effort_info" ] && parts+=("$effort_info")
[ -n "$tokens_info" ] && parts+=("$tokens_info")
[ -n "$duration_info" ] && parts+=("$duration_info")
[ -n "$thinking_info" ] && parts+=("$thinking_info")

# Join with double space
output=""
for part in "${parts[@]}"; do
  if [ -n "$output" ]; then output="${output}  "; fi
  output="${output}${part}"
done

echo "$output"
