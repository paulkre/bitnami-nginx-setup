#!/bin/bash

echo "> Setting up HTTPS"

read -p "> Enter the domain pointing to this instance (or q to abort): " DOMAIN
read -p "> Enter the email address to be used for Let's Encrypt registration (or q to abort): " EMAIL

echo "> Installing HTTPS client"
cd /tmp
curl -Ls https://api.github.com/repos/xenolf/lego/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4 | wget -i -
tar xf `ls | grep "lego_v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*_linux_amd[0-9]*\.tar\.gz"`
sudo mkdir -p /opt/bitnami/letsencrypt
sudo mv lego /opt/bitnami/letsencrypt/lego
rm `ls | grep lego`

echo "> Generating a Let’s Encrypt certificate for your domain"
sudo /opt/bitnami/ctlscript.sh stop
sudo /opt/bitnami/letsencrypt/lego --tls --email=""$EMAIL"" --domains=""$DOMAIN"" --path="/opt/bitnami/letsencrypt" run

echo "> Configuring NGINX to use the Let's Encrypt certificate"
sudo mv /opt/bitnami/nginx/conf/bitnami/certs/server.crt /opt/bitnami/nginx/conf/bitnami/certs/server.crt.old
sudo mv /opt/bitnami/nginx/conf/bitnami/certs/server.key /opt/bitnami/nginx/conf/bitnami/certs/server.key.old
sudo mv /opt/bitnami/nginx/conf/bitnami/certs/server.csr /opt/bitnami/nginx/conf/bitnami/certs/server.csr.old
sudo ln -sf /opt/bitnami/letsencrypt/certificates/$DOMAIN.key /opt/bitnami/nginx/conf/bitnami/certs/server.key
sudo ln -sf /opt/bitnami/letsencrypt/certificates/$DOMAIN.crt /opt/bitnami/nginx/conf/bitnami/certs/server.crt
sudo chown root:root /opt/bitnami/nginx/conf/bitnami/certs/server*
sudo chmod 600 /opt/bitnami/nginx/conf/bitnami/certs/server*

sudo /opt/bitnami/ctlscript.sh start

echo "> Registering CRON job to renew certificate periodically"

sudo mkdir -p /opt/bitnami/letsencrypt/scripts
sudo echo "#!/bin/bash

sudo /opt/bitnami/ctlscript.sh stop nginx
sudo /opt/bitnami/letsencrypt/lego --tls --email="$EMAIL" --domains="$DOMAIN" --path="/opt/bitnami/letsencrypt" renew --days 90
sudo /opt/bitnami/ctlscript.sh start nginx
" > /opt/bitnami/letsencrypt/scripts/renew-certificate.sh
sudo chmod +x /opt/bitnami/letsencrypt/scripts/renew-certificate.sh

(crontab -l 2>/dev/null; echo "0 0 1 * * /opt/bitnami/letsencrypt/scripts/renew-certificate.sh 2> /dev/null") | crontab -
