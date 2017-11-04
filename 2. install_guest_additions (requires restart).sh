apt-get update
apt-get upgrade
apt-get install build-essential module-assistant
m-a prepare
read -p "insert guest additions then press enter"
mount /dev/sr0 /media/cdrom
sh /media/cdrom/VBoxLinuxAdditions.run
clear
clear
echo "restart when you are ready"
