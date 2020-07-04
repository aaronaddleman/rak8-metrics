# rak8-metrics

Deployment of Prometheus on raspberry pi k8 cluster

## building

Run 

```
bash make.sh
```

## dashboard

1. apply service account

```
kubectl apply -f admin-service-account.yaml
```

then to use the account...

1. get service token
1. start proxy
1. point browser

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin | awk '{print $1}')
kubectl proxy
# goto url
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
# enter in the token from the first step
```

## sending data

### statsd

get a list of pods

```
kubectl get pods -n monitoring
```

start port forwarding

```
kubectl port-forward -n monitoring pod/statsd-exporter-7d8fc9bcc-dfjqr 9125:9125
```

send metrics to port

```
echo "deploys.test.myservice:1|c" | socat -t 0 STDIN TCP:localhost:9125
```

view metrics

```
kubectl port-forward -n monitoring pod/statsd-exporter-7d8fc9bcc-dfjqr 9102:9102
```

point browser to localhost

```
http://localhost:9102/metrics
```

## services

### grafana

1. get the pod name for grafana
1. start port forward
1. point browser

```
kubectl get pods -n monitoring
kubectl port-forward -n monitoring pod/grafana-5f8959599b-hntrt 3000:3000
http://localhost:3000
```
