FROM alpine:latest

MAINTAINER wb_jian <wb_jian@qq.com>

WORKDIR /
ENV NPS_VERSION 0.26.5
ENV NPS_RELEASE_URL https://github.com/cnlh/nps/releases/download/v0.26.5/linux_amd64_server.tar.gz

RUN set -x && \
	wget --no-check-certificate ${NPS_RELEASE_URL} && \ 
	tar xzf linux_amd64_server.tar.gz && \
    rm linux_amd64_server.tar.gz

VOLUME /nps/conf

ENTRYPOINT ["/nps/nps"]