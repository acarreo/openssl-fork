FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENSSL_BRANCH="presto-content-filtering"

RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends git \
	cmake make g++ ca-certificates libgmp-dev vim pkg-config valgrind && apt-get clean

RUN mkdir -p /usr/local/ssl
COPY openssl.cnf /usr/local/ssl/

RUN git clone https://github.com/acarreo92/openssl-fork.git /root/openssl
WORKDIR /root/openssl
RUN git checkout ${OPENSSL_BRANCH}
COPY content_filtering_extension.patch /root/content_filtering_extension.patch
RUN git apply /root/content_filtering_extension.patch
RUN ./Configure -g && make -j && make install_sw
RUN echo "/usr/local/lib64" >> /etc/ld.so.conf.d/libc.conf && ldconfig
RUN openssl req -new -days 365 -nodes -x509 -subj "/" -keyout /home/server.key -out /home/server.crt
