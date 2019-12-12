FROM exist2resist/centos7
MAINTAINER admin@dataandstoragesolutions.com
ENV TZ='America/Edmonton' PUID=99 GUID=100 PORT=80 DEV_ENV='testing'

COPY ./install.sh /tmp/
RUN chmod 755 /tmp/install.sh && /tmp/install.sh && rm -rf /tmp/*

EXPOSE 80 81 82 83 84 85 86 87 88 89 90
VOLUME ["/etc/nginx","/environments"]
CMD ["/usr/local/bin/systemctl"]