FROM ubuntu:16.04

RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
    wget ca-certificates autoconf bison build-essential libssl-dev \
    libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev \
    libffi-dev libgdbm3 libgdbm-dev libdb-dev && \
    update-ca-certificates

RUN wget -O - https://github.com/rbenv/ruby-build/archive/v20210119.tar.gz | tar xz && \
    PREFIX=/usr/local ./ruby-build-20210119/install.sh

ENV LANG=C.UTF-8

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
