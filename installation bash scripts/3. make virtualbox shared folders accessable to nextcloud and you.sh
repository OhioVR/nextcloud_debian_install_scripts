#make vboxsf a member of the group of www-data
#allow myself acces to my own files than you very much
echo "type in the user name you wish to add to the virtualbox shared folders access group"
read userName
sudo usermod -a -G vboxsf $userName
#allow the webserver acces to the files thank you very much
sudo usermod -a -G vboxsf www-data
clear
clear
echo "after log off and on you can view your shared folders and so can www-data which is apache's user"
