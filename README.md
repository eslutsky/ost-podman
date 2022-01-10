## about
this repo contains  source code for running ovirt-system-tests (libvirt) [0] in a privileged container

[0] https://github.com/oVirt/ovirt-system-tests.git

## building the container
- clone the ost code `git clone -b ignore_selinux_firewall https://github.com/eslutsky/ovirt-system-tests.git` [0]
- chown to the image `chown -R 1000:1000 ovirt-system-tests`
- build the container `make build-ost`
[0] - this is a patched version for running in container

## running ost inside the container
- run the  pre-build container as privileged (root)  `make run-ost`

- run the ost setup script inside container `make setup-ost`

- run the suite inside container `make run-suite SUITE_NAME=tr-suite-master`

- run the go-ovirt-client tests inside OST container `make run-live-tests`

- run the entire flow `make run-all`
    this will build and run the OST container,setup OST,create the RHV environment,run tests

## Accessing the OST engine for debugging (2 hops)

```bash

# Access the container shell
make debug

## find out the ost container address
OST_CONTAINER_IP=`ip -4 -o addr show eth0  |  egrep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1`

#  from Container create ssh tunnel to the engine VM
sudo sshpass -p 123456 ssh -L ${OST_CONTAINER_IP}:443:192.168.200.2:443 root@192.168.200.2


## create ssh tunnnel to the Host running the Container
sudo ssh -L 443:${OST_CONTAINER_IP}:443 root@${OST_HOST}

```
- this will open 443 on localhost,allowing access to the engine on port 443


