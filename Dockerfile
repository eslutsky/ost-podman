FROM centos:8

RUN sysctl -a|grep ipv6|grep accept_ra\ | sed s/.$/2/ >> /etc/sysctl.conf

COPY . /work
WORKDIR /work

ENV container docker

RUN dnf -y update && dnf clean all

### SYSTEMD ###
RUN dnf -y install systemd && dnf clean all && \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

### LIBVIRT ###
RUN dnf install -y python3.9 python39-devel python3-pip python3-gobject \
git curl wget jq \
libcurl-devel sudo which \
gcc openssl-devel libxml2-devel libvirt-daemon-kvm virt-install fuse-overlayfs sudo socat   

## PODMAN ###
RUN dnf install -y podman
RUN useradd podman; \
    echo podman:10000:5000 > /etc/subuid; \
    echo podman:10000:5000 > /etc/subgid;
RUN chown podman:podman -R /home/podman
RUN chown podman:podman -R /work

RUN echo "podman        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
RUN usermod -a -G qemu podman

## required for OST runs
RUN dnf install -y policycoreutils-python-utils

# Enable libvirtd and virtlockd services.
RUN systemctl enable libvirtd
RUN systemctl enable virtlockd

# Add configuration for "default" storage pool.
RUN mkdir -p /etc/libvirt/storage
COPY pool-default.xml /etc/libvirt/storage/default.xml

# Socat service
COPY lib/ovirt-engine-socat.service /usr/lib/systemd/system/ovirt-engine-socat.service
RUN systemctl enable ovirt-engine-socat

VOLUME /var/lib/docker

# The entrypoint.sh script runs before services start up to ensure that
# critical directories and permissions are correct.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/sbin/init"]
