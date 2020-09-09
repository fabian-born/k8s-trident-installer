# k8s Trident Installer
### Docker Image to setup NetApp Trident in a Kubernetes Cluster

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/fabianborn/k8s-trident-installer)


#### Now you can install the installer by using kubectl:
Before you start you have create a config map and in the yaml file the following setting has to been modified:
````yaml
      volumeMounts:
      - name: kconfig
        mountPath: "/config"
        subPath: <name of the origin kubeconfig file>
```

``` 
kubectl create configmap trident-install-kubeconfig --from-file=$KUBECONFIG

kubectl apply -f https://raw.githubusercontent.com/fabian-born/k8s-trident-installer/master/k8s-trident-installer.yaml
```

#### Simple docker image to deploy NetApp Trident to Kubernetes cluster

```docker run -v <path-to-kubeconfig>config:/config fabianborn/k8s-trident-installer:latest```


Here is a short example:
[![asciicast](https://asciinema.org/a/gKTMvKguMYOINNOtcNxSiZCKR.svg)](https://asciinema.org/a/gKTMvKguMYOINNOtcNxSiZCKR)
