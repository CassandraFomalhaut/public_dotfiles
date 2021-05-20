# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Custom path
path+=$HOME/.local/bin
path+=$HOME/bin
path+=$HOME/go/bin

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Autostart sway 
if [ "$(tty)" = "/dev/tty1" ]; then
    _JAVA_AWT_WM_NONREPARENTING=1 sway
fi

# Shortcuts
alias top='btm'
alias tree='exa --all --tree --level=2 --long'
alias ssh="kitty +kitten ssh"
alias cat='bat'
alias grep='rg'
alias vim='nvim'
alias asd='cd ~/homedirs && q'
alias q='exa --all --long --header --git'
alias nmap='sudo grc nmap'
alias aurfind="pikaur -Qq | fzf --multi --preview 'pikaur -Qi {1}'"
alias aurdelete="pikaur -Qq | fzf --multi --preview 'pikaur -Qi {1}' | xargs -ro pikaur -Rns"
alias aurinstall="pikaur -Slq | fzf --multi --preview 'pikaur -Si {1}' | xargs -ro pikaur -S"
alias show_palette='for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done;'
alias offdoc_init="docker run --rm -it --name offensive_docker -p 4444:4444 -v $HOME/homedirs/pentest:/root/pentest aaaguirrep/offensive-docker /bin/zsh"
alias offdoc_exec="docker exec -it offensive_docker /bin/zsh"
alias bettercap='docker run -it --rm --privileged --net=host bettercap/bettercap -iface wlan1'
alias fluxion='docker run -it --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:ro --privileged --net=host --name=fluxion treemo/fluxion'
alias tl="task list"
alias t="task"
alias ta="task add"
alias glog='git log --pretty=format:"%h %s %cd" --graph --stat'
alias dots='cd ~/homedirs/dotfiles'
alias p10kupdate='git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull'
alias ansi_rainbow='for (( i = 30; i < 38; i++ )); do echo -e "\033[0;"$i"m Normal: (0;$i); \033[1;"$i"m Light: (1;$i)"; done'
alias crsnapshot='sudo lvcreate --snapshot --size 16G --name $(date -d "today" +"%Y%m%d%H%M") /dev/vg0/root'

# Plugins
plugins=(git zsh-completions fzf)

autoload -Uz compinit
compinit

# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# Gruvbox fzf
export FZF_DEFAULT_OPTS='
  --color fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
  --color info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54
'
# Fzf completions for zsh
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

source $ZSH/oh-my-zsh.sh

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
