package k8sdisallowmountsocket

test_socket_mount {
  violation[v] with input.review.object as {
    "kind": "Pod",
    "metadata": {
      "name": "foo"
    },
    "spec": {
      "foo": "wut",
      "volumes": [
        {"hostPath": {"path": "/var/run/docker.sock"}},
      ]
    }
  }
  v.msg == "The Pod foo is mounting the Docker socket"
  v.code == "DockerMountException"
}
