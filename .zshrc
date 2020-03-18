DEFAULT_USER="daniel"


HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.history

setopt PROMPT_SUBST
setopt autocd

# fpath=(~/.config/zsh/completions $fpath)
autoload -Uz compinit vcs_info
compinit
_comp_options+=(globdots)

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''   # show colors on menu completion
zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
precmd () { vcs_info }
PS1='%F{3}%3~ ${vcs_info_msg_0_}%f%# '

setopt completealiases


export LC_ALL=en_US.UTF-8
export PATH=$HOME/.bin:$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH
export VISUAL=/usr/bin/nvim 
export EDITOR="$VISUAL"
export GOPATH="$HOME/.go"
export FZF_DEFAULT_COMMAND='fd --type f --follow'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export NNN_PLUG='o:-_fuzzy_cmd $nnn'
export NNN_OPENER=mimeopen
export NNN_COLORS='4321'
export NNN_TRASH=1
export NNN_BMS='D:~/Documents;h:/home/daniel;p:~/Proggz;d:~/Downloads/;.:~/.config'
export NNN_ARCHIVE="\\.(7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rar|rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)$"
# (cat ~/.cache/wal/sequences &)

function fzf-dmenu() { 
	# note: xdg-open has a bug with .desktop files, so we cant use that shit
	selected="$(ls /usr/share/applications | fzf -e)"
	nohup `grep '^Exec' "/usr/share/applications/$selected" | tail -1 | sed 's/^Exec=//' | sed 's/%.//'` >/dev/null 2>&1&
}

export KEYTIMEOUT=1

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

zle-line-init() {
	zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
        echo -ne "\e[5 q"
}
zle -N zle-line-init


function ncd
{
    export NNN_TMPFILE=${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd

    nnn "$@"

    if [ -f $NNN_TMPFILE ]; then
            . $NNN_TMPFILE
            rm $NNN_TMPFILE
    fi
}
alias Zbrush="WINEPREFIX=~/Hdd/ZbrushWine wine start 'C:\\Program Files\Pixologic\Zbrush 2020\Zbrush.exe'"

alias vi=$VISUAL
alias vim=$VISUAL
alias config='/usr/bin/git --git-dir=$HOME/.dotcfg/ --work-tree=$HOME'
# config config --local status.showUntrackedFiles no



#-------- Transmission CLI v2 {{{
#------------------------------------------------------
# DEMO: http://www.youtube.com/watch?v=ee4XzWuapsE
# DESC: lightweight torrent client; interface from cli, webui, ncurses, and gui
# WEBUI:  http://localhost:9091/transmission/web/
# 	  http://192.168.1.xxx:9091/transmission/web/

tsm-clearcompleted() {
  transmission-remote -l | grep 100% | grep Done | \
  awk '{print $1}' | xargs -n 1 -I % transmission-remote -t % -r
}

# display numbers of ip being blocked by the blocklist (credit: smw from irc #transmission)
tsm-count() {
  echo "Blocklist rules:" $(curl -s --data \
  '{"method": "session-get"}' localhost:9091/transmission/rpc -H \
  "$(curl -s -D - localhost:9091/transmission/rpc | grep X-Transmission-Session-Id)" \
  | cut -d: -f 11 | cut -d, -f1)
}

# DEMO: http://www.youtube.com/watch?v=TyDX50_dC0M
# DESC: merge multiple ip blocklist into one
# LINK: https://github.com/gotbletu/shownotes/blob/master/blocklist.sh
tsm-blocklist() {
  echo "${Red}>>>Stopping Transmission Daemon ${Color_Off}"
    killall transmission-daemon
  echo "${Yellow}>>>Updating Blocklist ${Color_Off}"
    ~/.scripts/blocklist.sh
  echo "${Red}>>>Restarting Transmission Daemon ${Color_Off}"
    transmission-daemon
    sleep 3
  echo "${Green}>>>Numbers of IP Now Blocked ${Color_Off}"
    tsm-count
}
tsm-altdownloadspeed() { transmission-remote --downlimit "${@:-900}" ;}	# download default to 900K, else enter your own
tsm-altdownloadspeedunlimited() { transmission-remote --no-downlimit ;}
tsm-limitupload() { transmission-remote --uplimit "${@:-10}" ;}	# upload default to 10kpbs, else enter your own
tsm-limituploadunlimited() { transmission-remote --no-uplimit ;}
tsm-askmorepeers() { transmission-remote -t"$1" --reannounce ;}
tsm-daemon() { transmission-daemon ;}
tsm-quit() { killall transmission-daemon ;}
tsm-add() { transmission-remote --add "$1" ;}
tsm-hash() { transmission-remote --add "magnet:?xt=urn:btih:$1" ;}       # adding via hash info
tsm-verify() { transmission-remote --verify "$1" ;}
tsm-pause() { transmission-remote -t"$1" --stop ;}		# <id> or all
tsm-start() { transmission-remote -t"$1" --start ;}		# <id> or all
tsm-rad() { transmission-remote -t"$1" --remove-and-delete ;} # delete data also
tsm-remove() { transmission-remote -t"$1" --remove ;}		# leaves data alone
tsm-info() { transmission-remote -t"$1" --info ;}
tsm-speed() { while true;do clear; transmission-remote -t"$1" -i | grep Speed;sleep 1;done ;}
tsm-grep() { transmission-remote --list | grep -i "$1" ;}
tsm() { watch -n 5 transmission-remote --list ;}
tsm-show() { transmission-show "$1" ;}                          # show .torrent file information

# DEMO: http://www.youtube.com/watch?v=hLz7ditUwY8
# LINK: https://github.com/fagga/transmission-remote-cli
# DESC: ncurses frontend to transmission-daemon
tsm-ncurse() { transmission-remote-cli ;}





[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
