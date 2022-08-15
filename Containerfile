FROM fedora:36

RUN mkdir -p /run/osbuild

RUN dnf install -y \
        git \
        make \
        python3-setuptools \
        python3-devel \
        python3-docutils \
        rpm-build \
        selinux-policy \
        selinux-policy-devel \
        systemd

RUN git clone https://github.com/osbuild/osbuild.git

RUN make -C osbuild rpm && \
    dnf install -y osbuild/rpmbuild/RPMS/noarch/*.rpm

