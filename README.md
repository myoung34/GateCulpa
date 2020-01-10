# GateCulpa
Gatekeeper (opa for k8s) policies

### Testing And Linting GateKeeper Policies ###


```
$ find . -name '*.yaml' -type f -not -path "./policies/constraints/templates*"  -exec yamllint {} \;
$ find policies -maxdepth 1 ! -path policies -type d -exec helm lint {} \;
$ conftest verify
PASS - policy/policy/k8s-disallow-mount-socket_test.rego - data.k8sdisallowmountsocket.test_socket_mount
```

### Packaging GateKeeper Policies as Helm Charts ###

## Packages ##

There are 2 packages:

  1. Constraints -> The ConstraintTemplates
  2. Rules       -> The rules (depend on Constraints existing before they can be applied)

```
$ pip install policykit # https://github.com/garethr/policykit
$ mkdir build
$ # find all the gatekeeper rego policies (that arent tests or libs) and run policykit to build them
$ find policy -name '*.rego' ! -name '*_test.rego' ! -path 'policy/lib/*' -exec pk build {} \;
$ # find all the pk generated yaml ConstraintTemplates and move them into the constraints helm templates dir
$ find policy -name '*.yaml' -exec mv {} policies/constraints/templates/ \;
$ helm package policies/constraints -d ./build
$ helm package policies/rules -d ./build
$ ls -alh build
total 16K
drwxr-xr-x 2 myoung myoung 4.0K Jan 10 07:39 .
drwxr-xr-x 7 myoung myoung 4.0K Jan 10 07:39 ..
-rw-r--r-- 1 myoung myoung  932 Jan 10 07:39 constraints-0.1.1.tgz
-rw-r--r-- 1 myoung myoung  491 Jan 10 07:39 rules-0.1.1.tgz
```

### CI ###

An example of how we do this in CI to push to s3 can be found in [deploy.sh](/deploy.sh)
