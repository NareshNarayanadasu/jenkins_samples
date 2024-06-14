#!/bin/bash

# Update system and install Java
yum update -y
yum install java-1.8.0-openjdk.x86_64 wget -y

# Create directories for Nexus
mkdir -p /opt/nexus/
mkdir -p /tmp/nexus/

# Download and extract Nexus
cd /tmp/nexus/
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"
wget $NEXUSURL -O nexus.tar.gz
sleep 10
EXTOUT=$(tar xzvf nexus.tar.gz)
NEXUSDIR=$(echo $EXTOUT | head -n 1 | cut -d '/' -f 1)
sleep 5
rm -rf /tmp/nexus/nexus.tar.gz

# Move Nexus files to /opt
cp -r /tmp/nexus/* /opt/nexus/
sleep 5

# Delete existing nexus user if it exists
if id "nexus" &>/dev/null; then
    userdel -r nexus
    echo "Existing user 'nexus' deleted"
fi

# Create a new user for Nexus
useradd -r -m -d /opt/nexus -s /bin/bash nexus
echo "User 'nexus' created"

# Change ownership of Nexus directories
chown -R nexus:nexus /opt/nexus

# Create a systemd service file for Nexus
cat <<EOT > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Configure Nexus to run as nexus user
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Reload systemd configuration and start Nexus service
systemctl daemon-reload
systemctl start nexus
systemctl enable nexus

# Output initial admin password for user reference
ADMIN_PASSWORD=sdmin12
echo "Nexus Repository Manager has been installed and started." > /opt/nexus_installation_info.txt
echo "Access Nexus at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8081" >> /opt/nexus_installation_info.txt
echo "The default admin password is: $ADMIN_PASSWORD" >> /opt/nexus_installation_info.txt
    