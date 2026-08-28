# syntax=docker/dockerfile:1
FROM ubuntu:latest AS base

FROM base AS builder

RUN apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates python3-dev python3-venv python3-pip gcc; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Build into a virtualenv: Ubuntu marks the system Python as externally managed
# (PEP 668), so pip refuses to install into /usr without --break-system-packages.
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

FROM base

RUN apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates python3 openssh-client nano vim git sshpass; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Supply GitHub credentials from the environment at runtime. The helper is scoped
# to github.com so the token is never offered to any other host, and $GITHUB_PAT
# stays unexpanded here so it resolves in the running container, not at build time
# -- the token must never be baked into an image layer.
RUN git config --global credential.'https://github.com'.helper \
    '!f() { test "$1" = get && test -n "$GITHUB_PAT" && { echo username=x-access-token; echo "password=$GITHUB_PAT"; }; }; f'

WORKDIR /code

LABEL org.opencontainers.image.source=https://github.com/colawebrunner/docker-acs
