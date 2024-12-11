### Ubuntu - update
sudo apt -y update
sudo apt -y upgrade
sudo apt -y install curl wget net-tools python3-pip ansible gnupg software-properties-common lsb-release apt-transport-https ca-certificates jq

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

# AZ CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

function dockerInstall () {
    # Install Docker using get-docker.sh:
    curl -fsSL https://get.docker.com -o get-docker.sh &&
    sudo sh ./get-docker.sh --dry-run &&
    sudo sh ./get-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker
}


function rsyslogConfig () {
    # rSyslogd Configuration for remote logging
    sudo cat <<-EOF >> /etc/rsyslog.d/50-default.conf
    *.*  action(type="omfwd" target="192.0.2.2" port="7514" protocol="tcp"
                action.resumeRetryCount="100"
                queue.type="linkedList" queue.size="10000")
    EOF
    sudo systemctl restart rsyslogd;
}
