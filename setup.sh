echo "> Starting setup process"

echo "> Installing Node.js"
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs
sudo apt-get install gcc g++ make

echo "> Installing yarn"
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

echo "> Installing PM2"
sudo yarn global add pm2

# Register pm2 as systemd unit
pm2 startup

# Add pm2 commands to PATH variable
sudo env PATH=$PATH:/usr/bin /usr/local/share/.config/yarn/global/node_modules/pm2/bin/pm2 startup systemd -u bitnami --hp /home/bitnami

echo "> Connecting NGINX to PM2"
echo 'location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
}' > /opt/bitnami/nginx/conf/bitnami/app.conf
sudo /opt/bitnami/ctlscript.sh restart nginx

echo "> Generating SSH key pair"
cat /dev/zero | ssh-keygen -q -N ""

read -p "> Do you want to set up HTTPS via Let's Encrypt? (y/n) " HTTPS_SETUP
# Using this approach: https://docs.bitnami.com/aws/how-to/generate-install-lets-encrypt-ssl/#alternative-approach
if [ $HTTPS_SETUP =~ ^[yY]$ ]
then
  source setup-https.sh
fi

echo "> The server has to restart to finish the setup. Do you want to reboot the server now? (y/n)"
read REBOOT_SERVER
if [ $REBOOT_SERVER =~ ^[yY]$ ]
then
  sudo reboot
fi