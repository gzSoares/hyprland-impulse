FROM quay.io/fedora/fedora-bootc:44 AS final

LABEL ostree.bootable="true"
LABEL containers.bootc="1"

COPY locale.conf post-install.sh pacotes_desktop pacotes_necessarios post-install.service vconsole.conf zram-generator.conf ./

RUN mkdir -vp /var/roothome /data /var/home && \
    dnf5 -y upgrade --refresh && \
    dnf5 -y install kernel-modules-extra --refresh && \
    printf 'omit_dracutmodules+=" nfs "\nomit_drivers+=" nfs nfsv3 nfsv4 nfs_acl nfs_common sunrpc rxrpc rpcrdma auth_rpcgss rpcsec_gss_krb5 "\n' | tee /etc/dracut.conf.d/no-nfs.conf >/dev/null && \
    kver="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    dracut -f /usr/lib/modules/${kver}/initramfs.img ${kver} && \
    dnf5 -y install wget && \
    mv -v zram-generator.conf /etc/systemd/ && \
    mv -v vconsole.conf /etc/vconsole.conf && \
    mv -v locale.conf /etc/locale.conf && \
    rm -rvf /opt && mkdir -vp /var/opt && ln -vs /var/opt /opt && \
    mkdir -vp /var/usrlocal && mv -v /usr/local/* /var/usrlocal/ 2>/dev/null && \
    rm -rvf /usr/local && ln -vs /var/usrlocal /usr/local && \
    mv -v post-install.sh /usr/bin/post-install.sh && \
    mv -v post-install.service /usr/lib/systemd/system/post-install.service && \
    chmod +x /usr/bin/post-install.sh && \
    systemctl enable post-install.service && \
    dnf5 clean all && \
    rm -rfv /var/cache/* /var/lib/* /var/log/* /var/tmp/*

RUN dnf5 install dnf5-plugins -y

RUN dnf5 copr enable errornointernet/quickshell -y
RUN dnf5 copr enable atim/starship -y
RUN dnf5 copr enable alternateved/eza -y
RUN dnf5 copr enable sdegler/hyprland -y

RUN dnf5 install hyprland --setopt=install_weak_deps=False -y

RUN dnf5 install quickshell-git --setopt=install_weak_deps=False -y

# Pacotes de sistema — separado pra isolar erro
RUN grep -v '^#' pacotes_necessarios | tr '\n' ' ' | xargs dnf5 install -y

# Pacotes de desktop — separado pra isolar erro
RUN grep -v '^#' pacotes_desktop | tr '\n' ' ' | xargs dnf5 install -y

RUN systemctl mask systemd-remount-fs.service && \
    systemctl enable spice-vdagentd.service

# Dotfiles do II no skel
RUN dnf5 install -y git rsync && \
    git clone --filter=blob:none --recurse-submodules \
    https://github.com/end-4/dots-hyprland /tmp/dots-hyprland && \
    rsync -av /tmp/dots-hyprland/dots/ /etc/skel/ && \
    rm -rf /tmp/dots-hyprland

RUN dnf5 clean all && \
    rm -rfv /var/cache/* /var/lib/* /var/log/* /var/tmp/* \
    /var/usrlocal/share/applications/mimeinfo.cache \
    /var/roothome/.*

RUN bootc container lint

# Estágio final de otimização com Chunkah
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
