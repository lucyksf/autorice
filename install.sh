#!/bin/sh

# Export the path to this directory for later use in the script
export LINKDOT=$PWD

# Install fonts and programs. Including two WMs, a terminal emulator
# App launcher, screenshot tool, pdf viewer, image viewer, and text editor.
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

# Link dash to /bin/sh for performance boost.
# Then link several font config files for better font display.
sudo ln -sfT dash /usr/bin/sh
sudo ln -sf /etc/fonts/conf.avail/75-joypixels.conf /etc/fonts/conf.d/
sudo ln -sf /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/
sudo ln -sf /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
sudo ln -sf /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/

# Misc but important. The last disables mouse acceleration and can be removed.
sudo install -Dm 644 other/freetype2.sh /etc/profile.d/
sudo install -Dm 644 other/local.conf /etc/fonts/
sudo install -Dm 644 other/dashbinsh.hook /usr/share/libalpm/hooks/
sudo install -Dm 644 other/50-mouse-acceleration.conf /etc/X11/xorg.conf.d/

# Make some folders. Screenshots will go in the captures folder.
mkdir -p ~/.config ~/Images/Captures ~/Images/Wallpapers \
    $LINKDOT/config/mpd/playlists ~/Music

# Move provided wallpapers to the wallpapers folder
mv -n wallpapers/* ~/Images/Wallpapers

# Clone the aur packages being installed. Polybar and Oh-My-Zsh
# git clone https://aur.archlinux.org/oh-my-zsh-git.git ~/.aurpkgs/oh-my-zsh-git
# git clone https://aur.archlinux.org/polybar.git ~/.aurpkgs/polybar
# ^ not working, replaced by the polybar package ^

# Install them
# cd ~/.aurpkgs/oh-my-zsh-git
# makepkg -si
# cd ~/.aurpkgs/polybar
# makepkg -si

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mkdir -p ~/.oh-my-zsh/custom/themes
cp "$LINKDOT/config/zsh/themes/"*.zsh-theme ~/.oh-my-zsh/custom/themes/
cp "$LINKDOT/config/zsh/themes/"*.zsh ~/.oh-my-zsh/custom/

# Link all dotfiles into their appropriate locations
: 'cd ~/
ln -sf $LINKDOT/home/.* .

cd ~/.config
ln -sf $LINKDOT/config/* .
'

# Link dotfiles from $LINKDOT/home into ~
cd ~
for item in "$LINKDOT"/home/.[!.]*; do
    name=$(basename "$item")

    # Skip . and .. just in case
    [ "$name" = "." ] && continue
    [ "$name" = ".." ] && continue

    # If target exists and is a directory, skip (you'll handle configs separately)
    if [ -d "$item" ]; then
        echo "-- Skipping directory $name (handled elsewhere)"
        continue
    fi

    ln -sf "$item" "$HOME/$name"
    echo "-- Linked $name"
done

# Link config directories
mkdir -p ~/.config
for item in "$LINKDOT"/config/*; do
    name=$(basename "$item")

    # If the config already exists, back it up
    if [ -e "$HOME/.config/$name" ]; then
        mv "$HOME/.config/$name" "$HOME/.config/$name.backup"
        echo "-- Backed up existing $name"
    fi

    ln -sf "$item" "$HOME/.config/$name"
    echo "-- Linked config $name"
done

echo "-- Installation Complete! Restart the computer."
