#!/bin/bash
NC_APPS_PATH=/var/www/vhosts/nextcloud/apps/
NT_DL=https://github.com/nextcloud/nextant/releases/download/v1.0.8/nextant-1.0.8.tar.gz
NT_RELEASE=nextant-1.0.8.tar.gz
NCPATH=/var/www/vhosts/nextcloud
SOLR_DSCONF=/opt/solr/server/solr/configsets/data_driven_schema_configs/conf/solrconfig.xml
SOLR_JETTY=/opt/solr/server/etc/jetty-http.xml

wget -q http://apache.claz.org/lucene/solr/6.6.2/solr-6.6.2.tgz --show-progress
tar -zxf solr-6.6.2.tgz
bash ./solr-6.6.2/bin/install_solr_service.sh solr-6.6.2.tgz &
count=0
while ! timeout 1 bash -c "echo > /dev/tcp/localhost/8983"; do
clear
case "$count" in
0)
  echo 'waiting for solr to start |';;
1)
  echo 'waiting for solr to start /';;
2)
  echo 'waiting for solr to start –';;
3)
  echo 'waiting for solr to start \';;
esac
sleep 0.5;
((count=count+1));
if [ $count -gt 3 ]; then
    ((count=0));
fi
done



sudo sed -i '35,37  s/"jetty.host" \//"jetty.host" default="127.0.0.1" \//' $SOLR_JETTY

iptables -A INPUT -p tcp -s localhost --dport 8983 -j ACCEPT
iptables -A INPUT -p tcp --dport 8983 -j DROP

sudo -u solr /opt/solr/bin/solr create -c nextant

# Add search suggestions feature
sed -i '2i <!DOCTYPE config [' "$SOLR_DSCONF"
sed -i "3i   <\!ENTITY nextant_component SYSTEM \"$NCPATH/apps/nextant/config/nextant_solrconfig.xml\"\>" "$SOLR_DSCONF"
sed -i '4i   ]>' "$SOLR_DSCONF"

sed -i '$d' "$SOLR_DSCONF" | sed -i '$d' "$SOLR_DSCONF"
echo "
&nextant_component;
</config>" | tee -a "$SOLR_DSCONF"

echo "SOLR_OPTS=\"\$SOLR_OPTS -Dsolr.allow.unsafe.resourceloading=true\"" | sudo tee -a /etc/default/solr.in.sh

service solr restart

wget -q -P "$NC_APPS_PATH" "$NT_DL" --show-progress
cd "$NC_APPS_PATH"
tar zxf "$NT_RELEASE"
echo "10"
# Enable Nextant
rm -r "$NT_RELEASE"
sudo -u www-data php $NCPATH/occ app:enable nextant
chown -R www-data:www-data $NCPATH/apps
sudo -u www-data php $NCPATH/occ nextant:test http://127.0.0.1:8983/solr/ nextant --save
sudo -u www-data php $NCPATH/occ nextant:index
echo "done, see if you can do full text searches now"
