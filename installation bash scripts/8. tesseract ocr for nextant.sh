sudo apt-get install tesseract-ocr
echo "tesseract optical charactor recognition installed"
echo "The OCR is configured to search for jpg and tiff, the script is going to enable png, if you don't want to do that press n"
read activate
if [ $activate = no ]
then
else
  sudo cp SolrService.php /var/www/vhosts/nextcloud/apps/nextant/lib/Service/SolrService.php
  echo "SolrService.php containing png configuration copied to /var/www/vhosts/nextcloud/apps/nextant/lib/Service/SolrService.php"
fi
echo "restarting solr service"
service solr restart

echo "type yes if you want to reindex your files at this time (if you got a lot of images this could take a while. Suggestion: add .noindex files to directorys you don't want to index if the indexer is taking too long on files you don't want to full text search on)"
read activate
if [ $activate = yes ]
sudo -u www-data php /var/www/vhosts/nextcloud/occ nextant:index
fi
echo "finished"
