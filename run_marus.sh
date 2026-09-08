#!/bin/bash

# Color definitions for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting MARUS 2.0 Simulator...${NC}"

# 1. Enable X11 forwarding for graphical interfaces (Unity 6 and RViz 2)
echo -e "Configuring display server permissions (xhost)..."
xhost +local:docker > /dev/null 2>&1 || xhost + > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[Success] X11 access granted for Docker.${NC}"
else
    echo -e "${RED}[Warning] Failed to set xhost permissions. Graphical interface (GUI) may not display properly.${NC}"
fi

# 2. Check and prepare shared workspace folder on host machine
SHARED_DIR="${HOME}/marus2_shared"
if [ ! -d "$SHARED_DIR" ]; then
    echo -e "Creating shared project directory: $SHARED_DIR"
    mkdir -p "$SHARED_DIR"
    chmod 777 "$SHARED_DIR"
else
    echo -e "${GREEN}[Success] Shared directory already exists: $SHARED_DIR${NC}"
fi

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

# 4. Check NVIDIA GPU and Docker runtime support
COMPOSE_FILE="docker-compose.yaml"
HAS_NVIDIA=false

if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}[Success] NVIDIA GPU and drivers detected on host:${NC}"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    HAS_NVIDIA=true

    # Check if Docker daemon has NVIDIA runtime configured
    if ! $DOCKER_CMD info 2>/dev/null | grep -qi "nvidia"; then
        echo -e "${YELLOW}[Notice] NVIDIA Container Runtime is not registered in Docker daemon.${NC}"
        if command -v nvidia-ctk &> /dev/null; then
            echo -e "${BLUE}Configuring Docker to use nvidia-container-toolkit...${NC}"
            if sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl daemon-reload && sudo systemctl restart docker; then
                echo -e "${GREEN}[Success] Docker daemon configured with NVIDIA runtime and restarted.${NC}"
                sleep 2
            else
                echo -e "${YELLOW}[Warning] Could not automatically configure Docker daemon.${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}[Warning] nvidia-smi not found. NVIDIA GPU acceleration will not be used.${NC}"
    if [ -f "docker-compose.cpu.yaml" ]; then
        echo -e "${BLUE}Using CPU-only fallback compose configuration (docker-compose.cpu.yaml)...${NC}"
        COMPOSE_FILE="docker-compose.cpu.yaml"
    fi
fi

# 5. Start Docker container via Docker Compose
echo -e "Starting Docker container (${COMPOSE_FILE})..."
$DOCKER_CMD compose -f "${COMPOSE_FILE}" up -d

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}MARUS 2.0 container has started successfully in the background!${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "To open an interactive shell inside the container, run:"
    echo -e "  ${YELLOW}${DOCKER_CMD} compose exec marus2_simulator bash${NC}"
    echo -e "--------------------------------------------------------------------"
    echo -e "Inside the container, you can launch:"
    echo -e "  1. ROS 2 Lyrical adapter: ${YELLOW}ros2 launch marus2_ros_adapter ros2_server_launch.py${NC}"
    echo -e "  2. Unity Hub:             ${YELLOW}unityhub${NC}"
    echo -e "====================================================================\n"
else
    echo -e "\n${RED}[Error] Failed to start Docker container.${NC}"
    if [ "$HAS_NVIDIA" = true ] && [ "$COMPOSE_FILE" = "docker-compose.yaml" ]; then
        echo -e "${YELLOW}--------------------------------------------------------------------"
        echo -e "If you encountered 'could not select device driver \"nvidia\" with capabilities: [[gpu]]':"
        echo -e "Run these commands to configure and reload Docker with NVIDIA support:"
        echo -e "  ${GREEN}sudo nvidia-ctk runtime configure --runtime=docker${NC}"
        echo -e "  ${GREEN}sudo systemctl daemon-reload${NC}"
        echo -e "  ${GREEN}sudo systemctl restart docker${NC}"
        echo -e ""
        echo -e "Alternatively, to run in CPU mode without GPU reservation:"
        echo -e "  ${GREEN}${DOCKER_CMD} compose -f docker-compose.cpu.yaml up -d${NC}"
        echo -e "--------------------------------------------------------------------${NC}\n"
    fi
    exit 1
fi