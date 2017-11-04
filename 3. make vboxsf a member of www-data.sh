#make vboxsf a member of the group of www-data
#allow myself acces to my own files than you very much
sudo usermod -aG vboxsf $(whoami)
#allow the webserver acces to the files thank you very much
sudo usermod -a -G vboxsf www-data
echo "now you can add your shared storage to nextcloud's external storage stuff"
