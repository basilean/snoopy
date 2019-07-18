#!/bin/bash
#
# Andres Basile
#

####### ####### ####### OPTIONS ####### ####### #######

####### Architecture
# https://www.debian.org/ports/arm/
# pi1 -> armel
# pi2, pi3 -> armhf
DEBIAN_ARCH="armhf"

####### Version
# https://www.debian.org/releases/
# unstable -> sid
# testing -> bullseye
# stable -> buster
DEBIAN_VERSION="sid"

####### Hostname
# https://en.wikipedia.org/wiki/Hostname
IMAGE_HOSTNAME="nx1701"

####### Locales
# https://en.wikipedia.org/wiki/Locale_(computer_software)
# https://wiki.debian.org/Locale
IMAGE_LANG="es_AR"
IMAGE_CODE="UTF-8"
IMAGE_TZ="America/Argentina/Buenos_Aires"

####### ####### ####### ####### ####### ####### #######


####### DEFINITIONS #######.
PACKAGES_REQUIRED="binfmt-support qemu qemu-user-static debootstrap curl unzip"
# https://www.debian.org/mirror/list
DEBIAN_REPOSITORY="http://deb.debian.org/debian/"
# https://github.com/raspberrypi/firmware
RPI_FIRMWARE_GIT="https://github.com/raspberrypi/firmware/archive/master.zip"
TARGET_IMAGE="debian_${DEBIAN_VERSION}_${DEBIAN_ARCH}.img"
CACHE_DIRECTORY="${PWD}/CACHE"
CACHE_DIRECTORY_MOUNTPOINT="${CACHE_DIRECTORY}/ROOT"
FIRMWARE_NAME="firmware-master"
ROOT_KEYPAIR="debian_${DEBIAN_VERSION}_${DEBIAN_ARCH}_key"
LOG_FILE="debian_${DEBIAN_VERSION}_${DEBIAN_ARCH}.log"
IMAGE_LOCAL="${IMAGE_LANG}.${IMAGE_CODE} ${IMAGE_CODE}"

####### COMMANDS #######
#######   RTFM   #######
# https://en.wikipedia.org/wiki/RTFM
COMMAND_APT="apt-get"
# https://manpages.debian.org/unstable/apt/apt-get.8.en.html
COMMAND_MKDIR="mkdir"
# https://manpages.debian.org/unstable/coreutils/mkdir.1.en.html
COMMAND_CURL="curl"
# https://manpages.debian.org/unstable/curl/curl.1.en.html
COMMAND_UNZIP="unzip"
# https://manpages.debian.org/unstable/unzip/unzip.1.en.html
COMMAND_DD="dd"
# https://manpages.debian.org/unstable/coreutils/dd.1.en.html
COMMAND_ECHO="echo"
# https://manpages.debian.org/unstable/coreutils/echo.1.en.html
COMMAND_FDISK="fdisk"
# https://manpages.debian.org/unstable/fdisk/fdisk.8.en.html
COMMAND_LOSETUP="losetup"
# https://manpages.debian.org/unstable/mount/losetup.8.en.html
COMMAND_MKFS_VFAT="mkfs.vfat"
# https://manpages.debian.org/unstable/dosfstools/mkfs.vfat.8.en.html
COMMAND_MKFS_EXT4="mkfs.ext4"
# https://manpages.debian.org/unstable/e2fsprogs/mkfs.ext4.8.en.html
COMMAND_BLKID="blkid"
# https://manpages.debian.org/unstable/util-linux/blkid.8.en.html
COMMAND_MOUNT="mount"
# https://manpages.debian.org/unstable/mount/mount.8.en.html
COMMAND_CP="cp"
# https://manpages.debian.org/unstable/coreutils/cp.1.en.html
COMMAND_QEMU_DEBOOTSTRAP="qemu-debootstrap"
# https://manpages.debian.org/unstable/qemu-user-static/qemu-debootstrap.1.en.html
COMMAND_RM="rm"
# https://manpages.debian.org/unstable/coreutils/rm.1.en.html
COMMAND_SSH_KEYGEN="ssh-keygen"
# https://manpages.debian.org/unstable/openssh-client/ssh-keygen.1.en.html
COMMAND_CHROOT="chroot"
# https://manpages.debian.org/buster/manpages-hu/chroot.1.hu.html.gz
COMMAND_UMOUNT="umount"
# https://manpages.debian.org/buster/mount/umount.8.en.html
COMMAND_DATE="date"
# https://manpages.debian.org/buster/coreutils/date.1.en.html

####### VARIABLES #######
TARGET_LOOP="" # loosetup
TARGET_LOOP_PARTUUID_BOOT="" # blkid
TARGET_LOOP_PARTUUID_ROOT="" # blkid
TARGET_LOOP_PARTUUID_STORAGE="" # blkid

####### PROGRAM #######
${COMMAND_ECHO} "-> Starting Logging...
${LOG_FILE}"
${COMMAND_DATE} > ${LOG_FILE}

${COMMAND_ECHO} "-> Installing packages required to create image...
${PACKAGES_REQUIRED}"
${COMMAND_APT} install -y ${PACKAGES_REQUIRED} >> ${LOG_FILE}

${COMMAND_ECHO} "-> Creating cache directory...
${CACHE_DIRECTORY}"
${COMMAND_MKDIR} ${CACHE_DIRECTORY}

${COMMAND_ECHO} "-> Downloading Raspberry Pi closed firmware and kernel...
(Yes, it IS NOT open hardware.)"
${COMMAND_CURL} -L ${RPI_FIRMWARE_GIT} -o ${CACHE_DIRECTORY}/${FIRMWARE_NAME}.zip >> ${LOG_FILE} 2>> ${LOG_FILE}

${COMMAND_ECHO} "-> Unziping firmware and kernel..."
${COMMAND_UNZIP} ${CACHE_DIRECTORY}/${FIRMWARE_NAME}.zip -d ${CACHE_DIRECTORY} >> ${LOG_FILE}

${COMMAND_ECHO} "-> Creating 2Gb image with zeros..."
${COMMAND_DD} if=/dev/zero of=${TARGET_IMAGE} bs=4M count=500 >> ${LOG_FILE}  2>> ${LOG_FILE}

${COMMAND_ECHO} "-> Making partitions...
/boot 100M
/ 1.6G
/storage (free space)"
${COMMAND_ECHO} "o
n
p
1

+100M
t
c
n
p
2

+1800M
n
p
3


a
1

w
q
" | ${COMMAND_FDISK} ${TARGET_IMAGE} >> ${LOG_FILE}

${COMMAND_ECHO} "-> Creating loop setup..."
TARGET_LOOP=`${COMMAND_LOSETUP} -vfP --show ${TARGET_IMAGE}`
${COMMAND_ECHO} ${TARGET_LOOP}

${COMMAND_ECHO} "-> Creating partition boot..."
${COMMAND_MKFS_VFAT} ${TARGET_LOOP}p1 >> ${LOG_FILE} 2>> ${LOG_FILE}
TARGET_LOOP_PARTUUID_BOOT=`${COMMAND_BLKID} -s PARTUUID -o value ${TARGET_LOOP}p1`
${COMMAND_ECHO} ${TARGET_LOOP_PARTUUID_BOOT}

${COMMAND_ECHO} "-> Creating partition root..."
${COMMAND_MKFS_EXT4} ${TARGET_LOOP}p2 >> ${LOG_FILE} 2>> ${LOG_FILE}
TARGET_LOOP_PARTUUID_ROOT=`${COMMAND_BLKID} -s PARTUUID -o value ${TARGET_LOOP}p2`
${COMMAND_ECHO} ${TARGET_LOOP_PARTUUID_ROOT}

${COMMAND_ECHO} "-> Creating partition storage..."
${COMMAND_MKFS_EXT4} ${TARGET_LOOP}p3 >> ${LOG_FILE} 2>> ${LOG_FILE}
TARGET_LOOP_PARTUUID_STORAGE=`${COMMAND_BLKID} -s PARTUUID -o value ${TARGET_LOOP}p3`
${COMMAND_ECHO} ${TARGET_LOOP_PARTUUID_STORAGE}

${COMMAND_ECHO} "-> Creating cache root mountpoint...
${CACHE_DIRECTORY_MOUNTPOINT}"
${COMMAND_MKDIR} ${CACHE_DIRECTORY_MOUNTPOINT}

${COMMAND_ECHO} "-> Mounting loop root partition..."
${COMMAND_MOUNT} ${TARGET_LOOP}p2 ${CACHE_DIRECTORY_MOUNTPOINT}

${COMMAND_ECHO} "-> Creating and mounting additional mount point and partitions..."
${COMMAND_MKDIR} ${CACHE_DIRECTORY_MOUNTPOINT}/boot
${COMMAND_MKDIR} ${CACHE_DIRECTORY_MOUNTPOINT}/storage
${COMMAND_MOUNT} ${TARGET_LOOP}p1 ${CACHE_DIRECTORY_MOUNTPOINT}/boot/
${COMMAND_MOUNT} ${TARGET_LOOP}p3 ${CACHE_DIRECTORY_MOUNTPOINT}/storage/

${COMMAND_ECHO} "-> Building Debian base system...
(It takes couple of minutes downloading, extracting and configuring.)"
${COMMAND_QEMU_DEBOOTSTRAP} --arch ${DEBIAN_ARCH} --include=ssh,locales,rng-tools ${DEBIAN_VERSION} ${CACHE_DIRECTORY_MOUNTPOINT} ${DEBIAN_REPOSITORY}  >> ${LOG_FILE} 2>> ${LOG_FILE}

${COMMAND_ECHO} "-> Copying firmware and kernel..."
${COMMAND_CP} -av ${CACHE_DIRECTORY}/${FIRMWARE_NAME}/boot/* ${CACHE_DIRECTORY_MOUNTPOINT}/boot/ >> ${LOG_FILE}
${COMMAND_CP} -av ${CACHE_DIRECTORY}/${FIRMWARE_NAME}/modules ${CACHE_DIRECTORY_MOUNTPOINT}/lib/ >> ${LOG_FILE}

${COMMAND_ECHO} "-> Configuring image..."
${COMMAND_ECHO} "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=${TARGET_LOOP_PARTUUID_ROOT} rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait" > ${CACHE_DIRECTORY_MOUNTPOINT}/boot/cmdline.txt

${COMMAND_ECHO} "proc /proc proc defaults 0 0
PARTUUID=${TARGET_LOOP_PARTUUID_BOOT} /boot vfat defaults 0 2
PARTUUID=${TARGET_LOOP_PARTUUID_ROOT} / ext4 defaults,noatime 0 1
PARTUUID=${TARGET_LOOP_PARTUUID_STORAGE} /storage ext4 defaults,noatime 0 1" > ${CACHE_DIRECTORY_MOUNTPOINT}/etc/fstab

${COMMAND_ECHO} ${IMAGE_LOCAL} > ${CACHE_DIRECTORY_MOUNTPOINT}/etc/locale.gen
${COMMAND_CHROOT} ${CACHE_DIRECTORY_MOUNTPOINT} locale-gen >> ${LOG_FILE} 2>> ${LOG_FILE}
${COMMAND_CHROOT} ${CACHE_DIRECTORY_MOUNTPOINT} update-locale LANG=${IMAGE_LANG}.${IMAGE_CODE} LANGUAGE=${IMAGE_LANG}.${IMAGE_CODE} LC_ALL=${IMAGE_LANG}.${IMAGE_CODE}  >> ${LOG_FILE} 2>> ${LOG_FILE}

${COMMAND_RM} ${CACHE_DIRECTORY_MOUNTPOINT}/etc/localtime
${COMMAND_CHROOT} ${CACHE_DIRECTORY_MOUNTPOINT} ln -s /usr/share/zoneinfo/${IMAGE_TZ} /etc/localtime
${COMMAND_CHROOT} ${CACHE_DIRECTORY_MOUNTPOINT} dpkg-reconfigure -f noninteractive tzdata >> ${LOG_FILE} 2>> ${LOG_FILE}

${COMMAND_ECHO} "[Match]
Name=enx*
[Network]
DHCP=ipv4" > ${CACHE_DIRECTORY_MOUNTPOINT}/etc/systemd/network/20-wired.network
${COMMAND_CHROOT} ${CACHE_DIRECTORY_MOUNTPOINT} systemctl enable systemd-networkd.service >> ${LOG_FILE} 2>> ${LOG_FILE}

${COMMAND_ECHO} ${IMAGE_HOSTNAME} > ${CACHE_DIRECTORY_MOUNTPOINT}/etc/hostname

${COMMAND_RM} ${CACHE_DIRECTORY_MOUNTPOINT}/lib/systemd/system/getty.target.wants/getty-static.service

${COMMAND_ECHO} "-> Creating ssh key pair for root..."
${COMMAND_SSH_KEYGEN} -b 4096 -t rsa -f ${ROOT_KEYPAIR} -N ""  >> ${LOG_FILE}

${COMMAND_ECHO} "-> Copying key into image..."
${COMMAND_MKDIR} ${CACHE_DIRECTORY_MOUNTPOINT}/root/.ssh
${COMMAND_CP} -v ${ROOT_KEYPAIR}.pub ${CACHE_DIRECTORY_MOUNTPOINT}/root/.ssh/authorized_keys >> ${LOG_FILE}

${COMMAND_ECHO} "-> Copying storage resize script..."
${COMMAND_ECHO} "#!/bin/bash
umount /storage
echo \"d
3
n
p
3


n
w
\" | fdisk /dev/mmcblk0
resize2fs /dev/mmcblk0p3
fsck -fy /dev/mmcblk0p3
mount /storage
rm /root/resize_storage.bash" > ${CACHE_DIRECTORY_MOUNTPOINT}/root/resize_storage.bash

${COMMAND_ECHO} "-> Umounting loop device partitions..."
${COMMAND_UMOUNT} ${TARGET_LOOP}p1
${COMMAND_UMOUNT} ${TARGET_LOOP}p3
${COMMAND_UMOUNT} ${TARGET_LOOP}p2

${COMMAND_ECHO} "-> Cleaning loop device..."
${COMMAND_LOSETUP} -d ${TARGET_LOOP}

${COMMAND_ECHO} "-> Removing cache directory..."
${COMMAND_RM} -r ${CACHE_DIRECTORY}

${COMMAND_ECHO} "******* NEXT STEPS *******
- Copy image into SD
    ${COMMAND_DD} if=${TARGET_IMAGE} of=/dev/mmcblk0 bs=4M
    sync
- Login into new machine
    ssh -i ${ROOT_KEYPAIR} root@${IMAGE_HOSTNAME}
- Resize storage partition at new machine
    bash /root/resize_storage.bash

Have fun!
"
