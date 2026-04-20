FROM ubuntu:24.04

ARG TARGET_VERSION=1.6.11
ENV TARGET_VERSION=${TARGET_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV UCF_FORCE_CONFFOLD=1
ENV DEBIAN_PRIORITY=critical

COPY rc_install.sh /root/rc_install.sh
COPY entrypoint.sh /root/entrypoint.sh

RUN chmod +x /root/rc_install.sh /root/entrypoint.sh && \
    /root/rc_install.sh

EXPOSE 80

ENTRYPOINT ["/root/entrypoint.sh"]
