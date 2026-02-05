$env.TERM = "xterm-256color"
$env.COLORTERM = "truecolor"
$env.config.buffer_editor = "hx"
$env.config.show_banner = false
$env.config.edit_mode = 'vi'

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# --- Carapace completions ---
$env.CARAPACE_BRIDGES = 'zsh,bash'
source ~/Library/Caches/nushell/carapace/init.nu

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# git shortcuts
alias g   = git
alias ga  = git add
alias gb  = git branch
alias gc  = git checkout
alias gcb = git checkout -b
alias gcm = git checkout master
alias gcd = git checkout develop
alias gcp = git checkout preview
alias gd  = git diff
alias gf  = git fetch
alias gl  = git log
alias gs  = git status

alias gcom = git commit -m
alias gca  = git commit --amend
alias push = git push
alias pull = git pull

# tools
alias v  = nvim
alias h  = hx
alias j  = jobs

def reload-env [] {
    source $nu.env-path
}
$env.PROMPT_COMMAND = ">"
