ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME="mytheme"
DISABLE_AUTO_UPDATE="false"
FZF_BASE="/usr/share/fzf"
plugins=( fzf git z cp sudo fancy-ctrl-z )

eval $(thefuck --alias)

# aliases
alias startx="startx ~/.xinitrc"
alias ncmpcpp="ncmpcpp -q"
alias vi='nvim'
alias vim='nvim'
alias ls='exa -F'
alias l='exa -FGhl --git'
alias ltree='exa -FThl --git'
alias tree='exa -FT'
alias rls='exa -FR'
alias copy='xclip -se c'
alias neofetch='echo "\n\n" && neofetch && echo "\n"'

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh

if [[ ! -d $ZSH_CACHE_DIR ]]; then mkdir $ZSH_CACHE_DIR fi [[ -f "$ZSH/oh-my-zsh.sh" ]] \ && source $ZSH/oh-my-zsh.sh autoload -U colors && colors [[ -f "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \ && source "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" [[ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \ && source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
