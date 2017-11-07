#!/bin/bash
echo "What you will need to do is go into your router's lan config and set the ip address of this virtual machine to be static. You could write a script that did this and it would be great. Please share one if you make it. Since you will need to forward ports 443 and 80 before you begin installing nextcloud, you might as well set the ip of this VM to static while you are at it."
echo "In case you were wondering what your ip address currently is it is:"
hostname -I
echo "after that run the next script which installs nextcloud"
