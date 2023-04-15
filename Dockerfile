FROM alpine:3.17
COPY ipsec.conf /etc/ipsec.conf
COPY ipsec.secrets /etc/ipsec.secrets
COPY bypass-lan.conf /etc/strongswan.d/charon/bypass-lan.conf
COPY build-ipsec-conf.sh /usr/local/bin/
RUN apk add --no-cache tini strongswan
