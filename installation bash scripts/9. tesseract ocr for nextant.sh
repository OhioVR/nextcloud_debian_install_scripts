#!/bin/bash

sudo apt-get install tesseract-ocr
echo "tesseract optical charactor recognition installed"
sleep 1
clear
echo "The OCR is configured to search for jpg and tiff, the script is going to enable png, if you don't want to do that press n"
read activate
if [ "$activate" != no ];then
  sudo cp SolrService.php /var/www/vhosts/nextcloud/apps/nextant/lib/Service/SolrService.php
  echo "SolrService.php containing png configuration copied to /var/www/vhosts/nextcloud/apps/nextant/lib/Service/SolrService.php"
fi
echo "restarting solr service"
service solr restart
clear
echo "ok, now tesseract is installed. However there is one thing you have to do to make it work and before you can index your files. Open your admin panel in the web interface and additional settings. Under additional settings is the nextant settings. Look for [edit your filters], click on it, then find Image and check it on. Don't be dismayed that it doesn't say png, if you enabled png with this script you will get search results from it. Put some jpg files or png files in nextcloud to do a test search. After you are done come back here and press any key to continue"
read anykey
clear
echo "type yes if you want to reindex your files at this time (if you got a lot of images this could take a while. Suggestion: add .noindex files to directorys you don't want to index if the indexer is taking too long on files you don't want to full text search on)"
read activate
if [ "$activate" = yes ]; then
sudo -u www-data php /var/www/vhosts/nextcloud/occ nextant:index
fi
echo "finished"
