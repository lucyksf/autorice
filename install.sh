#!/usr/bin/env bash

set -uo pipefail

LINKDOT="${LINKDOT:-$PWD}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/dotfiles_backup/$(date +%Y%m%d%H%M%S)}"
mkdir -p "$BACKUP_DIR"

echo "autorice installer"
echo "  repo root: $LINKDOT"
echo "  backups:   $BACKUP_DIR"
echo

# Require bash-only features (nullglob, dotglob)
shopt -s nullglob dotglob

sudo pacman -S ttf-croscore noto-fonts-cjk noto-fonts \
    ttf-fantasque-sans-mono ttf-linux-libertine rofi mpv maim \
    alacritty alacritty-terminfo picom dash neovim \
    feh sxhkd bspwm i3-gaps polybar dunst zathura-pdf-mupdf libnotify \
    diff-so-fancy zsh-autosuggestions zsh-syntax-highlighting \
    xorg-server xorg-xinit xorg-xprop pulseaudio-alsa eza xclip thefuck

yay -S ttf-joypixels apulse

read -p "-- For music, use mpd + ncmpcpp instead of cmus? [y/N] " yna
case $yna in
    [Yy]* ) sudo pacman -S mpd ncmpcpp
        patch home/.xinitrc < other/add-mpd.patch
        ;;
    * ) sudo pacman -S cmus;;
esac

# Optionally install some more programs. Including a file manager,
# find, cat, grep, and curl replacements. And a powerful image viewer.
read -p "-- Install extras? (nnn fd bat ripgrep httpie sxiv fzf) [Y/n] " ynb
case $ynb in
    ''|[Yy]* ) sudo pacman -S nnn fd bat ripgrep httpie sxiv fzf
        patch home/.zshrc < other/add-fzf.patch
        ;;
    * ) echo "-- Extras Skipped";;
esac

# helper: move existing target to backup
backup_and_move() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local bn
    bn="$(basename "$target")"
    local dest="$BACKUP_DIR/${bn}.$(date +%s).backup"
    echo "  backing up $target -> $dest"
    mv "$target" "$dest"
  fi
}

# 1) Link home dotfiles (files only). Skip .config here.
if [ -d "$LINKDOT/home" ]; then
  echo "Linking files from $LINKDOT/home -> ~"
  for src in "$LINKDOT/home"/.[!.]* "$LINKDOT/home"/..?*; do
    [ -e "$src" ] || continue
    base="$(basename "$src")"
    # avoid . and ..
    [[ "$base" = "." || "$base" = ".." ]] && continue
    # skip .config (handled later)
    if [ "$base" = ".config" ]; then
      echo "  skipping .config (handled via config/)"
      continue
    fi
    # skip directories in home/ (only link files)
    if [ -d "$src" ]; then
      echo "  skipping directory $base (home/ should contain files only)"
      continue
    fi

    dest="$HOME/$base"
    if [ -L "$dest" ]; then
      # if it's already the same link -> skip
      if [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        echo "  already linked: $dest"
        continue
      else
        backup_and_move "$dest"
      fi
    elif [ -e "$dest" ]; then
      backup_and_move "$dest"
    fi

    ln -sfn "$src" "$dest"
    echo "  linked: $dest -> $src"
  done
  echo
fi

# Ensure ~/.config exists
mkdir -p "$HOME/.config"

# 2) Handle everything under config/
if [ -d "$LINKDOT/config" ]; then
  echo "Processing config/ -> ~/.config/"
  for src in "$LINKDOT/config"/*; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    dest="$HOME/.config/$name"

    case "$name" in
      git)
        # If a specific gitconfig exists, link it to ~/.gitconfig
        gitcfg=""
        if [ -f "$src/.gitconfig" ]; then gitcfg="$src/.gitconfig"; fi
        if [ -f "$src/gitconfig" ]; then gitcfg="$src/gitconfig"; fi

        if [ -n "$gitcfg" ]; then
          if [ -e "$HOME/.gitconfig" ] || [ -L "$HOME/.gitconfig" ]; then
            backup_and_move "$HOME/.gitconfig"
          fi
          ln -sfn "$gitcfg" "$HOME/.gitconfig"
          echo "  linked: ~/.gitconfig -> $gitcfg"
        else
          # fallback: symlink whole directory to ~/.config/git
          if [ -e "$dest" ] || [ -L "$dest" ]; then
            backup_and_move "$dest"
          fi
          ln -sfn "$src" "$dest"
          echo "  linked: $dest -> $src"
        fi
        ;;

      zsh)
        # Symlink config/zsh -> ~/.config/zsh
        if [ -e "$HOME/.config/zsh" ] || [ -L "$HOME/.config/zsh" ]; then
          backup_and_move "$HOME/.config/zsh"
        fi
        ln -sfn "$src" "$HOME/.config/zsh"
        echo "  linked: ~/.config/zsh -> $src"

        # Ensure Oh My Zsh exists (clone if missing)
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
          echo "  oh-my-zsh not found -> cloning to ~/.oh-my-zsh"
          git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" 2>/dev/null || true
        fi

        # Copy themes and aliases into oh-my-zsh/custom/
        if [ -d "$src/themes" ]; then
          mkdir -p "$HOME/.oh-my-zsh/custom/themes"
          cp -a "$src/themes/"*.zsh-theme "$HOME/.oh-my-zsh/custom/themes/" 2>/dev/null || true
          echo "  copied zsh themes -> ~/.oh-my-zsh/custom/themes/"
        fi
        if [ -f "$src/themes/aliases.zsh" ]; then
          mkdir -p "$HOME/.oh-my-zsh/custom"
          cp -a "$src/themes/aliases.zsh" "$HOME/.oh-my-zsh/custom/" 2>/dev/null || true
          echo "  copied aliases.zsh -> ~/.oh-my-zsh/custom/"
        fi
        ;;

      *)
        # Default: symlink the config folder into ~/.config/<name>
        if [ -e "$dest" ] || [ -L "$dest" ]; then
          backup_and_move "$dest"
        fi
        ln -sfn "$src" "$dest"
        echo "  linked: $dest -> $src"
        ;;
    esac
  done
  echo
fi

echo "Installation complete."
echo "Backups (if any) are in: $BACKUP_DIR"
echo "If something looks off, you can restore items from the backup directory."
