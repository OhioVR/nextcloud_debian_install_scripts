#sudo needs to be installed!
#!/bin/bash
apt-get install sudo
echo "type in the user name you wish to add to sudoer"
read userName
usermod -aG sudo $userName
clear
clear
read -p "you must now log out and log in for the new sudo privilages to take effect"
