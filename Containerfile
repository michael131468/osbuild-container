FROM fedora:36

ARG OSBUILD_VERSION=

RUN mkdir -p /run/osbuild

RUN dnf install -y 'dnf-command(copr)' && \
    dnf copr enable -y @osbuild/osbuild && \
    dnf install -y osbuild${OSBUILD_VERSION} osbuild-tools${OSBUILD_VERSION} osbuild-ostree${OSBUILD_VERSION} && \
    dnf remove -y 'dnf-command(copr)'
