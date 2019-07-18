# Snoopy
A small script to create custom Debian image for Raspberry Pi.

## WARNING
You should not download and execute a script as root without having idea what it does.
So, please, take a look into it and make sure it fits your environment, there is not warranty.

I wrote this script to make my (and friends..) life easier deploying rpi, I tried to make it simple and clear as possible.

## Description
It creates a rpi compatible SD image and then wraps classical Debian installation strategy using debotstrap.
After that, it does few tweaks into new installation to leave it ready to power on and connect through network.

## Usage
- Clone this repo.
    git clone https://github.com/basilean/snoopy.git

- Change working directory to it.
    cd snoopy

- Edit "OPTIONS" section to fit your needs.
    vi snoopy.sh
        DEBIAN_ARCH="armhf"
        DEBIAN_VERSION="sid"
        IMAGE_HOSTNAME="nx1701"
        IMAGE_LANG="es_AR"
        IMAGE_CODE="UTF-8"
        IMAGE_TZ="America/Argentina/Buenos_Aires"

- Run it and wait for completation.
    bash snoopy.sh

- If everything was right, you should found a list of files.
(using armhf architecture and sid version)
    debian_sid_armhf.img # Image ready to be burnt into SD.
    debian_sid_armhf_key # Private RSA key for root.
    debian_sid_armhf_key.pub # Public RSA key for root
    debian_sid_armhf.log # Log of commands execution output.

- After that, burn SD.
    dd if=debian_sid_armhf.img of=/dev/mmcblk0 bs=4M

- Once you boot rpi, connect to it using ssh key.
    ssh -i debian_sid_armhf_key root@nx1701

- As first command there, resize storage partition to use whole free space.
(it will be deleted after execution to avoid mistakes and loose data)
    bash /root/resize_storage.bash

# Author
Andres Basile
