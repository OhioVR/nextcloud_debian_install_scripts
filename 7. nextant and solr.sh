NC_APPS_PATH=/var/www/vhosts/nextcloud/apps/
NT_DL=https://github.com/nextcloud/nextant/releases/download/v1.0.7/nextant-1.0.7.tar.gz
NT_RELEASE=nextant-1.0.7.tar.gz
NCPATH=/var/www/vhosts/nextcloud/
SOLR_DSCONF=/opt/solr-7.1.0/server/solr/configsets/_default/conf
SOLR_JETTY=/opt/solr/server/etc/jetty-http.xml

echo "1"
wget -q http://apache.claz.org/lucene/solr/7.1.0/solr-7.1.0.tgz --show-progress
echo "2"
tar -zxf solr-7.1.0.tgz
echo "3"
bash ./solr-7.1.0/bin/install_solr_service.sh solr-7.1.0.tgz &
echo "(going to sleep for 20 seconds to wait for solr to start up)"
sleep 20







clear
echo "4"
sudo sed -i '35,37  s/"jetty.host" \//"jetty.host" default="127.0.0.1" \//' $SOLR_JETTY

iptables -A INPUT -p tcp -s localhost --dport 8983 -j ACCEPT
iptables -A INPUT -p tcp --dport 8983 -j DROP

clear
echo "5"
sudo -u solr /opt/solr/bin/solr create -c nextant
clear
echo "6"
# Add search suggestions feature
sed -i '2i <!DOCTYPE config [' "$SOLR_DSCONF"
sed -i "3i   <\!ENTITY nextant_component SYSTEM \"$NCPATH/apps/nextant/config/nextant_solrconfig.xml\"\>" "$SOLR_DSCONF"
sed -i '4i   ]>' "$SOLR_DSCONF"

sed -i '$d' "$SOLR_DSCONF" | sed -i '$d' "$SOLR_DSCONF"
echo "
&nextant_component;
</config>" | tee -a "$SOLR_DSCONF"
clear
echo "7"
echo "SOLR_OPTS=\"\$SOLR_OPTS -Dsolr.allow.unsafe.resourceloading=true\"" | sudo tee -a /etc/default/solr.in.sh
clear
echo "8"
service solr restart
clear
echo "9"





















wget -q -P "$NC_APPS_PATH" "$NT_DL" --show-progress
cd "$NC_APPS_PATH"
tar zxf "$NT_RELEASE"
clear
echo "10"
# Enable Nextant
rm -r "$NT_RELEASE"
sudo -u www-data php $NCPATH/occ app:enable nextant
chown -R www-data:www-data $NCPATH/apps
sudo -u www-data php $NCPATH/occ nextant:test http://127.0.0.1:8983/solr/ nextant --save
sudo -u www-data php $NCPATH/occ nextant:index
clear
echo "done, see if you can do full text searches now"
