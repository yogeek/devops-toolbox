FROM alpine:3.8


#-----------------------
# TERRAFORM
#-----------------------

ENV TERRAFORM_VERSION 0.11.10

RUN apk --update add ca-certificates curl && \
    curl -sSkL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > /terraform.zip && \
    unzip /terraform.zip && rm /terraform.zip && \
    mv terraform* /usr/local/bin && \
    chmod +x /usr/local/bin/terraform*

#-----------------------
# ANSIBLE
#-----------------------

ENV ANSIBLE_VERSION=2.6.4 \
    ANSIBLE_HOST_KEY_CHECKING=False
    
RUN apk --update add build-base libffi-dev \
    openssl-dev openssh-client \
    python-dev py-pip py-crypto py-jinja2 && \
    pip install --upgrade pip && \
    pip install ansible==${ANSIBLE_VERSION} && \
    apk del build-base openssl-dev libffi-dev python-dev

#-----------------------
# PACKER
#-----------------------

ENV PACKER_VERSION 1.3.1

RUN curl -LO "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
    rm packer_${PACKER_VERSION}_linux_amd64.zip && \
    mv packer /usr/local/bin

#-----------------------
# KUBECTL
#-----------------------

ENV KUBECTL_VERSION 1.10.7

RUN curl -sSL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    > /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl


#-----------------------
# KOPS
#-----------------------

ENV KOPS_VERSION 1.8.0
# https://kubernetes.io/docs/tasks/kubectl/install/
# latest stable kubectl: curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt

RUN curl -sSL https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
    > /usr/local/bin/kops \
    && chmod +x /usr/local/bin/kops


#-----------------------
# HELM
#-----------------------

ENV HELM_VERSION 2.9.0
RUN curl -LO "https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar xvzf helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    rm helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin && \
    rm -rf linux-amd64

#-----------------------
# AWS CLI
#-----------------------

ENV AWS_CLI_VERSION 1.16.30
RUN apk -Uuv add groff less python py-pip && \
	pip install awscli==${AWS_CLI_VERSION} && \
	rm /var/cache/apk/*

#-----------------------
# STERN
#-----------------------

ENV STERN_VERSION 1.6.0
RUN curl -sSL "https://github.com/wercker/stern/releases/download/${STERN_VERSION}/stern_linux_amd64" \
    > /usr/local/bin/stern && \
	chmod +x /usr/local/bin/stern

#-----------------------
# GOLANG
#-----------------------

# https://github.com/docker-library/golang/blob/master/1.10/alpine3.7/Dockerfile
ENV GOLANG_VERSION 1.11.1

RUN set -eux; \
  apk add --no-cache --virtual .build-deps \
    bash \
    sudo \
    gcc \
    musl-dev \
    openssl \
    go \
  ; \
  export \
# set GOROOT_BOOTSTRAP such that we can actually build Go
    GOROOT_BOOTSTRAP="$(go env GOROOT)" \
# ... and set "cross-building" related vars to the installed system's values so that we create a build targeting the proper arch
# (for example, if our build host is GOARCH=amd64, but our build env/image is GOARCH=386, our build needs GOARCH=386)
    GOOS="$(go env GOOS)" \
    GOARCH="$(go env GOARCH)" \
    GOHOSTOS="$(go env GOHOSTOS)" \
    GOHOSTARCH="$(go env GOHOSTARCH)" \
  ; \
# also explicitly set GO386 and GOARM if appropriate
# https://github.com/docker-library/golang/issues/184
  apkArch="$(apk --print-arch)"; \
  case "$apkArch" in \
    armhf) export GOARM='6' ;; \
    x86) export GO386='387' ;; \
  esac; \
  \
  curl -sSL "https://golang.org/dl/go${GOLANG_VERSION}.src.tar.gz" > go.tgz; \
  echo '558f8c169ae215e25b81421596e8de7572bd3ba824b79add22fba6e284db1117 *go.tgz' | sha256sum -c -; \
  tar -C /usr/local -xzf go.tgz; \
  rm go.tgz; \
  \
  cd /usr/local/go/src; \
  for p in /go-alpine-patches/*.patch; do \
    [ -f "$p" ] || continue; \
    patch -p2 -i "$p"; \
  done; \
  ./make.bash; \
  \
  rm -rf /go-alpine-patches; \
  apk del .build-deps; \
  \
  export PATH="/usr/local/go/bin:$PATH"; \
  go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

#-----------------------
# Utilities
# 
# => tmux : terminal multiplexer
# => jq : very useful to parse JSON output
# => htop : enhanced top
# => su-exec : to manage file permissions with docker bind-mount (lighter than gosu)
# => shadow : to have usermod commands for switching process user with su-exec
#-----------------------

RUN apk --update --no-cache add \
    tmux \
    openssl \
    htop \
    bash \
    git \
    zsh \
    zsh-vcs \
    make \
    jq \
    gettext \
    ncurses \
    shadow \
    su-exec

# Create devops user
RUN addgroup devops && adduser -S -G devops devops

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh

# Add a script to display useful information like tools versions (set as the default command of the image)
COPY versions.sh test.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/versions.sh && \
    chmod +x /usr/local/bin/test.sh

# OH-MY-ZSH
USER devops
RUN curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | zsh || true
COPY .zshrc /home/devops

# Use root for the entrypoint
USER root
CMD ["versions.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]
