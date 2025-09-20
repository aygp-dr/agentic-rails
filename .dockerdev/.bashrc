# Agentic Rails Docker bashrc

# Colors for prompt
export PS1='\[\033[01;32m\]agentic-rails\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Aliases
alias be='bundle exec'
alias rc='rails console'
alias rs='rails server -b 0.0.0.0'
alias rt='rails test'
alias rdb='rails db'
alias migrate='rails db:migrate'
alias rollback='rails db:rollback'
alias seed='rails db:seed'

# Rails environment helpers
alias dev='RAILS_ENV=development'
alias test='RAILS_ENV=test'
alias prod='RAILS_ENV=production'

# Git aliases
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph -10'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Performance monitoring
alias monitor='ruby /app/bin/monitor'
alias bench='rails test:benchmark'
alias profile='bundle exec derailed bundle:mem'

# Export environment
export RAILS_ENV=${RAILS_ENV:-development}
export EDITOR=vi

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
shopt -s histappend

# cd to app directory on login
cd /app