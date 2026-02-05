#!/usr/bin/env bash

# Run fuzzy select in tmux popup, no preview
session=$(tmux list-sessions -F "#{session_name}" | fzf-tmux -p --no-preview) || exit 0

# If nothing selected, do nothing
[ -n "$session" ] || exit 0

# Switch to the chosen session
tmux switch-client -t "$session"
