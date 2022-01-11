CONTAINER_ID=`podman ps  | grep ost-podman | awk '{print $$1}'`
SUITE_NAME=tr-suite-master
HIGH_PORT=`source ${CURDIR}/virsh_utils.sh;find_unused_port`
OS=el8stream
FQDN=`hostname -f`
EXTERNAL_PORT=`source ${CURDIR}/virsh_utils.sh; find_podman_port`

run-all: build-ost run-ost setup-ost run-suite run-live-tests

build-ost:
	podman build --squash -f Dockerfile -t ost-podman

print-engine-fqdn:
	echo "OST Engine is available at https://${FQDN}:${EXTERNAL_PORT}"

run-ost:
	podman run --name ost-2 --privileged --publish ${HIGH_PORT}:443 -d --device /dev/kvm:/dev/kvm --sysctl net.ipv6.conf.all.accept_ra=2 -v /sys/fs/cgroup:/sys/fs/cgroup:rw  ost-podman:full
	echo "OST Engine is available at https://${FQDN}:${EXTERNAL_PORT}"

setup-ost:
	echo $(CONTAINER_ID)
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'cd /work/ovirt-system-tests ; ./setup_for_ost.sh -y'

run-suite:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'cd /work/ovirt-system-tests ; ./ost.sh run $(SUITE_NAME) $(OS)'

run-mock-tests:
	podman cp test-go-ovirt.sh $(CONTAINER_ID):/work/
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sh /work/test-go-ovirt.sh'

save-vm-xmls:
	podman cp virsh_utils.sh $(CONTAINER_ID):/work/
	podman exec -ti --user root $(CONTAINER_ID) bash -c 'source /work/virsh_utils.sh; save_xml'

restore-vm-xmls:
	podman cp virsh_utils.sh $(CONTAINER_ID):/work/
	podman exec -ti --user root $(CONTAINER_ID) bash -c 'source /work/virsh_utils.sh; restore_xml'

run-live-tests:
	podman cp test-go-ovirt.sh $(CONTAINER_ID):/work/
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sh /work/test-go-ovirt.sh live'

start-engine-socket:
	podman cp ovirt-engine-socat.service $(CONTAINER_ID):/usr/lib/systemd/system/ovirt-engine-socat.service
	podman exec -ti --user root $(CONTAINER_ID) bash -c 'systemctl enable ovirt-engine-socat;systemctl start ovirt-engine-socat'

#create image from an existing container
commit-ost:
	podman commit $(CONTAINER_ID) ost-podman:full

ssh-engine:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sshpass -p 123456 ssh root@192.168.202.2'

engine-tail-log:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sshpass -p 123456 ssh root@192.168.202.2 tail -f /var/log/ovirt-engine/engine.log'

engine-configure-fqdn:
	podman cp virsh_utils.sh $(CONTAINER_ID):/work/
	podman exec -ti --user podman $(CONTAINER_ID) bash -c "source /work/virsh_utils.sh; add_engine_alternate_FQDN $(FQDN) $(EXTERNAL_PORT)"


destroy-suite:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c "cd /work/ovirt-system-tests ; ./ost.sh destroy $(SUITE_NAME) $(OS)"

restart: 
	podman stop $(CONTAINER_ID)
	podman start  $(CONTAINER_ID)

cleanup:
	podman stop $(CONTAINER_ID)
	podman rm $(CONTAINER_ID)

debug:
	podman exec -ti --user podman $(CONTAINER_ID) /bin/bash
	
