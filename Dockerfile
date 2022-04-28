# syntax=docker/dockerfile:1
FROM ubuntu:latest

WORKDIR /code

COPY . .

RUN apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
    python3-dev python3-pip sshpass git gcc; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --no-cache-dir -r requirements.txt

LABEL org.opencontainers.image.source https://github.com/colawebrunner/docker-acs