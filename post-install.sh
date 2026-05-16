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
    org.mozilla.firefox \
    org.remmina.Remmina \
    com.discordapp.Discord \
    com.spotify.Client \
    com.thincast.client \
    im.riot.Riot \
    org.fedoraproject.MediaWriter \
    org.gtk.Gtk3theme.adw-gtk3-dark \
    page.codeberg.JakobDev.jdReplace \
    page.codeberg.libre_menu_editor.LibreMenuEditor \
    com.dec05eba.gpu_screen_recorder \
    org.gnome.TextEditor

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
done
