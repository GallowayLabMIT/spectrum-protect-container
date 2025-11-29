FROM ubuntu:noble
RUN mkdir /workdir
COPY ./spectrum_protect.8.1.13.3.tar.gz.aa \
     ./spectrum_protect.8.1.13.3.tar.gz.ab \
     ./spectrum_protect.8.1.13.3.tar.gz.ac \
     ./spectrum_protect.8.1.13.3.tar.gz.ad \
     ./spectrum_protect.8.1.13.3.tar.gz.ae \
     ./entrypoint.sh /workdir
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

RUN <<EOF
apt-get update \
&& apt-get install -y ca-certificates openssl \
&& update-ca-certificates \
&& rm -rf /var/lib/apt/lists/* \
&& chmod +x /workdir/entrypoint.sh
EOF

ENV LD_LIBRARY_PATH=/usr/local/ibm/gsk8_64/lib64

RUN mkdir /data

VOLUME /data
VOLUME /etc/adsm

WORKDIR /data

ENTRYPOINT ["/workdir/entrypoint.sh"]
