ARG  TAG=20
FROM node:${TAG}

# Set working directory
WORKDIR /app

# Create docker group and add node user to it for Docker-outside-of-Docker support
RUN groupadd -f docker && \
    usermod -aG docker node || true

# TypeScript and tsc-watch are installed via install_tooling.sh

# Copy bash configuration for persistent history
COPY .bashrc /root/.bashrc

# Create bash history file with proper permissions
RUN touch /app/.bash_history && chmod 666 /app/.bash_history

# Switch to root user for development
USER root
