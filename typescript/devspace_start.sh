#!/bin/bash
set +e  # Continue on errors

# Docker-outside-of-Docker: Fix permissions for Docker socket if it exists
if [ -e /var/run/docker.sock ]; then
    echo "Configuring Docker socket permissions..."
    # Get the GID of the docker socket
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    
    # Create or update docker group with the correct GID
    if getent group docker >/dev/null 2>&1; then
        # Update existing docker group GID if needed
        CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
        if [ "$CURRENT_DOCKER_GID" != "$DOCKER_GID" ]; then
            sudo groupmod -g $DOCKER_GID docker 2>/dev/null || true
        fi
    else
        # Create docker group with correct GID
        sudo groupadd -g $DOCKER_GID docker 2>/dev/null || true
    fi
    
    # Add current user to docker group
    sudo usermod -aG docker $(whoami) 2>/dev/null || true
    
    # Apply group membership without requiring logout
    newgrp docker || true
fi

export NODE_ENV=development
if [ -f "yarn.lock" ]; then
   echo "Installing Yarn Dependencies"
   yarn
else 
   if [ -f "package.json" ]; then
      echo "Installing NPM Dependencies"
      npm install
   fi
fi

COLOR_BLUE="\033[0;94m"
COLOR_GREEN="\033[0;92m"
COLOR_RESET="\033[0m"

# Print useful output for user
echo -e "${COLOR_BLUE}
     %########%      
     %###########%       ____                 _____                      
         %#########%    |  _ \   ___ __   __ / ___/  ____    ____   ____ ___ 
         %#########%    | | | | / _ \\\\\ \ / / \___ \ |  _ \  / _  | / __// _ \\
     %#############%    | |_| |(  __/ \ V /  ____) )| |_) )( (_| |( (__(  __/
     %#############%    |____/  \___|  \_/   \____/ |  __/  \__,_| \___\\\\\___|
 %###############%                                  |_|
 %###########%${COLOR_RESET}


Welcome to your development container!

This is how you can work with it:
- Files will be synchronized between your local machine and this container
- Some ports will be forwarded, so you can access this container via localhost
- Run \`${COLOR_GREEN}npm start${COLOR_RESET}\` to start the application

Docker-outside-of-Docker is enabled:
- You can use docker commands inside this container
- Docker commands will run on the host's Docker daemon
- Run \`${COLOR_GREEN}docker version${COLOR_RESET}\` to verify Docker access
"

# Set terminal prompt
export PS1="\[${COLOR_BLUE}\]devspace\[${COLOR_RESET}\] ./\W \[${COLOR_BLUE}\]\\$\[${COLOR_RESET}\] "
if [ -z "$BASH" ]; then export PS1="$ "; fi

# Include project's bin/ folder in PATH
export PATH="./bin:$PATH"

# Open shell with bash history persistence
bash