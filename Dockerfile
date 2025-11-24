FROM ubuntu:noble
RUN mkdir /workdir
COPY ./spectrum_protect.8.1.13.3.tar.gz.aa \
     ./spectrum_protect.8.1.13.3.tar.gz.ab \
     ./spectrum_protect.8.1.13.3.tar.gz.ac \
     ./spectrum_protect.8.1.13.3.tar.gz.ad \
     ./spectrum_protect.8.1.13.3.tar.gz.ae /workdir
RUN <<EOF
cd /workdir \
&& cat spectrum_protect.8.1.13.3.tar.gz.a* > spectrum_protect.8.1.13.3.tar.gz \
&& tar xvf spectrum_protect.8.1.13.3.tar.gz \
&& dpkg -i gskcrypt64_8.0-55.24.linux.x86_64.deb gskssl64_8.0-55.24.linux.x86_64.deb \
&& dpkg -i tivsm-api64.amd64.deb \
&& dpkg -i tivsm-apicit.amd64.deb \
&& dpkg -i tivsm-ba.amd64.deb \
&& dpkg -i tivsm-bacit.amd64.deb \
&& dpkg -i tivsm-bahdw.amd64.deb
EOF

RUN mkdir /data \
 && ln -sf /dev/stdout /opt/tivoli/tsm/dsmsched.log \
 && ln -sf /dev/stderr /opt/tivoli/tsm/error.log

VOLUME /data
VOLUME /etc/adsm

WORKDIR /data

CMD ["/usr/bin/dsmc", "incr"]