#!/bin/bash -exu

export ROOT="${PWD}"
export STEMCELL_VERSION=$(cat "${ROOT}"/stemcell/version)
export RELEASE_VERSION="99999+dev.$(date +%s)"

function main() {
  upload_stemcell
  upload_release
  force_compilation
}

function force_compilation() {
  pushd /tmp > /dev/null
    sed \
      -e "s/REPLACE_ME_DIRECTOR_UUID/$(/opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" status --uuid)/g" \
      -e "s/REPLACE_ME_RELEASE_VERSION/${RELEASE_VERSION}/g" \
      -e "s/REPLACE_ME_RELEASE_NAME/${RELEASE_NAME}/g" \
      "${ROOT}/mega-ci/scripts/ci/compile-bosh-release/fixtures/compilation.yml" > "compilation.yml"
    /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" -d "/tmp/compilation.yml" -n deploy
  popd > /dev/null

  pushd "${ROOT}/compiled-bosh-release" > /dev/null
    /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" -d "/tmp/compilation.yml" export release "${RELEASE_NAME}/${RELEASE_VERSION}" "ubuntu-trusty/${STEMCELL_VERSION}"
  popd > /dev/null

  /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" -n delete deployment compilation
}

function upload_stemcell() {
  pushd "${ROOT}/stemcell" > /dev/null
    /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" upload stemcell stemcell.tgz --skip-if-exists
  popd > /dev/null
}

function upload_release() {
  pushd "${ROOT}/release-repo" > /dev/null
    /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" -n create release --name "${RELEASE_NAME}" --force --version "${RELEASE_VERSION}"
    /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" upload release
  popd > /dev/null
}

function cleanup_releases() {
  /opt/rubies/ruby-2.2.4/bin/bosh -t "${BOSH_DIRECTOR}" -n cleanup
}

function rollup() {
  set +x
  local input
  input="${1}"

  local output

  IFS=$'\n'
  for line in ${input}; do
    output="${output:-""}\n${line}"
  done

  printf "%s" "${output#'\n'}"
  set -x
}

trap cleanup_releases EXIT
main
