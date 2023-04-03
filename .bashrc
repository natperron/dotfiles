# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export HISTFILE="$XDG_CACHE_HOME/bash_history"
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

PS1='\[\e[1;34m\][\[\e[1;36m\]\u\[\e[1;34m\]@\[\e[1;36m\]\h \[\e[1;35m\]\w\[\e[0;37m\]$(parse_git_branch)\[\e[1;34m\]]$\[\e[m\] '

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export NPM_PACKAGES="${HOME}/.local/share/npm"
export PATH=$HOME/.local/share/pyenv/bin:$NPM_PACKAGES/bin:$PATH
[ -f ~/.config/bash/git-aliases ] && . ~/.config/bash/git-aliases
[ -f ~/.config/bash/cleanup-aliases ] && . ~/.config/bash/cleanup-aliases
[ -f ~/.config/bash/other-aliases ] && . ~/.config/bash/other-aliases
