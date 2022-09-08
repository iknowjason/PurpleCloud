#!/bin/sh

echo "Download velociraptor configuration yaml file!" >> /tmp/helk.log
curl -L "https://${storage_acct}.blob.core.windows.net/${storage_container}/${vserver_config}" -o /home/helk/server.config.yaml

echo "Download velociraptor linux binary!" >> /tmp/helk.log
curl -L "https://${storage_acct}.blob.core.windows.net/${storage_container}/${linux_binary}" -o /home/helk/velociraptor.gz

echo "gzip velociraptor" >> /tmp/helk.log
cd /home/helk
gzip -d velociraptor.gz

echo "chmod +x velociraptor" >> /tmp/helk.log
chmod +x velociraptor

echo "copy velociraptor to /usr/sbin" >> /tmp/helk.log
cp velociraptor /usr/sbin/.

echo "Build velociraptor deb package" >> /tmp/helk.log
velociraptor --config /home/helk/server.config.yaml debian server

echo "Install deb package and service" >> /tmp/helk.log
dpkg -i /home/helk/*.deb

echo "Add velociraptor administrator in config" >> /tmp/helk.log
sudo -u velociraptor bash -c 'velociraptor --config /home/helk/server.config.yaml user add ${vadmin_username} ${vadmin_password} --role administrator'

echo "Git clone HELK" >> /tmp/helk.log
cd /usr/src
git clone https://github.com/iknowjason/HELK.git

# Backup the install file
cd /usr/src/HELK/docker;cp helk_install.sh helk_install.sh.bak

# Set the helk username
sed -i 's/htpasswd.users "helk"/htpasswd.users "${vadmin_username}"/g' helk_install.sh

# Set the helk password
sed -i 's/KIBANA_UI_PASSWORD_INPUT="hunting"/KIBANA_UI_PASSWORD_INPUT="${vadmin_password}"/g' helk_install.sh

echo "Installing HELK" >> /tmp/helk.log
cd /usr/src/HELK/docker
./helk_install.sh

echo "Finished bootstrap script" >> /tmp/helk.log
