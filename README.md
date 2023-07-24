# configure-keycloak-on-eks-using-terraform
This repository contains Terraform code to provision AWS infrastructure deploy Keycloak to Elastic Kubernetes Service (EKS). 

### To setup and preview resources with Terraform
Run Command
```shell
make plan
```

### To deploy the AWS Services with Terraform
Run command
```shell
make apply

```
### To update kube-config
Run command
```shell
make update-kube-config
```

### To deploy Keycloak to EKS
Run command
```shell
make deploy-keycloak
```

### To delete all resource with Terraform
Run command
```shell
make destroy
```