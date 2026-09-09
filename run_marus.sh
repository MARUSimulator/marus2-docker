#!/bin/bash

# Color definitions for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting MARUS 2.0 ROS 2 Environment...${NC}"

# 1. Enable X11 forwarding for graphical ROS tools (e.g. RViz 2, rqt)
xhost +local:docker > /dev/null 2>&1 || xhost + > /dev/null 2>&1

# 2. Check and prepare shared workspace folder on host machine
SHARED_DIR="${HOME}/marus2_shared"
mkdir -p "$SHARED_DIR"
chmod 777 "$SHARED_DIR" 2>/dev/null || true

# 3. Check Docker daemon access and permissions
DOCKER_CMD="docker"
if ! docker info > /dev/null 2>&1; then
    if sudo docker info > /dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    else
        echo -e "${RED}[Error] Cannot connect to the Docker daemon. Is Docker running?${NC}"
        exit 1
    fi
fi

COMPOSE_FILE="docker-compose.yaml"

# 4. Handle detached (background) vs attached (foreground) mode
if [ "$1" == "-d" ] || [ "$1" == "--detach" ]; then
    echo -e "Starting ROS 2 container in background..."
    $DOCKER_CMD compose -f "${COMPOSE_FILE}" up -d
    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}🚀 MARUS 2.0 ROS 2 adapter is running in the background!            ${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "Follow live logs:  ${YELLOW}${DOCKER_CMD} compose logs -f${NC}"
    echo -e "Open shell:        ${YELLOW}${DOCKER_CMD} compose exec marus2_simulator bash${NC}"
    echo -e "Stop container:    ${YELLOW}${DOCKER_CMD} compose down${NC}"
    echo -e "====================================================================\n"
else
    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}🚀 Starting MARUS 2.0 ROS 2 Adapter (Attached Mode)                 ${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "The server will stay open and stream live output to this terminal."
    echo -e "Open ${YELLOW}marus2-example${NC} in Unity 6 on your host and press ${YELLOW}Play${NC}!"
    echo -e "${YELLOW}(Press Ctrl+C anytime to cleanly stop the server)${NC}"
    echo -e "--------------------------------------------------------------------\n"
    $DOCKER_CMD compose -f "${COMPOSE_FILE}" up
fi