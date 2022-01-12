#!/bin/bash
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

function wait_VM_to_be_up {
    address=$1
while [ -z "$( socat -T2 stdout tcp:${address}:22,connect-timeout=2,readbytes=1 2>/dev/null )" ]
do
    echo "."
    sleep 1
done

}



function add_engine_alternate_FQDN {
    hostname=$1
    port=$2
    dnf install socat -y
    wait_VM_to_be_up "192.168.202.2"
    sshpass -p 123456 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  root@192.168.202.2 <<EOF
set -x
echo >>/etc/ovirt-engine/engine.conf.d/99-custom-fqdn.conf
echo SSO_ALTERNATE_ENGINE_FQDNS\=\"$\{SSO_ALTERNATE_ENGINE_FQDNS\} ${hostname} ${hostname}:${port}\" >>/etc/ovirt-engine/engine.conf.d/99-custom-fqdn.conf
systemctl restart ovirt-engine
EOF
}
