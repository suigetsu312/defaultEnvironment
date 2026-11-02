__defaultenv_project_session_name() {
  local project_path=$1
  local project_name=${project_path:t}
  local path_hash

  project_name=${project_name//[^[:alnum:]_-]/_}
  project_name=${project_name[1,32]}
  path_hash=$(printf '%s' "$project_path" | cksum | cut -d ' ' -f 1) || return 1
  printf '%s-%s' "$project_name" "$path_hash"
}

__defaultenv_enter_session() {
  local session_name=$1

  if [[ -n ${TMUX:-} ]]; then
    tmux switch-client -t "=$session_name"
  else
    tmux attach-session -t "=$session_name"
  fi
}

__defaultenv_open_project() {
  local project_path=$1
  local create_layout=${2:-false}
  local session_name

  if ! command -v tmux >/dev/null 2>&1; then
    print -u2 'tdev: tmux is required.'
    return 127
  fi
  if [[ ! -d $project_path ]]; then
    print -u2 "tdev: project directory does not exist: $project_path"
    return 1
  fi
  project_path=$(cd "$project_path" && pwd -P) || return 1
  session_name=$(__defaultenv_project_session_name "$project_path") || return 1

  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    if ! tmux new-session -d -s "$session_name" -n editor -c "$project_path"; then
      print -u2 "tdev: could not create tmux session '$session_name'."
      return 1
    fi

    if [[ $create_layout == true ]]; then
      if command -v nvim >/dev/null 2>&1; then
        tmux send-keys -t "${session_name}:editor" nvim C-m
      else
        print -u2 'tdev: nvim is not installed; the editor window is a shell.'
      fi

      tmux new-window -d -t "$session_name" -n build -c "$project_path" || return 1
      tmux split-window -d -v -t "${session_name}:build" -c "$project_path" || return 1
      tmux new-window -d -t "$session_name" -n git -c "$project_path" || return 1
      if command -v lazygit >/dev/null 2>&1; then
        tmux send-keys -t "${session_name}:git" lazygit C-m
      fi
      tmux select-window -t "${session_name}:editor" || return 1
    fi
  fi

  __defaultenv_enter_session "$session_name"
}

tproject() {
  local directories selected

  if ! command -v zoxide >/dev/null 2>&1; then
    print -u2 'tproject: zoxide is required.'
    return 127
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'tproject: fzf is required.'
    return 127
  fi
  if ! command -v tmux >/dev/null 2>&1; then
    print -u2 'tproject: tmux is required.'
    return 127
  fi

  directories=$(zoxide query -l) || {
    print -u2 'tproject: zoxide has no recorded directories yet.'
    return 1
  }
  [[ -n $directories ]] || {
    print -u2 'tproject: zoxide has no recorded directories yet.'
    return 1
  }
  selected=$(printf '%s\n' "$directories" | fzf --prompt='project> ') || return 0
  [[ -n $selected ]] || return 0

  __defaultenv_open_project "$selected"
}

tlist() {
  local sessions selected session_name

  if ! command -v tmux >/dev/null 2>&1; then
    print -u2 'tlist: tmux is required.'
    return 127
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'tlist: fzf is required.'
    return 127
  fi

  sessions=$(tmux list-sessions -F $'#{session_name}\t#{session_path}' 2>/dev/null) || {
    print 'tlist: no tmux sessions are running.'
    return 0
  }
  [[ -n $sessions ]] || {
    print 'tlist: no tmux sessions are running.'
    return 0
  }
  selected=$(printf '%s\n' "$sessions" | fzf --delimiter=$'\t' --with-nth=1,2 --prompt='session> ') || return 0
  session_name=${selected%%$'\t'*}
  [[ -n $session_name ]] || return 0

  __defaultenv_enter_session "$session_name"
}

tdev() {
  if (( $# > 1 )); then
    print -u2 'Usage: tdev [project-directory]'
    return 2
  fi
  __defaultenv_open_project "${1:-$PWD}" true
}
