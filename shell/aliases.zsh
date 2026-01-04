# Git aliases (matching oh-my-zsh git plugin)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias glog='git log --oneline --decorate --graph'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gst='git status'
alias gsw='git switch'
alias gswc='git switch -c'

# Directory shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -la'

# Editor shortcuts
alias v='nvim'
alias c='code .'

# Kubernetes (matching existing alias style)
alias k='kubectl'

# Common dev commands
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
