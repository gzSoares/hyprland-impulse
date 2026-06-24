FROM quay.io/fedora/fedora-bootc:44 AS final

LABEL ostree.bootable="true"
LABEL containers.bootc="1"

COPY locale.conf post-install.sh pacotes_necessarios \
    post-install.service vconsole.conf zram-generator.conf ./

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

# Habilita COPRs
RUN dnf5 -y install 'dnf5-command(copr)' && \
    dnf5 copr enable -y ririko66z/dots-hyprland && \
    dnf5 copr enable -y sdegler/hyprland && \
    dnf5 copr enable -y deltacopy/darkly && \
    dnf5 copr enable -y alternateved/eza && \
    dnf5 copr enable -y atim/starship && \
    dnf5 copr enable -y errornointernet/quickshell && \
    dnf5 copr enable -y heus-sueh/packages && \
    dnf5 config-manager addrepo \
        --from-repofile=https://download.opensuse.org/repositories/home:luisbocanegra/Fedora_44/home:luisbocanegra.repo

# Pacotes do COPR ririko66z/dots-hyprland — separados para diagnóstico
# Se algum não existir, o build vai indicar qual
RUN dnf5 install -y \
        bibata-cursor-theme \
        breeze-plus-icon-theme \
        florian-karsten-space-grotesk-fonts \
        google-material-symbols-vf-rounded-fonts \
        google-roboto-flex-fonts \
        google-rubik-vf-fonts \
        google-sans-flex-vf-fonts \
        hyprland-qt-support \
        jetbrains-mono-fonts \
        microtex \
        python-materialyoucolor \
        quickshell-git \
        songrec && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Pacotes do COPR sdegler/hyprland
RUN dnf5 install -y \
        cliphist \
        hyprcursor \
        hyprdim \
        hyprgraphics \
        hypridle \
        hyprland \
        hyprland-guiutils && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Pacotes de COPRs individuais
RUN dnf5 install -y darkly && \
    dnf5 install -y eza && \
    dnf5 install -y starship && \
    dnf5 install -y quickshell && \
    dnf5 install -y matugen && \
    dnf5 install -y kde-material-you-colors && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# KDE / sistema
RUN dnf5 install -y \
    ark \
    bluedevil \
    bluez \
    dolphin \
    gnome-keyring \
    gnome-keyring-pam \
    NetworkManager \
    plasma-nm \
    plasma-systemsettings \
    polkit-kde \
    sddm-breeze && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Utilitários
RUN dnf5 install -y \
    adw-gtk3-theme \
    easyeffects \
    ffmpeg-free \
    java-21-openjdk \
    lm_sensors \
    mpvpaper \
    ntfs-3g \
    plasma-systemmonitor \
    thermald \
    unzip \
    upower \
    wtype \
    ydotool && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Portais XDG
COPY xdg-desktop-portal.service portals.conf ./

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

RUN git clone --filter=blob:none --recurse-submodules \
    https://github.com/end-4/dots-hyprland /tmp/dots-hyprland && \
    rsync -av /tmp/dots-hyprland/dots/ /etc/skel/ && \
    rm -rf /tmp/dots-hyprland && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

RUN sed -i \
    '/dbus-update-activation-environment --systemd/a\    hl.exec_cmd("sleep 2 && systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")' \
    /etc/skel/.config/hypr/hyprland/execs.lua

RUN systemctl enable NetworkManager && \
    systemctl enable bluetooth && \
    systemctl enable thermald && \
    systemctl mask systemd-remount-fs.service && \
    systemctl disable bootc-fetch-apply-updates.timer && \
    rm -rfv /var/roothome/.*

RUN grep -v '^#' /pacotes_necessarios | grep '^@' | sed 's/^@//' | \
    xargs -r dnf5 group install -y && \
    grep -v '^#' /pacotes_necessarios | grep -v '^@' | grep -v '^$' | \
    xargs -r dnf5 install -y && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

RUN bootc container lint

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
