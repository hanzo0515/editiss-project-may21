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
echo "Please enter the ip:"
read -r ip
scp /root/worker-kube.sh $ip:/root/
ssh root@$ip "./worker-kube.sh" > /root/worker-kube.sh
sleep 15s
echo "Adding Firewall Rules"
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload
sleep 3s
echo "Creating Token for worker node"
kubeadm init
sleep 5s
kubeadm token create --print-join-command | grep "^kubeadm" >> /root/join-token
sleep 5s
chmod u+x /root/join-token
sleep 10s
scp /root/join-token $ip:/root/
sleep 5s
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
ssh root@$ip "./join-token" > /root/join-token
sleep 180s
echo "####### Clustering is DONE!!!! ######"
kubectl get pods --all-namespaces
kubectl get nodes
sleep 5s
echo "####### Scanning and Hardening Start ######"
sh /root/zephyrus.sh


