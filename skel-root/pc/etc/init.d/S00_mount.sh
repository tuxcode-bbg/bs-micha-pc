#!/bin/sh

PATH=/var/bin:/bin:/usr/bin:/var/sbin:/sbin:/usr/sbin

# Create console and null devices if they don't exist.
[ -e /dev/console ] || mknod -m 644 /dev/console c 5 1
[ -e /dev/null ] || mknod -m 666 /dev/null  c 1 3

mount -t tmpfs tmpfs /tmp
mount -t sysfs sys /sys
mount -t tmpfs tmp /tmp
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
mkdir -p /dev/shm/usb
mount -t usbfs none /proc/bus/usb
mkdir -p /tmp/dev
#mount -a

# directory for mounting disks
mkdir /tmp/media
rm -rf /media
ln -s /tmp/media /	# /media points to /tmp/media/

## do not mount or update var, if network is up at this point, ie nfs boot
#ETH0_LINK_STATUS=`ip link show eth0 up`
#if [ "x$ETH0_LINK_STATUS" != "x" ]; then
#	exit
#fi

# the ethernet chip needs 2 seconds to initialize...
# ...so start it *now*, then real network setup is fast
echo "ifconfig eth0 up"
/sbin/ifconfig eth0 up

if [ -f /var/etc/.factory ]; then
	exit
fi

VARDEV=`grep -i var /proc/mtd | cut -f 0 -s -d :`

if [ -z $VARDEV ]; then
        echo no var partition found
else
        if [ ! -d /var_init ]; then
                echo Rename /var to /var_init
                /bin/mv /var /var_init
        fi
        if [ ! -d /var ]; then
                /bin/mkdir /var
        fi

	if [ -f /var_init/etc/.reset ]; then
                echo Factory reset, erasing var /dev/$VARDEV
		/bin/rm /var_init/etc/.reset
                /sbin/flash_eraseall /dev/$VARDEV
	fi

        VARBLOCK=`grep -i var /proc/mtd | cut -b 4`
        echo try to mount /dev/mtdblock$VARBLOCK to /var
        /bin/mount -t jffs2 /dev/mtdblock$VARBLOCK /var
        if [ $? != 0 ]; then
                echo Erasing var /dev/$VARDEV
                /sbin/flash_eraseall /dev/$VARDEV
                echo try to mount /dev/mtdblock$VARBLOCK to /var
                /bin/mount -t jffs2 /dev/mtdblock$VARBLOCK /var
        fi
        if [ $? != 0 ]; then
                echo failed to mount /var
                /bin/rmdir /var && /bin/mv /var_init /var
        else
                if [ ! -d /var/tuxbox ]; then
                        /bin/cp -a /var_init/* /var/
			/bin/rm -f /var_init/etc/.newimage
                fi
                if [ ! -f /var/etc/network/interfaces ]; then
                        /bin/cp -a /var_init/etc /var/
                fi
                if [ -f /var_init/etc/.newimage ]; then
			/bin/rm /var_init/etc/.newimage
			/bin/cp /var_init/tuxbox/config/cables.xml /var/tuxbox/config/cables.xml
			/bin/cp /var_init/tuxbox/config/satellites.xml /var/tuxbox/config/satellites.xml
			/bin/cp /var_init/tuxbox/config/encoding.conf /var/tuxbox/config/encoding.conf
			/bin/cp /var_init/tuxbox/config/providermap.xml /var/tuxbox/config/providermap.xml
                fi
                if [ ! -d /var/etc/opkg ]; then
			/bin/cp -a /var_init/etc/opkg /var/etc
			/bin/cp -a /var_init/lib/opkg /var/lib
                fi
                if [ ! -d /var/etc/dropbear ]; then
			/bin/mkdir /var/etc/dropbear
			/bin/touch /var/etc/.dropbear

                fi
        fi
fi
