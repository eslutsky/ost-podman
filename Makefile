SUITE_NAME=tr-suite-master
OS=el8stream
FQDN=`hostname -f`
CONTAINER_ID=`source ${CURDIR}/lib/podman_utils.sh;find_container_id`
HIGH_PORT=`source ${CURDIR}/lib/podman_utils.sh;find_unused_port`
EXTERNAL_PORT=`source ${CURDIR}/lib/podman_utils.sh; find_podman_port`

run-all: build-ost run-ost setup-ost run-suite run-live-tests

build-ost:
	podman build --squash -f Dockerfile -t ost-podman

print-engine-fqdn:
	echo "OST Engine is available at https://${FQDN}:${EXTERNAL_PORT}"

run-ost:
	source ${CURDIR}/lib/podman_utils.sh; run_ost "ost-podman:latest"

run-ost-full:
	source ${CURDIR}/lib/podman_utils.sh; run_ost "ost-podman:full"

run-ost-engine-ui: run-ost-full restore-vm-xmls engine-configure-fqdn start-engine-socket print-engine-fqdn

setup-ost:
#	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'cd /work/ovirt-system-tests ; ./setup_for_ost.sh -y'
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "podman" "cd /work/ovirt-system-tests ; ./setup_for_ost.sh -y"

run-suite:
#	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'cd /work/ovirt-system-tests ; ./ost.sh run $(SUITE_NAME) $(OS)'
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "podman" "cd /work/ovirt-system-tests ; ./ost.sh run $(SUITE_NAME) $(OS)"

run-mock-tests:
	podman cp lib/test-go-ovirt.sh $(CONTAINER_ID):/work/
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "podman" "sh /work/test-go-ovirt.sh"

run-live-tests:
	podman cp lib/test-go-ovirt.sh $(CONTAINER_ID):/work/
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "podman" "sh /work/test-go-ovirt.sh live"

save-vm-xmls:
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "root" "save_xml"

restore-vm-xmls:
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "root" "restore_xml"

start-engine-socket:
	podman cp lib/ovirt-engine-socat.service $(CONTAINER_ID):/usr/lib/systemd/system/ovirt-engine-socat.service
	podman exec -ti --user root $(CONTAINER_ID) bash -c 'systemctl enable ovirt-engine-socat;systemctl start ovirt-engine-socat'

engine-configure-fqdn:
	source ${CURDIR}/lib/podman_utils.sh ; exec_in_ost "root" "add_engine_alternate_FQDN $(FQDN) $(EXTERNAL_PORT)"



#create image from an existing container
commit-ost:
	podman commit $(CONTAINER_ID) ost-podman:full

ssh-engine:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sshpass -p 123456 ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.202.2'

engine-tail-log:
	podman exec -ti --user podman $(CONTAINER_ID) bash -c 'sshpass -p 123456 ssh root@192.168.202.2 tail -f /var/log/ovirt-engine/engine.log'

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
	
