#FROM alpine:3.7
# Docker commands
FROM docker:stable-dind

RUN set -ex \
    && echo "http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache \
    apache2-utils \
    bash \
    bind-tools \
    bird \
    bridge-utils \
    busybox-extras \
    conntrack-tools \
    curl \
    dhcping \
    drill \
    ethtool \
    fping \
    iftop \
    iperf \
    iproute2 \
    iptables \
    iptraf-ng \
    iputils \
    ipvsadm \
    liboping \
    mtr \
    net-snmp-tools \
    netcat-openbsd \
    ngrep \
    nmap \
    nmap-nping \
    nmap-nping \
    py-crypto \
    py2-virtualenv \
    python2 \
    scapy \
    socat \
    strace \
    tcpdump \
    tcptraceroute \
    util-linux \
    vim


# apparmor issue #14140
RUN mv /usr/sbin/tcpdump /usr/bin/tcpdump

# Installing calicoctl
RUN wget https://github.com/projectcalico/calicoctl/releases/download/v3.1.1/calicoctl && chmod +x calicoctl && mv calicoctl /usr/local/bin

# Netgen
ADD netgen.sh /usr/local/bin/netgen

# My scripts
ADD dtr-ol-ping.sh /usr/local/bin/dtr-ol-ping
ADD dump-network.sh /usr/local/bin/dump-network
ADD ee-ports.sh /usr/local/bin/ee-ports
ADD interlock-headers.sh /usr/local/bin/interlock-headers 
ADD selinux-ports.sh /usr/local/bin/selinux-ports
ADD grab-bundle.sh /usr/local/bin/grab-bundle
ADD aws-api-poll.sh /usr/local/bin/aws-api-poll 
ADD dockerveth.sh /usr/local/bin/dockerveth
ADD nmon.sh /usr/local/bin/nmon

# jq
ADD https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 /usr/local/bin/jq
RUN chmod a+x /usr/local/bin/jq

# Installing ctop - top-like container monitor
ADD https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64 /usr/local/bin/ctop 
RUN chmod +x /usr/local/bin/ctop

ADD motd /etc/motd
ADD profile  /etc/profile

CMD ["/bin/bash","-l"]
