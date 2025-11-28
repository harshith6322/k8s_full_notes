kubectl version
kubectl get nodes
kubectl get node
kubectl get no

#pod file with labels 
---
apiVersion: v1
kind: Pod
metadata:
    name: pod-5
    labels:
        env: test
        app: swiggy
        client: infosys
spec:
    containers:
        - name: cont-1
            image: shaikmustafa/dm
            ports:
                - containerPort: 80

kubectl create -f pod.yml 
kubectl get po --show-labels
kubectl label pod mypod "env=test"
kubectl label pod pod1 pod2 pod3 app=nginx
kubectl label pod mypod-{1..3} app=nginx
kubectl label pods --all app=nginx
kubectl label pod mypod course=devops cloud=aws
kubectl get po -l app=swiggy
kubectl get po -l app-
kubectl get po -l env=test
kubectl get po -l env!=test
kubectl get po -l 'env in (dev,test)'
kubectl get po -l 'env notin (dev,test)'



#pod file with nodeSelector 
---
apiVersion: v1
kind: Pod
metadata:
    name: pod-5
    labels:
        env: test
        app: swiggy
        client: infosys
spec:
    nodeSelector:
        node: node1
    containers:
        - name: cont-1
            image: shaikmustafa/dm
            ports:
                - containerPort: 80

kubectl get no
kubectl label node i-0fa30252d69538098 node=node2
kubectl get no --show-labels
kubectl get no --show-labels | grep -i "node=node2"
