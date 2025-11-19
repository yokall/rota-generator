FROM ubuntu:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Configure locale
RUN apt-get update && apt-get install -y locales \
    && localedef -i en_GB -c -f UTF-8 -A /usr/share/locale/locale.alias en_GB.UTF-8
ENV LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB:en \
    LC_ALL=en_GB.UTF-8

# Install basic build tools and dependencies
RUN apt-get update && apt-get install -y \
    perl \
    build-essential \
    git \
    apt-transport-https ca-certificates gnupg curl

# Install testing modules
RUN apt-get update && apt-get install -y \
    libtest2-suite-perl \
    libtest2-harness-perl \
    libdevel-cover-perl

# Install perl development tools
RUN apt-get update && apt-get install -y \
    libdevel-nytprof-perl \
    libperl-critic-perl \
    perltidy \
    libdist-zilla-perl

# Install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && apt-get update -y && apt-get install google-cloud-cli -y

# Install perl modules for application
RUN apt-get update && apt-get install -y  \
    libemail-sender-perl \
    libemail-mime-perl \
    libauthen-sasl-perl \
    libnet-ssleay-perl \
    libio-socket-ssl-perl \
    liburi-perl
