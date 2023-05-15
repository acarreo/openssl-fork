FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENSSL_BRANCH="openssl-3.0"

RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends git \
	cmake make g++ ca-certificates libgmp-dev vim pkg-config && apt-get clean

RUN mkdir -p /usr/local/ssl
COPY openssl.cnf /usr/local/ssl/

RUN git clone --branch ${OPENSSL_BRANCH} --depth 1 https://github.com/openssl/openssl.git /root/openssl
WORKDIR /root/openssl
RUN ./Configure && make -j && make install_sw
RUN echo "/usr/local/lib64" >> /etc/ld.so.conf.d/libc.conf && ldconfig
RUN openssl req -new -days 365 -nodes -x509 -subj "/" -keyout /home/server.key -out /home/server.crt
