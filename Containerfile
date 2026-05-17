FROM quay.io/fedora/fedora-bootc:44 AS final

LABEL ostree.bootable="true"
LABEL containers.bootc="1"

# Copia arquivos de configuração e scripts
COPY locale.conf post-install.sh pacotes_desktop pacotes_necessarios \
     post-install.service vconsole.conf zram-generator.conf ./

# Configuração base do sistema
RUN mkdir -vp /var/roothome /data /var/home && \
    dnf5 -y upgrade --refresh && \
    dnf5 -y install kernel-modules-extra --refresh && \
    printf 'omit_dracutmodules+=" nfs "\nomit_drivers+=" nfs nfsv3 nfsv4 nfs_acl nfs_common sunrpc rxrpc rpcrdma auth_rpcgss rpcsec_gss_krb5 "\n' \
        | tee /etc/dracut.conf.d/no-nfs.conf >/dev/null && \
    kver="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    dracut -f /usr/lib/modules/${kver}/initramfs.img ${kver} && \
    mv -v zram-generator.conf /etc/systemd/ && \
    mv -v vconsole.conf /etc/vconsole.conf && \
    mv -v locale.conf /etc/locale.conf && \
    rm -rvf /opt && mkdir -vp /var/opt && ln -vs /var/opt /opt && \
    mkdir -vp /var/usrlocal && mv -v /usr/local/* /var/usrlocal/ 2>/dev/null || true && \
    rm -rvf /usr/local && ln -vs /var/usrlocal /usr/local && \
    mv -v post-install.sh /usr/bin/post-install.sh && \
    mv -v post-install.service /usr/lib/systemd/system/post-install.service && \
    chmod +x /usr/bin/post-install.sh && \
    systemctl enable post-install.service && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Habilitar repositórios COPR
RUN dnf5 install -y dnf5-plugins && \
    dnf5 copr enable -y ririko66z/dots-hyprland && \
    dnf5 copr enable -y sdegler/hyprland && \
    dnf5 copr enable -y deltacopy/darkly && \
    dnf5 copr enable -y alternateved/eza && \
    dnf5 copr enable -y atim/starship && \
    dnf5 clean all

# Áudio
RUN dnf5 install -y \
    cava \
    pavucontrol \
    wireplumber \
    libdbusmenu-gtk3-devel \
    playerctl && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Backlight
RUN dnf5 install -y --setopt=install_weak_deps=False \
    geoclue2 \
    brightnessctl \
    ddcutil && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Utilitários básicos
RUN dnf5 install -y \
    coreutils \
    cliphist \
    cmake \
    curl \
    wget2 \
    ripgrep \
    jq \
    xdg-utils \
    rsync \
    yq && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Cursor Bibata
RUN dnf5 install -y bibata-cursor-theme && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Temas, fontes e ambiente visual
RUN dnf5 install -y \
    adw-gtk3-theme \
    breeze-cursor-theme \
    grub2-breeze-theme \
    breeze-icon-theme \
    breeze-icon-theme-fedora \
    kf6-breeze-icons \
    sddm-breeze \
    breeze-plus-icon-theme \
    darkly \
    eza \
    fish \
    fontconfig \
    kitty \
    florian-karsten-space-grotesk-fonts \
    starship \
    jetbrains-mono-nerd-fonts \
    google-material-symbols-vf-rounded-fonts \
    material-icons-fonts \
    readex-pro-fonts-all \
    google-rubik-vf-fonts \
    twitter-twemoji-fonts \
    google-sans-flex-vf-fonts && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Hyprland
RUN dnf5 install -y --setopt=install_weak_deps=False \
    hyprland \
    "hyprland-guiutils" \
    "hyprland-qt-support" \
    hyprsunset \
    wl-clipboard && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# KDE / sistema
RUN dnf5 install -y \
    bluedevil \
    gnome-keyring \
    NetworkManager \
    plasma-nm \
    polkit-kde \
    dolphin \
    plasma-systemsettings && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# MicroTeX (renderizador LaTeX do II)
RUN dnf5 install -y microtex && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Portais XDG
RUN dnf5 install -y \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-kde \
    xdg-desktop-portal-hyprland && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Dependências Python e build
RUN dnf5 install -y --setopt=install_weak_deps=False \
    clang \
    uv \
    gtk4-devel \
    libadwaita-devel \
    libsoup3-devel \
    libportal-gtk4 \
    gobject-introspection-devel \
    python3 \
    python3.12 \
    python3-devel \
    python3.12-devel && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Quickshell e matugen (via repo local do II)
# O repo local precisa estar disponível — aqui usamos o COPR do errornointernet como substituto
RUN dnf5 install -y dnf5-plugins && \
    dnf5 copr enable -y errornointernet/quickshell && \
    dnf5 copr enable -y heus-sueh/packages && \
    dnf5 install -y quickshell matugen && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Captura de tela
RUN dnf5 install -y \
    hyprshot \
    slurp \
    swappy \
    tesseract \
    tesseract-langpack-eng \
    tesseract-langpack-chi_sim \
    wf-recorder && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Utilitários de entrada e sistema
RUN dnf5 install -y \
    polkit \
    polkit-kde \
    polkit-qt \
    polkit-qt5-1 \
    polkit-qt6-1 \
    upower \
    thermald \
    lm_sensors \
    wtype \
    ydotool && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Utilitários extras
RUN dnf5 install -y \
    fuzzel \
    glib2 \
    ImageMagick \
    hypridle \
    hyprlock \
    hyprpicker \
    songrec \
    translate-shell \
    qalculate \
    wlogout && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Extras opcionais
RUN dnf5 install -y --setopt=install_weak_deps=False \
    mpvpaper \
    plasma-systemmonitor \
    java-latest-openjdk \
    gnome-disk-utility \
    ark \
    unzip && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Instalar pacotes de sistema (pacotes_necessarios)
RUN grep -v '^#' pacotes_necessarios | grep -v '^$' | \
    xargs dnf5 install -y && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Clonar dotfiles do Illogical Impulse para /etc/skel/
RUN git clone --filter=blob:none --recurse-submodules \
        https://github.com/end-4/dots-hyprland /tmp/dots-hyprland && \
    rsync -av /tmp/dots-hyprland/dots/ /etc/skel/ && \
    rm -rf /tmp/dots-hyprland && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Habilitar/mascarar serviços
RUN systemctl enable NetworkManager && \
    systemctl enable bluetooth && \
    systemctl enable thermald && \
    systemctl mask systemd-remount-fs.service && \
    rm -rfv /var/roothome/.*

# Verificação final
RUN bootc container lint

# Estágio de otimização com Chunkah
FROM quay.io/coreos/chunkah AS chunkah

ARG CHUNKAH_CONFIG_STR

RUN --mount=from=final,src=/,target=/chunkah,ro \
    --mount=type=bind,target=/run/src,rw \
    chunkah build --max-layers 128 \
        --label ostree.commit- \
        --label ostree.final-diffid- \
        > /run/src/out.ociarchive

FROM oci-archive:out.ociarchive

LABEL ostree.bootable="true"
LABEL containers.bootc="1"
