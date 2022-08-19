# osbuild-docker

Dockerfile for osbuild fedora environment

# About

This project provides a container configuration and set up information on how to run osbuild in a 
**privileged** podman container. The only purpose of this is to be able to run the latest versions of
osbuild without installing it on the host system.

**Warning:** This project does not allow you to run osbuild in an unprivileged manner. The osbuild
project stages require permissions to do things like mount loopback devices or create device nodes
which cannot be done in a container namespace.

I created this container environment as a way to build the AutoSD sample-images on my host machine
without needing to install osbuild rpms.

# How to run

To run this, first build the container and then spawn a shell in the container with some extra
privileges.

```
sudo podman build -t osbuild:latest .
```

Note the sudo, this is because in the end the container must be run as root. (I did experiment
with using fakeroot/fakechroot to mask the mknod calls, but in the end I found I anyways need
access to /dev/loop-control to run image build operations with osbuild).

Now you can spawn a shell in the container with some extra privileges and mounts.

```
mkdir -p osbuild-store
sudo podman run \
  --rm \
  --privileged \
  --cap-add=sys_admin,mknod \
  --device-cgroup-rule="b 7:* rmw" \
  -v /dev/loop-control:/dev/loop-control \
  -v $(pwd)/osbuild-store:/mnt:z \
  -it osbuild:latest \
  /bin/sh
```

Note that we need to make a temporary directory outside of the container and mount it in to the
container. This is for osbuild to store artifacts it's working on. We need this because the selinux
setattr/getattr system calls do not work properly on the overlayfs within the container filesystem.
By having an externally mounted directory, we can workaround that.

The above can also be executed by using the included run.sh script in this project.

You can run osbuild once inside the container. You must specify the store and output directory
using --store and --output-directory to point to the mounted external directory (/mnt).

```
$ osbuild --store /mnt/store --output-directory /mnt/output [...]
```

# Example: Building AutoSD sample-images

I use this project to build AutoSD sample-images with the latest osbuild versions without installing
them to my host system.

```
$ git clone https://gitlab.com/CentOS/automotive/sample-images.git
$ cd sample-images/osbuild-manifests
$ make cs9-qemu-minimal-ostree.x86_64.img BUILDDIR=/mnt
```

The --store and --output-directory parameters for osbuild are configured by the makefile BUILDDIR
variable thus it needs to be set when calling make (unless the repo is cloned into the externally
mounted directory in which case BUILDDIR will by default use it).
