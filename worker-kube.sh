echo "#### Common Installation script ######"
echo "##### Execute on Manager and worker nodes also ####"
sleep 5 
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
###Enable br_netfilter kernel module
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-ip6tables
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
touch /etc/sysctl.d/k8s.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.d/k8s.conf
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.d/k8s.conf
###Disable Swap 
swapoff -a
###remove swap entry from /etc/fstab
sed -i '/swap/d' /etc/fstab
###Install Docker
yum install -y yum-utils device-mapper-persistent-data lvm2
yum install docker -y
	
###Add kubernetes repository
cd /etc/yum.repos.d
touch kubernetes.repo 
echo '[kubernetes]' > kubernetes.repo
echo 'name=Kubernetes' >> kubernetes.repo
echo 'baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64' >> kubernetes.repo
echo 'enabled=1' >> kubernetes.repo
echo 'gpgcheck=1' >> kubernetes.repo
echo 'repo_gpgcheck=1' >> kubernetes.repo
echo 'gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' >> kubernetes.repo
yum install -y kubelet kubeadm kubectl
##Start and enable docker service
systemctl start docker
systemctl enable docker
##start and enable kubelet service
systemctl start kubelet
systemctl enable kubelet
echo "#######Installation completed successfully #####"
