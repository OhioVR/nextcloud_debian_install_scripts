#optimize nextcloud
echo "there is an error message in nextcloud's admin panel saying that opcache is all broke and stuff"
echo "so this script will copy a more fleshed out opcache.ini file to where it needs to go"
cp optcache.ini /etc/php/7.0/mods-available/opcache.ini
