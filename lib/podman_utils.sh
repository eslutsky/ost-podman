
function find_container_id {
    echo $(cat .container_id)
}

function find_unused_port {
    while
        port=$(shuf -n 1 -i 49152-65535)
        netstat -atun | grep -q "$port"
    do
    continue
    done
    echo "$port"
}

# wrapped for podman runner
function run_ost {
    image_name=$1
    ext_hostname=$(hostname -f)
    remote_port=$(find_unused_port)

    if [ -e .container_id ] ; then
        podman ps -a --no-trunc | grep -q $(cat .container_id)  && exit 2
    fi

    container=$(podman run --privileged --publish ${remote_port}:443 -d --device /dev/kvm:/dev/kvm --sysctl net.ipv6.conf.all.accept_ra=2 -v /sys/fs/cgroup:/sys/fs/cgroup:rw  ${image_name})
    echo ${container} > .container_id
	echo "OST Engine is available at https://${ext_hostname}:${remote_port}"
}

function exec_in_ost {
    user=$1
    command=$2
    #set -x
    container_id=$(find_container_id)
    podman cp lib/virsh_utils.sh ${container_id}:/work/
	podman exec -i --user ${user} ${container_id} bash <<EOF
source /work/virsh_utils.sh
echo "running remote command ${command} "
$command
EOF
}

function find_podman_port {
    echo $(podman inspect $(find_container_id) | jq -r ' .[] | .NetworkSettings.Ports."443/tcp" | .[0].HostPort')
}