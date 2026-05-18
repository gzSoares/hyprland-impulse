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

# Override global de tema escuro para todos os apps
flatpak override --system --env=GTK_THEME=adw-gtk3-dark
flatpak override --system --env=GTK_USE_PORTAL=1

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

# Criar as pastas na /home
xdg-user-dirs-update
    
done
