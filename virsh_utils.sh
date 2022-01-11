#!/bin/bash
function find_unused_port {
    while
        port=$(shuf -n 1 -i 49152-65535)
        netstat -atun | grep -q "$port"
    do
    continue
    done
    echo "$port"
}
function save_xml {
echo "saving VMs"
for vm in `virsh list | grep ost | awk '{print $2}'` ; do
    echo "saving VM ${vm}" 
    virsh dumpxml ${vm} >vm-${vm}.xml
done

echo "saving networks"
for network in `virsh net-list | egrep '^ ost.*' | awk '{print $1}'` ; do
    echo "saving Network ${network}"
    virsh net-dumpxml ${network} >net-${network}.xml
done
}

function restore_xml {
    for net in `ls net-*.xml` ; do
        virsh net-define ${net}
        virsh net-start "${net:4:-4}"
    done

    for vm in `ls vm-*.xml` ; do
        virsh define ${vm}
        virsh start "${vm:3:-4}"
    done


}

function add_engine_alternate_FQDN {
    hostname=$1
    port=$2
    sshpass -p 123456 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  root@192.168.202.2 <<EOF
echo >>/etc/ovirt-engine/engine.conf.d/99-custom-fqdn.conf
echo SSO_ALTERNATE_ENGINE_FQDNS\=\"$\{SSO_ALTERNATE_ENGINE_FQDNS\} ${hostname} ${hostname}:${port}\" >>/etc/ovirt-engine/engine.conf.d/99-custom-fqdn.conf
systemctl restart ovirt-engine
EOF
}

function find_podman_port {
    container_id=$(podman ps  | grep ost-podman | awk '{print $1}')
    echo $(podman inspect ${container_id} | jq -r ' .[] | .NetworkSettings.Ports."443/tcp" | .[0].HostPort')

}