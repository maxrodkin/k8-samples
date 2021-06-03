# k8-samples
Hello there!  
It`s my attempt to run terraform+aws+rke+k8s+helm  
Based on:  
https://medium.com/@brotandgames/deploy-a-kubernetes-cluster-using-terraform-and-rke-provider-68112463e49d  
https://registry.terraform.io/providers/rancher/rke/latest/docs/resources/cluster  
https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/  
https://helm.sh/docs/using_helm/  

usefull commands:  
alias klr="kubectl --kubeconfig kube_config_cluster.yml"  
klr get no
klr proxy
klr -n kube-system describe secret $(klr -n kube-system get secret | grep admin-user | awk '{print $1}') | grep ^token: | awk '{ print $2 }'  
new URL because of new version of kubernetes-dashboard with some changes:  
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/  

before https://helm.sh/docs/using_helm/  create PV with:
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  capacity:
    storage: 8Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: "" #it`s important, lurk more at https://stackoverflow.com/questions/52668938/pod-has-unbound-persistentvolumeclaims
  local:
    path: /opt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ec2-35-160-98-95.us-west-2.compute.amazonaws.com
    

