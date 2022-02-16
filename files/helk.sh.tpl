#!/bin/sh

echo "Download velociraptor!" >> /tmp/helk.log
curl -L 'https://github.com/iknowjason/BlueTools/blob/main/velociraptor-v0.5.6-linux-amd64.gz?raw=true' -o /home/helk/velociraptor.gz

echo "gzip velociraptor" >> /tmp/helk.log
cd /home/helk
gzip -d velociraptor.gz

echo "chmod +x velociraptor" >> /tmp/helk.log
chmod +x velociraptor

echo "copy velociraptor to /usr/sbin" >> /tmp/helk.log
cp velociraptor /usr/sbin/.

echo "config generate" >> /tmp/helk.log
velociraptor config generate > /home/helk/config.yaml

echo "Change client URL in config" >> /tmp/helk.log
sed -i 's/localhost:8000/${helk_ip}:8000/g' /home/helk/config.yaml

echo "Change server bind in config" >> /tmp/helk.log
sed -i 's/bind_address: 127.0.0.1/bind_address: ${helk_ip}/g' /home/helk/config.yaml

echo "Add helk administrator in config" >> /tmp/helk.log
velociraptor --config /home/helk/config.yaml user add helk helk --role administrator

echo "Add self-signed certificate parameter in config" >> /tmp/helk.log
sed -i 's/pinned_server_name: VelociraptorServer/use_self_signed_ssl: true\n  pinned_server_name: VelociraptorServer/' /home/helk/config.yaml

echo "Build velociraptor deb package" >> /tmp/helk.log
velociraptor --config /home/helk/config.yaml debian server

echo "Install deb package and service" >> /tmp/helk.log
dpkg -i /home/helk/velociraptor_0.5.6_server.deb

echo "Git clone HELK" >> /tmp/helk.log
cd /usr/src
git clone https://github.com/iknowjason/HELK.git

echo "Installing HELK" >> /tmp/helk.log
cd /usr/src/HELK/docker
./helk_install.sh

echo "Finished bootstrap script" >> /tmp/helk.log
