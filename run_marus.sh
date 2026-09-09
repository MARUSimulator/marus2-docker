#!/bin/bash

# Color definitions for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting MARUS 2.0 ROS 2 Environment...${NC}"

# 1. Enable X11 forwarding for graphical ROS tools (e.g. RViz 2, rqt)
echo -e "Configuring display server permissions (xhost)..."
xhost +local:docker > /dev/null 2>&1 || xhost + > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[Success] X11 access granted for Docker.${NC}"
else
    echo -e "${YELLOW}[Notice] xhost permissions could not be set automatically. (Only required if using RViz inside Docker).${NC}"
fi

# 2. Check and prepare shared workspace folder on host machine
SHARED_DIR="${HOME}/marus2_shared"
mkdir -p "$SHARED_DIR"
chmod 777 "$SHARED_DIR" 2>/dev/null || true
echo -e "${GREEN}[Success] Shared exchange directory ready (${SHARED_DIR}).${NC}"

# 3. Check Docker daemon access and permissions
DOCKER_CMD="docker"
if ! docker info > /dev/null 2>&1; then
    if sudo docker info > /dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo -e "${YELLOW}[Notice] Docker requires root privileges. Using 'sudo docker'.${NC}"
        echo -e "${YELLOW}         Tip: To run docker without sudo, execute:${NC}"
        echo -e "${YELLOW}              sudo usermod -aG docker \$USER && newgrp docker${NC}"
    else
        echo -e "${RED}[Error] Cannot connect to the Docker daemon. Is Docker installed and running?${NC}"
        exit 1
    fi
fi

# 4. Start Docker container via Docker Compose
COMPOSE_FILE="docker-compose.yaml"
echo -e "Starting Docker container (${COMPOSE_FILE})..."
$DOCKER_CMD compose -f "${COMPOSE_FILE}" up -d

if [ $? -eq 0 ]; then
    echo -e "${BLUE}Waiting for ROS 2 adapter gRPC server to initialize...${NC}"
    sleep 2
    echo -e "\n${BLUE}--- Adapter Initial Startup Logs ---${NC}"
    $DOCKER_CMD compose logs --tail=10 marus2_simulator
    echo -e "${BLUE}------------------------------------${NC}"

    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}🚀 MARUS 2.0 ROS 2 adapter is running and listening on localhost!  ${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "You can now open ${YELLOW}marus2-example${NC} in Unity 6 on your host and press ${YELLOW}Play${NC}!"
    echo -e "--------------------------------------------------------------------"
    echo -e "Helpful commands:"
    echo -e "  - Follow live adapter logs: ${YELLOW}${DOCKER_CMD} compose logs -f${NC}"
    echo -e "  - Open interactive shell:   ${YELLOW}${DOCKER_CMD} compose exec marus2_simulator bash${NC}"
    echo -e "  - Stop the container:       ${YELLOW}${DOCKER_CMD} compose down${NC}"
    echo -e "====================================================================\n"
else
    echo -e "\n${RED}[Error] Failed to start Docker container.${NC}"
    exit 1
fi