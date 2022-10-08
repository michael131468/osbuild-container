FROM fedora:36

ARG VERSION=

RUN mkdir -p /run/osbuild

RUN dnf install -y 'dnf-command(copr)' && \
    dnf copr enable -y @osbuild/osbuild && \
    dnf install -y osbuild${VERSION} osbuild-tools${VERSION} && \
    dnf remove -y 'dnf-command(copr)'
