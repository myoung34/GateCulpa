#!/bin/bash -ex

export S3_REPO_SHORT="s3-repo-test"
export ENVIRONMENT="staging"
export VERSION="${CI_PIPELINE_ID:-0}.$((1 + RANDOM % 100)).$((1 + RANDOM % 100))-${CI_COMMIT_SHA:0:7}"


if [[ -z ${1} ]]; then
  echo "s3 repo not given"
  exit 1
fi

export S3_REPO="$1"

if [[ $2 == "prod" || $2 == "production" ]]; then
  export S3_REPO="s3-repo"
  export ENVIRONMENT="prod"
fi

[[ ! -d build ]] && mkdir build

helm init
helm plugin install https://github.com/hypnoglow/helm-s3.git
helm repo add ${S3_REPO_SHORT} "s3://${S3_REPO}/charts"

find policy -name '*.rego' ! -name '*_test.rego' ! -path 'policy/lib/*' -exec pk build {} \;
find policy -name '*.yaml' -exec mv {} policies/constraints/templates/ \;

#shellcheck disable=SC2044
for i in $(find policies -maxdepth 1 ! -path policies -type d); do
  pushd . >/dev/null 2>&1
  cd "${i}" || exit 1
  #shellcheck disable=SC2002
  name=$(cat Chart.yaml  | grep -E '^name:' | awk '{print $2}')
  #shellcheck disable=SC2002,SC2155
  export VERSION=$(cat Chart.yaml  | grep -E '^version:' | awk '{print $2}')

  if [[ "${ENVIRONMENT}" == "staging" ]]; then
    export VERSION="0.0.${CI_PIPELINE_ID:-0}-${CI_COMMIT_SHA:0:7}"
  fi

  #shellcheck disable=SC2002
  echo "Deploying ${name} version: ${VERSION}"
  helm package . --version "${VERSION}" -d ../../build
  popd >/dev/null 2>&1
  helm s3 push "build/${name}-${VERSION}.tgz" ${S3_REPO_SHORT}
done

helm s3 reindex ${S3_REPO_SHORT}
