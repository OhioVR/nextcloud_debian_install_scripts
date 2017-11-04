#!/bin/bash
#we need if config and unfortunately debian doesn't install this by default
sudo apt-get install net-tools
clear
clear
echo "this script didn't do much besides just install net-tools which debian should have had installed normally anyway"
echo "what you will need to do is go into your router's lan config and set the ip address of this virtual machine to be static. You could write a script that did this and it would be great. Please share one if you make it. Besides the static ip you will also need to forward ports 443 and 80 to that ip address in your router to make it accessable to the outside."
echo "In case you were wondering what your ip address currently is it is:"
hostname -I
