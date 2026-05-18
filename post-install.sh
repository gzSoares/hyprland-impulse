#!/bin/bash

set -e

# Troca remote Fedora pelo Flathub
if flatpak remotes | grep -q '^fedora'; then
    flatpak remote-delete fedora
    sleep 2
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Instala Flatpaks do Flathub
flatpak install -y flathub \
    org.gtk.Gtk3theme.adw-gtk3-dark \
    ca.desrt.dconf-editor \
    org.mozilla.firefox

# Override global de tema dark para todos os apps
flatpak override --system --env=GTK_THEME=adw-gtk3-dark
flatpak override --system --env=GTK_USE_PORTAL=1
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Copia dotfiles do skel pro home de todos os usuários que ainda não os têm
for userdir in /var/home/*/; do
    user=$(basename "$userdir")
    if [ "$user" = "*" ]; then continue; fi
    for dotfile in /etc/skel/.* /etc/skel/*; do
        base=$(basename "$dotfile")
        [ "$base" = "." ] || [ "$base" = ".." ] && continue
        target="$userdir/$base"
        if [ ! -e "$target" ]; then
            cp -r "$dotfile" "$target"
            chown -R "$user:$user" "$target"
        fi
    done

    sudo -u "$user" env HOME="$userdir" xdg-user-dirs-update --force
    
done
