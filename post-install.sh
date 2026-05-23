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
    org.gtk.Gtk3theme.adw-gtk3 \
    org.gtk.Gtk3theme.adw-gtk3-dark \
    com.github.tchx84.Flatseal \
    org.telegram.desktop \
    com.google.Chrome \
    org.mozilla.firefox \
    com.dec05eba.gpu_screen_recorder \
    com.discordapp.Discord \
    com.spotify.Client \
    com.thincast.client \
    org.remmina.Remmina \
    im.riot.Riot \
    io.github.diegopvlk.Cine \
    org.fedoraproject.MediaWriter\
    org.gnome.Boxes \
    org.gnome.Calculator \
    org.gnome.TextEditor \
    org.kde.gwenview \
    page.codeberg.JakobDev.jdReplace \
    page.codeberg.libre_menu_editor.LibreMenuEditor

# Override global de tema escuro para todos os apps
flatpak override --system --env=GTK_THEME=adw-gtk3-dark
flatpak override --system --env=GTK_USE_PORTAL=1
