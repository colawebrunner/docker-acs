# syntax=docker/dockerfile:1
FROM ubuntu:latest as base

FROM base as builder

RUN mkdir /install
WORKDIR /install

COPY requirements.txt requirements.txt

RUN apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
    python3-dev python3-pip sshpass git gcc; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip
# RUN python3 -m pip install --no-cache-dir -r requirements.txt

RUN python3 -m pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM base

COPY --from=builder /install /usr/local

RUN apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
    openssh-client nano vim git sshpass; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN git config --global credential.helper "cache --timeout=86400"

WORKDIR /code

LABEL org.opencontainers.image.source https://github.com/colawebrunner/docker-acs
