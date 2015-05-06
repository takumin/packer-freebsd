#!/bin/sh

NAME=$1
TYPE=$2

if [ "${TYPE}" == "virtualbox" ]; then
	DISK=ada0
elif [ "${TYPE}" == "qemu" ]; then
	DISK=vtbd0
fi

# initial disk
gpart create -s gpt ${DISK}
gpart add -s 64k -t freebsd-boot -l boot ${DISK}
gpart add -t freebsd-ufs -l disk ${DISK}
gpart bootcode -b /boot/pmbr -p /boot/gptboot -i 1 ${DISK}
newfs -Ujl /dev/gpt/disk
tunefs -a enable /dev/gpt/disk
tunefs -N enable /dev/gpt/disk
mount /dev/gpt/disk /mnt

# install world
tar -xUpf /usr/freebsd-dist/base.txz -C /mnt
tar -xUpf /usr/freebsd-dist/kernel.txz -C /mnt

# cofigure fstab
cat > /mnt/etc/fstab << __EOF__
# Device	Mountpoint	FStype	Options	Dump	Pass #
/dev/gpt/disk	/		ufs	rw	1	1
procfs		/proc		procfs	rw	0	0
__EOF__

# initial configure
sysrc -R /mnt hostname=${NAME}
sysrc -R /mnt ifconfig_vtnet0=DHCP
sysrc -R /mnt sshd_enable=YES

# nfsv4 server configure
sysrc -R /mnt nfs_server_enable=YES
sysrc -R /mnt nfsv4_server_enable=YES
sysrc -R /mnt nfsuserd_enable=YES
sysrc -R /mnt mountd_enable=YES
sysrc -R /mnt weak_mountd_authentication=YES
sysrc -R /mnt nfs_reserved_port_only=YES
sysrc -R /mnt rpc_lockd_enable=YES
sysrc -R /mnt rpc_statd_enable=YES
sysrc -R /mnt rpcbind_enable=YES
mkdir /mnt/vagrant
cat > /mnt/etc/exports << __EOF__
V4: /
/vagrant -network 10.0.0.0 -mask 255.0.0.0
/vagrant -network 172.16.0.0 -mask 255.240.0.0
/vagrant -network 192.168.0.0 -mask 255.255.0.0
__EOF__

# nfsv4 client configure
#sysrc -R /mnt nfs_client_enable=YES
#sysrc -R /mnt nfsuserd_enable=YES
#sysrc -R /mnt nfscbd_enable=YES

# boot configure
sysrc -R /mnt -f /boot/loader.conf autoboot_delay=-1
sysrc -R /mnt -f /boot/loader.conf beastie_disable=YES

# copy resolv.conf
cp /etc/resolv.conf /mnt/etc/resolv.conf

# initial pkgng
chroot /mnt sh -c 'env ASSUME_ALWAYS_YES=YES pkg bootstrap'

# update pkg repo
chroot /mnt pkg update -q

# initial package
chroot /mnt pkg install -qy shells/bash
chroot /mnt pkg install -qy security/sudo
if [ "${TYPE}" == "virtualbox" ]; then
	chroot /mnt pkg install -qy emulators/virtualbox-ose-additions
fi
chroot /mnt pkg install -qy net/rsync
chroot /mnt pkg install -qy sysutils/rubygem-chef
chroot /mnt pkg install -qy sysutils/puppet
chroot /mnt pkg install -qy sysutils/ansible

# enable virtualbox-ose-additions
if [ "${TYPE}" == "virtualbox" ]; then
	sysrc -R /mnt vboxguest_enable=YES
	sysrc -R /mnt vboxservice_enable=YES
	sysrc -R /mnt vboxservice_flags=--disable-timesync
fi

# configure vagrant sudo
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /mnt/usr/local/etc/sudoers

# root password
echo -n "vagrant" | pw -V /mnt/etc usermod -n root -h 0

# create vagrant password
chroot /mnt pw useradd -n vagrant -c "Vagrant User" -G wheel,operator -m -s /usr/local/bin/bash -h -
echo -n "vagrant" | pw -V /mnt/etc usermod -n vagrant -h 0

# configure ssh vagrant
mkdir /mnt/home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure vagrant key" > /mnt/home/vagrant/.ssh/authorized_keys
chmod 0700 /mnt/home/vagrant/.ssh
chown -R 1001:1001 /mnt/home/vagrant/.ssh

# reboot
shutdown -r now
