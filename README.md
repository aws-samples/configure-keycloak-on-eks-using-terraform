<<<<<<< HEAD
## My Project

TODO: Fill this README out!

Be sure to:

* Change the title in this README
* Edit your repository description on GitHub

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

=======
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

### To depoloy Keycloak to EKS
Run command
```shell
make deploy-keycloak
```

### To delete all resource with Terraform
Run command
```shell
make destroy
```
>>>>>>> 09d6e5f (Initial commit.)
