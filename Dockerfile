FROM ubuntu:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Configure locale
RUN apt-get update && apt-get install -y locales \
    && localedef -i en_GB -c -f UTF-8 -A /usr/share/locale/locale.alias en_GB.UTF-8
ENV LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB:en \
    LC_ALL=en_GB.UTF-8

# Install dependencies
RUN apt-get update && apt-get install -y \
    perl \
    ca-certificates \
    libemail-sender-perl \
    libemail-mime-perl \
    libyaml-perl \
    libauthen-sasl-perl \
    libnet-ssleay-perl \
    libio-socket-ssl-perl \
    liburi-perl \
    libdatetime-perl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy your Perl script(s) and supporting files
COPY . /app

# Run the script when the container starts
CMD ["bin/generate_rota.pl"]
