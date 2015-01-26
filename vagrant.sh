#!/bin/bash
# Bash script alternative to get addons running locally.

#Update repo
apt-get update

echo ">>> Installing LAMP"

#Generate mysql password
MYSQL_ROOT_PASSWORD='root'

#Set the password so you don't have to enter it during installation
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

#Tools
sudo apt-get install htop vim git -y

#Main install
sudo apt-get install mysql-server mysql-client apache2 php5 php5-cli libapache2-mod-php5 php5-mysql php5-curl php5-gd php-pear php5-imagick php5-mcrypt php5-memcache php5-mhash php5-sqlite php5-xmlrpc php5-xsl php5-json php5-dev libpcre3-dev make sed -y

sudo a2enmod rewrite
sudo service apache2 restart

echo ">>> Installing Redis"

# Add repository
sudo apt-add-repository ppa:rwky/redis -y

# Install Redis
# -qq implies -y --force-yes
sudo apt-get install -qq redis-server

# Redis Configuration
sudo mkdir -p /etc/redis/conf.d

# transaction journaling - config is written, only enabled if persistence is requested
cat << EOF | sudo tee /etc/redis/conf.d/journaling.conf
appendonly yes
appendfsync everysec
EOF

# Persistence
if [ ! -z "$1" ]; then
  if [ "$1" == "persistent" ]; then
    echo ">>> Enabling Redis Persistence"
    
    # add the config to the redis config includes
    if ! cat /etc/redis/redis.conf | grep -q "journaling.conf"; then
      sudo echo "include /etc/redis/conf.d/journaling.conf" >> /etc/redis/redis.conf
    fi
    
    # schedule background append rewriting
    if ! crontab -l | grep -q "redis-cli bgrewriteaof"; then
      line="*/5 * * * * /usr/bin/redis-cli bgrewriteaof > /dev/null 2>&1"
      (sudo crontab -l; echo "$line" ) | sudo crontab -
    fi
  fi # persistent
fi # arg check

sudo service redis-server restart


echo ">>> Installing Elasticsearch"

# Set some variables
ELASTICSEARCH_VERSION=1.4.2 # Check http://www.elasticsearch.org/download/ for latest version

# Install prerequisite: Java
# -qq implies -y --force-yes
sudo apt-get install -qq openjdk-7-jre-headless

wget --quiet https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ELASTICSEARCH_VERSION.deb
sudo dpkg -i elasticsearch-$ELASTICSEARCH_VERSION.deb
rm elasticsearch-$ELASTICSEARCH_VERSION.deb

# Configure Elasticsearch for development purposes (1 shard/no replicas, don't allow it to swap at all if it can run without swapping)
sudo sed -i "s/#index.number_of_shards: 1/index.number_of_shards: 1/" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/#index.number_of_replicas: 0/index.number_of_replicas: 0/" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/#bootstrap.mlockall: true/bootstrap.mlockall: true/" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/#cluster.name: elasticsearch/cluster.name: addons/" /etc/elasticsearch/elasticsearch.yml

sudo service elasticsearch restart

# Configure to start up Elasticsearch automatically
sudo update-rc.d elasticsearch defaults 95 10
