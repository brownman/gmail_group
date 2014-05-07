echo install dependencies 
sudo apt-get install -y `cat gmail_group.sh | grep depend -m1 | sed 's/#depend://g'`
 exit
echo --------

cat .travis.yml
echo -----------
bash -c ./.present.sh
