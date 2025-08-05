ARG  TAG=20
FROM node:${TAG}

# Set working directory
WORKDIR /app

# Create docker group and add node user to it for Docker-outside-of-Docker support
RUN groupadd -f docker && \
    usermod -aG docker node || true

# TypeScript and tsc-watch are installed via install_tooling.sh

# Switch to root user for development
USER root
