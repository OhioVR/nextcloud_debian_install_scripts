echo "1"
wget -q http://apache.claz.org/lucene/solr/7.1.0/solr-7.1.0.tgz --show-progress
echo "2"
tar -zxf solr-7.1.0.tgz
echo "3"
bash ./solr-7.1.0/bin/install_solr_service.sh solr-7.1.0.tgz &
echo "(going to sleep for 20 seconds to wait for solr to start up)"
sleep 20
echo "5"
sudo -u solr /opt/solr/bin/solr create -c nextant

NC_APPS_PATH=/var/www/vhosts/nextcloud/apps/
NT_DL=https://github.com/nextcloud/nextant/releases/download/v1.0.7/nextant-1.0.7.tar.gz
NT_RELEASE=nextant-1.0.7.tar.gz
NCPATH=/var/www/vhosts/nextcloud/
wget -q -P "$NC_APPS_PATH" "$NT_DL" --show-progress
cd "$NC_APPS_PATH"
tar zxf "$NT_RELEASE"
clear
echo "8"
# Enable Nextant
rm -r "$NT_RELEASE"
sudo -u www-data php $NCPATH/occ app:enable nextant
chown -R www-data:www-data $NCPATH/apps
sudo -u www-data php $NCPATH/occ nextant:test http://127.0.0.1:8983/solr/ nextant --save
sudo -u www-data php $NCPATH/occ nextant:index
clear
echo "done, see if you can do full text searches now"
