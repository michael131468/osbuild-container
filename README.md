[![Build Container Images](https://github.com/michael131468/osbuild-container/actions/workflows/build-docker-image.yml/badge.svg)](https://github.com/michael131468/osbuild-container/actions/workflows/build-docker-image.yml)

# osbuild-container

OSBuild in a container.

# About

This project provides a container and set up information on how to run OSBuild in a **privileged**
[toolbox container][1]. 

The OSBuild project stages require permissions to do things like mount loopback devices or create
device nodes which cannot be done in a standard container namespace. This makes it not possible to
use OSBuild in a typical unprivileged container wrapped in user namespaces.

Since OSBuild cannot run in an unprivileged container, the only purpose of this is to be able to run
the latest versions of osbuild without installing it on the host system. The use case for me is to
have a disposable environment to build and experiment with the automotive-sig sample-images on my host
machine and to avoid installing the osbuild rpms.

This project also does not enable you to simply build images for a different architecture than the host
machine (i.e. aarch64 images on an x86_64 host). Although it is possible to use qemu-system-aarch64
within the container to do so (see bottom of this README).

# Running with Toolbx

The [Toolbx project](https://containertoolbx.org/) is a tool for containerised command
environments.

There are pre-built toolbox container images built and pushed to docker hub for this project. They
can be found [here][2].

To use these images as a toolbox environment, root privileges are required. Toolbx needs to
be spawned with sudo or as root to give the containerised environment access to the needed device
nodes. You can create the environment with the command below.

```
$ sudo toolbox create osbuild-toolbox -i docker.io/michael131468/osbuild-toolbox:latest
Image required to create toolbox container.
Download docker.io/michael131468/osbuild-toolbox:latest (500MB)? [y/N]: y
Created container: osbuild-toolbox
Enter with: toolbox enter osbuild-toolbox
```

After creating the environment, you can then enter the toolbox environment like so.

```
$ sudo toolbox enter osbuild-toolbox
```

There is an issue that the current working directory won't be mounted directly into the
toolbx container. Instead you'll be dropped into the home directory of the root account (typically
/root).

# Running with Podman

There are pre-built Podman container images built and pushed to docker hub for this project. They
can be found [here][3].

Optionally you can build the container image locally like so:

```
sudo podman build -t osbuild:latest .
```

Note the use of "sudo". This is because in the end the container must be run as root. (I did experiment
with using fakeroot/fakechroot to mask the mknod calls, but in the end I found I anyways need
access to /dev/loop-control to run image build operations with osbuild).

Now you can spawn a container with some extra privileges and mounts.

```
mkdir -p osbuild-store
sudo podman run \
  --rm \
  --privileged \
  --cap-add=sys_admin,mknod \
  --device-cgroup-rule="b 7:* rmw" \
  -v /dev:/dev \
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

I use this project to build AutoSD sample-images with the latest OSBuild versions without installing
them to my host system.

```
$ sudo toolbox create osbuild-toolbox -i docker.io/michael131468/osbuild-toolbox:latest
$ sudo toolbox enter osbuild-toolbox
# dnf install -y git make
# git clone https://gitlab.com/CentOS/automotive/sample-images.git
# cd sample-images/osbuild-manifests
# make cs9-qemu-minimal-ostree.x86_64.img
```

The --store and --output-directory parameters for osbuild are configured by the makefile BUILDDIR
variable thus it needs to be set when calling make (unless the repo is cloned into the externally
mounted directory in which case BUILDDIR will by default use it).

# Building ARM64 Images with a QEMU VM

The sample-images project comes with support to wrap osbuild in a qemu virtual machine. I've tested this
and found it possible to do so within the toolbox container. I can fetch a pre-built aarch64 system image
to use as a base for qemu from the nightly artefacts produced by the AutoSD project.

```
$ sudo toolbox create osbuild-toolbox -i docker.io/michael131468/osbuild-toolbox:latest
$ sudo toolbox enter osbuild-toolbox
# dnf install -y git make qemu-system-aarch64
# git clone https://gitlab.com/CentOS/automotive/sample-images.git
# cd sample-images/osbuild-manifests
# mkdir -p _build
# cd _build
# wget --recursive --no-parent --no-directories -A "osbuildvm*" 'https://autosd.sig.centos.org/AutoSD-9/nightly/osbuildvm-images/'
# cd ..
# make cs9-qemu-developer-ostree.aarch64.img
```

This approach is significantly slower than building on the native architecture as the emulation reduces
performance. One should expect a very slow build process.

[1]: https://containertoolbx.org/
[2]: https://hub.docker.com/repository/docker/michael131468/osbuild-toolbox
[3]: https://hub.docker.com/repository/docker/michael131468/osbuild-docker
