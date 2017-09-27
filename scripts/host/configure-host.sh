#!/bin/bash
################################################################################
# Configure host to launch OpenShift cluster                                   #
################################################################################

sudo su

# Optional part - mounting 120 GB drive as /var/origin

mkdir /var/origin

parted -s -a optimal /dev/sdc mklabel gpt -- mkpart primary xfs 1 -1

/sbin/mkfs -t xfs -f /dev/sdc1

sudo echo "/dev/sdc1  /var/origin  xfs  defaults 0 0" >> /etc/fstab

mount /dev/sdc1

# Installing pre-requisite software

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

yum -y update

yum -y install docker-1.12.6

systemctl enable docker

systemctl start docker

sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry 172.30.0.0/16"' \
/etc/sysconfig/docker

systemctl stop docker

systemctl start docker

# Download & configure

cd /var/origin

wget https://github.com/openshift/origin/releases/download/v3.6.0/openshift-origin-server-v3.6.0-c4dd4cf-linux-64bit.tar.gz

tar -x -f openshift-origin-server-v3.6.0-c4dd4cf-linux-64bit.tar.gz

rm *.tar.gz

mv openshift-origin-server-v3.6.0-c4dd4cf-linux-64bit bin

export PATH=$(pwd):$PATH

cd /var/origin/

mkdir data

cp /var/origin/bin/oc /usr/bin

cp /var/origin/bin/oadm /usr/bin
 


