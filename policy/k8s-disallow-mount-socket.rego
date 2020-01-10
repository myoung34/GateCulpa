package k8sdisallowmountsocket

default is_gatekeeper = false

is_gatekeeper {
        has_field(input, "review")
        has_field(input.review, "object")
}

object = input {
        not is_gatekeeper
}

object = input.review.object {
        is_gatekeeper
}

has_field(obj, field) {
        obj[field]
}
name = object.metadata.name
kind = object.kind

is_pod {
  kind = "Pod"
}

pods[pod] {
  is_pod
  pod = object
}

volumes[volume] {
  pods[pod]
  volume = pod.spec.volumes[_]
}


# run these with dry run enabled.
# there is no 'warning' yet in gatekeeper, and we dont want to break everything
# https://github.com/open-policy-agent/gatekeeper/issues/382
violation[{
  "msg": msg,
  "code": "DockerMountException"
}] {
  volumes[volume]
  volume.hostPath.path = "/var/run/docker.sock"
  msg = sprintf("The %s %s is mounting the Docker socket", [kind, name])
}
