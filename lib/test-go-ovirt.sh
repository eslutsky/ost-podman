#!/usr/bin/bash

is_live=$1

cd /work/
mkdir -p tests/
cd tests/
cat <<__EOF__ >Dockerfile
FROM docker.io/library/golang:latest as BUILD
WORKDIR builddir
COPY . .
RUN cd go-ovirt-client/ ; go get -u -v -f all
__EOF__

if [[ -n "$is_live" ]]; then
cat <<__EOF__ >env.sh
export OVIRT_URL=https://192.168.202.2/ovirt-engine/api
export OVIRT_USERNAME=admin@internal
export OVIRT_PASSWORD=123456
export OVIRT_INSECURE=true
__EOF__
else
> env.sh
fi

git clone https://github.com/oVirt/go-ovirt-client.git
podman build . -t ovirt-client
podman run --rm -w /go/builddir/go-ovirt-client -ti ovirt-client bash -c 'source ../env.sh ; go test --json  ./... '

