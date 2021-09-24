# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export HISTFILE="$XDG_CACHE_HOME/bash_history"
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s checkwinsize
ulimit -c 0

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

if [ "$color_prompt" = yes ]; then
    PS1='\[\e[1;34m\][\[\e[1;35m\]\u\[\e[1;34m\]@\[\e[1;35m\]\h \[\e[1;36m\]\w\[\e[0;37m\]$(parse_git_branch)\[\e[1;34m\]]$\[\e[m\] '
else
    PS1='[\u@\h \w$(parse_git_branch)]$ '
fi
unset color_prompt force_color_prompt

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export NPM_PACKAGES="${HOME}/.npm-packages"
#export NODE_PATH="$NPM_PACKAGES/bin:$PATH"
export PATH=/opt/firefox/firefox:$HOME/.pyenv/bin:$NPM_PACKAGES/bin:$PATH
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"
source /usr/share/autojump/autojump.sh
[ -f ~/.config/bash/git-aliases ] && . ~/.config/bash/git-aliases
[ -f ~/.config/bash/work-aliases ] && . ~/.config/bash/work-aliases
[ -f ~/.config/bash/cleanup-aliases ] && . ~/.config/bash/cleanup-aliases
[ -f ~/.config/bash/other-aliases ] && . ~/.config/bash/other-aliases
