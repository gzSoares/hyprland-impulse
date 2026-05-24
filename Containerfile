FROM quay.io/fedora/fedora-bootc:44 AS final

LABEL ostree.bootable="true"
LABEL containers.bootc="1"

# Copia arquivos de configuração e scripts
COPY locale.conf post-install.sh pacotes_necessarios \
    post-install.service vconsole.conf zram-generator.conf \
    xdg-desktop-portal.service portals.conf ./

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
    dnf5 copr enable -y errornointernet/quickshell && \
    dnf5 copr enable -y heus-sueh/packages && \
    dnf5 clean all

# KDE Material You Colors (OpenSUSE Build Service repo)
RUN dnf5 config-manager addrepo \
    --from-repofile=https://download.opensuse.org/repositories/home:luisbocanegra/Fedora_44/home:luisbocanegra.repo && \
    dnf5 install -y kde-material-you-colors && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Backlight (--setopt=install_weak_deps=False)
RUN dnf5 install -y --setopt=install_weak_deps=False \
    geoclue2 \
    brightnessctl \
    ddcutil && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# (darkly e eza exigem COPRs deltacopy/darkly e alternateved/eza)
RUN dnf5 install -y \
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

# (hyprland vem do COPR sdegler/hyprland)
RUN dnf5 install -y --setopt=install_weak_deps=False \
    hyprland \
    hyprland-guiutils \
    hyprland-qt-support \
    hyprsunset \
    wl-clipboard && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Dependências Python e build (--setopt=install_weak_deps=False)
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

# (dependem dos COPRs errornointernet/quickshell e heus-sueh/packages)
RUN dnf5 install -y quickshell matugen && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# (xdg-desktop-portal-hyprland vem do COPR sdegler/hyprland)
# (xdg-desktop-portal.service corrigido para Hyprland sem graphical-session.target)
RUN dnf5 install -y \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-kde \
    xdg-desktop-portal-hyprland && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/* && \
    cp xdg-desktop-portal.service /usr/lib/systemd/user/xdg-desktop-portal.service && \
    mkdir -p /etc/skel/.config/xdg-desktop-portal && \
    cp portals.conf /etc/skel/.config/xdg-desktop-portal/portals.conf

# (hyprshot vem do COPR ririko66z/dots-hyprland)
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

# Instalação dos pacotes definidos nos arquivos de lista
RUN grep -v '^#' /tmp/setup/pacotes_necessarios | grep '^@' | sed 's/^@//' | \
    xargs -r dnf5 group install -y && \
    grep -v '^#' /tmp/setup/pacotes_necessarios | grep -v '^@' | grep -v '^$' | \
    xargs -r dnf5 install -y && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Clonar dotfiles do Illogical Impulse para /etc/skel/
RUN git clone --filter=blob:none --recurse-submodules \
    https://github.com/end-4/dots-hyprland /tmp/dots-hyprland && \
    rsync -av /tmp/dots-hyprland/dots/ /etc/skel/ && \
    rm -rf /tmp/dots-hyprland && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Corrige execs.lua — inicia xdg-desktop-portal no boot do Hyprland
# (Hyprland não ativa graphical-session.target automaticamente)
RUN sed -i \
    '/dbus-update-activation-environment --systemd/a\    hl.exec_cmd("sleep 2 && systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")' \
    /etc/skel/.config/hypr/hyprland/execs.lua

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
