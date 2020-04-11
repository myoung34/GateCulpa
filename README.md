# GateCulpa
Gatekeeper (opa for k8s) policies

## Known Issues ##

  1. GateKeeper supports libraries, but the functionality isnt quite sync'd across conftest and gatekeeper in a stable branch. "Common" code is currently duplicated instead of putting it into `policy/lib/{name}.rego` and doing `import data.lib.common`
  1. ~There is currently no "notify only" or "warning" behavior in GateKeeper. Im not a fan of preventing containers from running from the get-go, so currently the rules are set to 'dry-run' and run [sync.yaml](https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/demo/basic/sync.yaml) to get the following output. To get notified youll need to set up logging alerts or crawl your violations on a cron. See [this issue](https://github.com/open-policy-agent/gatekeeper/issues/382) to follow along with the future behavior~ No longer true from [this](https://github.com/open-policy-agent/gatekeeper/blob/46eeb19c454e212eeabcaf0b67395875eb4354f1/pkg/webhook/policy.go#L176)

```
$ aws-vault exec home -- kubectl get k8s-disallow-mount-socket k8s-disallow-mount-socket -oyaml
..snip...
status:
  auditTimestamp: "2020-01-09T19:34:09Z"
  byPod:
  - enforced: true
    id: gatekeeper-controller-manager-77ff8cc995-q5t7g
  totalViolations: 1
  violations:
  - enforcementAction: dryrun
    kind: Pod
    message: The Pod intended-angelfish-cloudcustodian-chart-d9f55bb66-wbdp6 is mounting
      the Docker socket
    name: intended-angelfish-cloudcustodian-chart-d9f55bb66-wbdp6
    namespace: default
```

## Testing And Linting GateKeeper Policies ##


```
$ find . -name '*.yaml' -type f -not -path "./policies/constraints/templates*"  -exec yamllint {} \;
$ find policies -maxdepth 1 ! -path policies -type d -exec helm lint {} \;
$ conftest verify
PASS - policy/policy/k8s-disallow-mount-socket_test.rego - data.k8sdisallowmountsocket.test_socket_mount
```

## Packaging GateKeeper Policies as Helm Charts ##

### Packages ###

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

## CI ##

An example of how we do this in CI to push to s3 can be found in [deploy.sh](/deploy.sh)

```
$ bash deploy.sh my-helm-bucket
Creating /root/.helm
Creating /root/.helm/repository
Creating /root/.helm/repository/cache
Creating /root/.helm/repository/local
Creating /root/.helm/plugins
Creating /root/.helm/starters
Creating /root/.helm/cache/archive
Creating /root/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /root/.helm.
Error: error installing: Post http://localhost:8080/apis/apps/v1/namespaces/kube-system/deployments: dial tcp 127.0.0.1:8080: connect: connection refused
Downloading and installing helm-s3 v0.9.0 ...
Checksum is valid.
Installed plugin: s3
"s3-repo-test" has been added to your repositories
[k8s-disallow-mount-socket] Generating a ConstraintTemplate from "policy/k8s-disallow-mount-socket.rego"
[k8s-disallow-mount-socket] Saving to "policy/k8s-disallow-mount-socket.yaml"
Deploying constraints version: 0.0.0-a88b543
Successfully packaged chart and saved it to: ../../build/constraints-0.0.0-a88b543.tgz
Deploying rules version: 0.0.0-a88b543
Successfully packaged chart and saved it to: ../../build/rules-0.0.0-a88b543.tgz
Repository s3-repo was successfully reindexed.
```
