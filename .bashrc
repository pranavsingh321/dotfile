# ---- interactive only ----
[[ $- != *i* ]] && return

# ---- history ----
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=1000

# ---- aliases ----
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias g='git'
alias ga='git add'
alias gf='git fetch'
alias gl='git log'
alias gb='git branch'
alias gs='git status'
alias gc='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout master'
alias gcd='git checkout develop'
alias gcp='git checkout preview'
alias gca='git commit --amend'
alias gcom='git commit -m'
alias push='git push'
alias pull='git pull'
alias j='jobs'
alias v='nvim'
alias h='hx'
alias reload='exec bash'

# bat fallback
command -v bat >/dev/null || alias bat=batcat

alias fz='find . -type f | fzf --preview "bat --style=numbers --color=always {}"'

# ---- helix ----
export HELIX_RUNTIME="$HOME/helix/runtime"

# ---- prompt ----
export PS1="$ "

# ---- secrets ----
[ -f ~/.secret ] && source ~/.secret

# ---- fzf ----
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ---- rust ----
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# ---- PATH ----
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.local/go/bin:/usr/local/go/bin:$PATH"

# ---- Homebrew (Linux) ----
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ---- Starship ----
eval "$(starship init bash)"

# ---- Carapace ----
export CARAPACE_BRIDGES='zsh,bash'
source <(carapace _carapace bash)
