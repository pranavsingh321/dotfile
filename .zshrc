# --- Powerlevel10k Instant Prompt ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Fix Ghostty TERM
if [[ "$TERM" == "xterm-ghostty" ]]; then
  export TERM=xterm-256color
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Plugins MUST be before oh-my-zsh.sh
plugins=(git zsh-autosuggestions)

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

source $ZSH/oh-my-zsh.sh

# --- fzf ---
source $(brew --prefix)/opt/fzf/shell/key-bindings.zsh
source $(brew --prefix)/opt/fzf/shell/completion.zsh

# --- Powerlevel10k ---
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Environment ---
export LANG="en_US.UTF-8"
export HELIX_RUNTIME=~/helix/runtime

export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Users/pp123/Downloads/flutter/bin:$PATH"
export PATH="/Users/pp123/.opencode/bin:$PATH"

# --- FZF Options ---
export FZF_DEFAULT_OPTS='--height 40% --preview "bat --style=numbers --color=always --line-range :500 {}"'

# --- Aliases ---
alias brewr='arch -x86_64 /usr/local/bin/brew'
alias leg='arch -x86_64'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias g='git'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gf='git fetch'
alias gl='git log'
alias gb='git branch'
alias gs='git status'
alias gcm='git checkout master'
alias gcd='git checkout develop'
alias gcp='git checkout preview'
alias gca='git commit --amend'
alias gcom='git commit -m'
alias push='git push'
alias pull='git pull'

alias rgf='rg --files'
alias j='jobs'
alias v='nvim'
alias h='hx'
alias s='source ~/.zshrc'

# --- Carapace ---
export CARAPACE_BRIDGES='zsh,bash'
eval "$(carapace _carapace zsh)"

# --- Starship ---
eval "$(starship init zsh)"
