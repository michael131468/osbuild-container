#!/bin/sh

sudo podman build -t osbuild:latest .
mkdir -p ./osbuild-store
sudo podman run --rm --privileged --cap-add=sys_admin,mknod --device-cgroup-rule="b 7:* rmw" -v /dev/loop-control:/dev/loop-control -v $(pwd)/osbuild-store:/mnt:z -it osbuild:latest /bin/sh
