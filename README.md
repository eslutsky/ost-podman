## about
this repo contains  source code for running ovirt-system-tests (libvirt) [0] in a privileged container

[0] https://github.com/oVirt/ovirt-system-tests.git

## building the container
- clone the ost code `git clone https://github.com/oVirt/ovirt-system-tests.git`
- chown to the image `chown -R 1000:1000 ovirt-system-tests`
- build the container `podman build . -t ost-podman`

## running ost inside the container
- run the  pre-build container as privileged (root)
    ```bash
    podman run --name ost --privileged -d --device /dev/kvm:/dev/kvm -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v $(pwd)/:/work ost-podman
    ```

- run the ost setup script inside container
    ```bash
    podman exec --user podman -ti 5b565bebb1c4 bash -c 'cd /work/ovirt-system-tests ; ./setup_for_ost.sh'
    ```

- run the basic-suite-master suite inside container 
    ```bash
    podman exec --user podman -ti 5b565bebb1c4 bash -c 'cd /work/ovirt-system-tests ; ./ost.sh run basic-suite-master el8stream'
    ```


