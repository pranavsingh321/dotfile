# --- Ghostty TERM fix ---
if [[ "$TERM" == "xterm-ghostty" ]]; then
  export TERM=xterm-256color
fi
export COLORTERM=24bit

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"

# Plugins MUST be before oh-my-zsh.sh
plugins=(git zsh-autosuggestions)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

source $ZSH/oh-my-zsh.sh

# --- fzf ---
source $(brew --prefix)/opt/fzf/shell/key-bindings.zsh
source $(brew --prefix)/opt/fzf/shell/completion.zsh

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
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden'

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
alias h='hx'
alias s='source ~/.zshrc'

# --- Carapace ---
export CARAPACE_BRIDGES='zsh,bash'
eval "$(carapace _carapace zsh)"

# Initialize Starship
eval "$(starship init zsh)"

