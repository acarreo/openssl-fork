#!/bin/bash

if [[ "$1" = "cf" ]]; then
    echo "Build OpenSSL image with content filtering extesion."
    DOCKERFILE="content_filtering.Dockerfile"
    IMAGE="presto-content-filtering-tls:openssl-3.0.1"
else
    echo "Construct OpenSSL image"
    DOCKERFILE="openssl.Dockerfile"
    IMAGE="pile-tls--openssl:3.0.1"
fi

docker build -f ${DOCKERFILE} -t ${IMAGE} .

