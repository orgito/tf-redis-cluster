#!/bin/bash -x

exec > >(tee "/var/log/cloud.log") 2>&1

# Exit if already executed
if [ -f ~/.terraform_provisioned ]; then exit; fi

create_cluster() {
    yum -y install nmap
    while
        sleep 1
        MASTERS=$(aws ec2 describe-instances --filters 'Name=instance.group-name,Values=${prefix},Name=instance-state-name,Values=running,Name=tag:Role,Values=redis_master' --query 'Reservations[*].Instances[*].NetworkInterfaces[0].PrivateIpAddress' --output text)
        COUNT=$(echo $MASTERS | wc -w)
        (( $COUNT < ${cluster_size} ))
    do
        continue
    done

    while
        sleep 1
        SLAVES=$(aws ec2 describe-instances --filters 'Name=instance.group-name,Values=${prefix},Name=instance-state-name,Values=running,Name=tag:Role,Values=redis_slave' --query 'Reservations[*].Instances[*].NetworkInterfaces[0].PrivateIpAddress' --output text)
        COUNT=$(echo $SLAVES | wc -w)
        (( $COUNT < ${cluster_size} ))
    do
        continue
    done

    cluster_nodes=$(echo $MASTERS $SLAVES | sed -r 's/(\S+)/\1:6379/g')

    while [ $(nmap -oG - -p6379 $MASTERS $SLAVES | grep -c 6379/open) -lt $[${cluster_size}*2] ]
    do
        sleep 1
    done

    echo yes | redis-cli --cluster create $cluster_nodes --cluster-replicas 1
}

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum --enablerepo=remi install -y redis-${version}

cat > /etc/sysctl.d/99-redis.conf << EOF
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 1024
EOF

cat > /etc/redis.conf <<EOF
${redis_conf}
EOF

systemctl enable redis
systemctl start redis

# Only run on the first master
if [ "${role}" == "master" -a "${index}" == "0" ]; then
    aws configure set default.region ${region}
    create_cluster
fi

echo "Node Provisioned" > ~/.terraform_provisioned
chattr +i ~/.terraform_provisioned

