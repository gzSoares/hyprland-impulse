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

# Habilitar repositórios COPR necessários
RUN dnf5 install -y dnf5-plugins && \
    dnf5 copr enable -y solopasha/hyprland && \
    dnf5 copr enable -y errornointernet/quickshell && \
    dnf5 copr enable -y heus-sueh/packages && \
    dnf5 copr enable -y atim/starship && \
    dnf5 copr enable -y alternateved/eza && \
    dnf5 clean all

# Instalar dependências do Hyprland primeiro (aquamarine traz libdisplay-info)
RUN dnf5 install -y \
    aquamarine \
    hyprcursor \
    hyprgraphics \
    hyprlang \
    hyprutils \
    hyprwayland-scanner && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Instalar Hyprland e ecossistema
RUN dnf5 install -y \
    hyprland \
    hyprlock \
    hypridle \
    hyprpicker \
    hyprsunset \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Instalar Quickshell (motor de widgets do II)
RUN dnf5 install -y \
    quickshell \
    qt6-qtbase \
    qt6-qtdeclarative \
    qt6-qt5compat \
    qt6-qtsvg \
    qt6-qtimageformats \
    qt6-qtmultimedia \
    qt6-qtwayland \
    kf6-kirigami2 \
    kdialog && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Instalar pacotes do sistema (pacotes_necessarios)
RUN grep -v '^#' pacotes_necessarios | grep -v '^$' | \
    xargs dnf5 install -y && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Instalar pacotes do desktop (pacotes_desktop)
RUN grep -v '^#' pacotes_desktop | grep -v '^$' | \
    xargs dnf5 install -y && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Clonar dotfiles do Illogical Impulse e instalar no skel
RUN dnf5 install -y git rsync && \
    git clone --filter=blob:none --recurse-submodules \
        https://github.com/end-4/dots-hyprland /tmp/dots-hyprland && \
    rsync -av /tmp/dots-hyprland/dots/ /etc/skel/ && \
    rm -rf /tmp/dots-hyprland && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/log/* /var/tmp/*

# Habilitar/mascarar serviços
RUN systemctl enable NetworkManager && \
    systemctl enable bluetooth && \
    systemctl mask systemd-remount-fs.service && \
    rm -rfv /var/roothome/.*

# Verificação final da imagem
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
