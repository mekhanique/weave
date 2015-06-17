#! /bin/bash

. ./config.sh

UNIVERSE=10.2.2.0/24

start() {
  host=$1
  shift
  proxy docker_on "$host" run "$@" -dt $SMALL_IMAGE /bin/sh
}

assert_no_ethwe() {
  assert_raises "container_ip $1 $2" 1
  assert_raises "proxy exec_on $1 $2 ip link show | grep -v ethwe"
}

start_suite "Ping proxied containers over cross-host weave network (with IPAM)"

weave_on $HOST1 launch -iprange $UNIVERSE
weave_on $HOST1 launch-proxy
start $HOST1 --name=auto
start $HOST1 --name=none       -e WEAVE_CIDR=none

weave_on $HOST2 launch -iprange $UNIVERSE $HOST1
weave_on $HOST2 launch-proxy --no-default-ipam
start $HOST2 --name=explicit   -e WEAVE_CIDR=
start $HOST2 --name=no-default

AUTO=$(container_ip $HOST1 auto)
EXPLICIT=$(container_ip $HOST2 explicit)
assert_raises "proxy exec_on $HOST1 auto     $PING $EXPLICIT"
assert_raises "proxy exec_on $HOST2 explicit $PING $AUTO"

assert_no_ethwe $HOST1 none
assert_no_ethwe $HOST2 no-default

end_suite
