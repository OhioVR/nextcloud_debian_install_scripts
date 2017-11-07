apt-get update
apt-get upgrade
apt-get install build-essential module-assistant
m-a prepare
clear
read -p "insert guest additions then press enter"
echo "sleeping for ten seconds..."
sleep 10
mount /dev/sr0 /media/cdrom
sh /media/cdrom/VBoxLinuxAdditions.run
clear
clear
echo "restart when you are ready"
