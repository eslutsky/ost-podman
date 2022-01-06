CONTAINER_ID=`podman ps -a | grep ost-podman | awk '{print $$1}'`
SUITE_NAME=tr-suite-master
OS=el8stream

build-ost:
	podman build --squash -f Dockerfile -t ost-podman

run-all: setup-ost run-suite 

run-ost:
	podman run --name ost --privileged -d --device /dev/kvm:/dev/kvm --sysctl net.ipv6.conf.all.accept_ra=2 -v /sys/fs/cgroup:/sys/fs/cgroup:rw  ost-podman

setup-ost:
	echo $(CONTAINER_ID)
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'cd /work/ovirt-system-tests ; ./setup_for_ost.sh -y'

run-suite:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'cd /work/ovirt-system-tests ; ./ost.sh run $(SUITE_NAME) $(OS)'

run-mock-tests:
	podman cp test-go-ovirt.sh $(CONTAINER_ID):/work/
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sh /work/test-go-ovirt.sh'

run-live-tests:
	podman cp test-go-ovirt.sh $(CONTAINER_ID):/work/
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sh /work/test-go-ovirt.sh live'

destroy-suite:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c "cd /work/ovirt-system-tests ; ./ost.sh destroy $(SUITE_NAME) $(OS)"

cleanup:
	podman stop $(CONTAINER_ID)
	podman rm $(CONTAINER_ID)

debug:
	podman exec -ti --user podman $(CONTAINER_ID) /bin/bash
	