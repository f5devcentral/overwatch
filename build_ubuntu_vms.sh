### Ubuntu - update
apt -y update
apt -y upgrade
apt -y install curl wget net-tools python3-pip ansible gnupg software-properties-common lsb-release apt-transport-https ca-certificates

### Additional software repos
# Terraform Repo
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt -y update && sudo apt -y install terraform

# kubectl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /"| sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt -y update && sudo apt -y install kubectl


# k9s
curl -fsSL https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb -o k9s_linux_amd64.deb && sudo dpkg -i ./k9s_linux_amd64.deb

# filebeat agent
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.15.3-amd64.deb && sudo dpkg -i filebeat-8.15.3-amd64.deb

# Install Docker using get-docker.sh:
curl -fsSL https://get.docker.com -o get-docker.sh &&
sudo sh ./get-docker.sh --dry-run &&
sudo sh ./get-docker.sh
sudo systemctl start docker
sudo systemctl enable docker

# AZ CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Unminimize the minimal ubuntu 22.04 LTS image
#sudo unminimize -y



















### The Grinder testing framework: https://github.com/cossme/grinder

apt -y install openjdk-11-jdk openjdk-8-jre unzip tar gzip wget curl
update-alternatives --config java
ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/local/java

cd /tmp
wget https://github.com/cossme/grinder/releases/download/4.0.0/grinder-4.0.0-binary.zip
cd /usr/local
unzip /tmp/grinder*.zip
cd grinder-4.0.0
touch etc/grinder.properties
chmod a+w etc/grinder.properties
mkdir bin

cat >> bin/setGrinderEnv.sh <<EOF
GRINDERPATH=`pwd`/..
GRINDERPROPERTIES=$GRINDERPATH/etc/grinder.properties
CLASSPATH=$GRINDERPATH/lib/grinder.jar:$CLASSPATH
JAVA_HOME=/usr/local/java
PATH=$JAVA_HOME/bin:$PATH
#echo "DEBUG: GRINDERPROPERTIES=$GRINDERPROPERTIES | JAVA_HOME=$JAVA_HOME "
export CLASSPATH PATH GRINDERPROPERTIES
EOF

cat >> bin/startAgent.sh <<EOF
#!/bin/bash
. ./setGrinderEnv.sh
java -classpath $CLASSPATH net.grinder.Grinder $GRINDERPROPERTIES
EOF

cat >> bin/startProxy.sh << EOF
#!/bin/bash
. ./setGrinderEnv.sh
java -classpath $CLASSPATH net.grinder.TCPProxy -console -http > grinder.py
EOF

cat >> bin/startConsole.sh <<EOF
#!/bin/bash
. ./setGrinderEnv.sh
java -classpath $CLASSPATH net.grinder.Console
EOF

chmod a+x bin/*.sh


Filebrowser.app
https://filebrowser.org/installation

docker run -d --rm --name filebrowser -v /usr/local/tmp:/srv -v /usr/local/filebrowser/filebrowser.db:/database.db -v /usr/local/filebrowser/.filebrowser.json:/.filebrowser.json --user $(id -u):$(id -g) -p 8080:80 filebrowser/filebrowser