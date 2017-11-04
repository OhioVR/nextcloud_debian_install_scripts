#make vboxsf a member of the group of www-data
#allow myself acces to my own files than you very much
sudo usermod -a -G vboxsf $(whoami)
#allow the webserver acces to the files thank you very much
sudo usermod -a -G vboxsf www-data
clear
clear
echo "after restarting you can view your shared folders and so can www-data which is apache's user"
