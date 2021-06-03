#!/bin/bash -v
#get public DNS name
cd $1
export HOST_DNS_NAME=$(dig +short myip.opendns.com @resolver1.opendns.com|nslookup|awk 'NR==1{print $4}'|sed 's/.$//')
export HOST_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo $HOST_DNS_NAME
echo $HOST_IP

rm -f *.pem *.srl
####TLS#######################################################################
#generate CA private and public keys
PASSWD=1234
openssl genrsa -passout pass:$PASSWD -aes256 -out ca-key.pem 4096
openssl req -passin pass:$PASSWD -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem \
-subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$HOST_DNS_NAME"

#create a server key and certificate signing request (CSR). Make sure that “Common Name” matches the hostname you use to connect to Docker
openssl genrsa -passout pass:$PASSWD -out server-key.pem 4096
openssl req -passin pass:$PASSWD -subj "/CN=$HOST_DNS_NAME" -sha256 -new -key server-key.pem -out server.csr

#Since TLS connections can be made through IP address as well as DNS name, the IP addresses need to be specified
echo subjectAltName = DNS:$HOST_DNS_NAME,IP:$HOST_IP,IP:127.0.0.1 >> extfile.cnf
#Set the Docker daemon key’s extended usage attributes to be used only for server authentication:
echo extendedKeyUsage = serverAuth >> extfile.cnf

#generate the signed certificate:
openssl x509 -passin pass:$PASSWD -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem   -CAcreateserial -out server-cert.pem -extfile extfile.cnf

#For client authentication, create a client key and certificate signing request
openssl genrsa -passout pass:$PASSWD -out key.pem 4096
openssl req -passin pass:$PASSWD -subj '/CN=client' -new -key key.pem -out client.csr

#To make the key suitable for client authentication, create a new extensions config file
echo extendedKeyUsage = clientAuth > extfile-client.cnf

#generate the signed certificate
openssl x509 -passin pass:$PASSWD -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem   -CAcreateserial -out cert.pem -extfile extfile-client.cnf
#you can safely remove the two certificate signing requests and extensions config files
rm -v client.csr server.csr extfile.cnf extfile-client.cnf
#To protect your keys from accidental damage, remove their write permissions
chmod -v 0400 ca-key.pem  server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem key.pem
####TLS#######################################################################
#Now you can make the Docker daemon only accept connections from clients providing a certificate trusted by your CA
sudo service docker stop
#sudo dockerd --tlsverify --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem   -H=0.0.0.0:2376

##учесть  [ Directory '/etc/sysconfig' does not exist ]
sudo sed -i 's/OPTIONS/#OPTIONS/g' /etc/sysconfig/docker
OPTIONS="\"--default-ulimit nofile=1024:4096 --tlsverify --tlscacert=$PWD/ca.pem --tlscert=$PWD/server-cert.pem --tlskey=$PWD/server-key.pem -H=0.0.0.0:2376\""
echo "OPTIONS=$OPTIONS" |sudo tee -a /etc/sysconfig/docker
sudo systemctl start docker
systemctl status docker.service
#journalctl -u docker
sudo docker ps
