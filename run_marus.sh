#!/bin/bash

# Boje za terminalski ispis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Bez boje

echo -e "${YELLOW}Pokretanje MARUS 2.0 simulatora...${NC}"

# 1. Omogućavanje pristupa X poslužitelju (X11 prosljeđivanje) za GUI (Unity 6 i RViz 2)
echo -e "Priprema grafičkog sučelja (xhost)..."
xhost +local:docker > /dev/null 2>&1 || xhost +
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[Uspješno] X11 pristup je odobren za Docker.${NC}"
else
    echo -e "${RED}[Upozorenje] Neuspješno postavljanje xhost +. Grafičko sučelje (GUI) možda neće raditi.${NC}"
fi

# 2. Provjera i kreiranje dijeljene mape na vašem računalu
SHARED_DIR="${HOME}/marus2_shared"
if [ ! -d "$SHARED_DIR" ]; then
    echo -e "Kreiranje dijeljene mape za projekte: $SHARED_DIR"
    mkdir -p "$SHARED_DIR"
    chmod 777 "$SHARED_DIR"
else
    echo -e "${GREEN}[Uspješno] Dijeljena mapa već postoji na putanji: $SHARED_DIR${NC}"
fi

# 3. Provjera Nvidia grafičke podrške
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}[Uspješno] Nvidia driveri su detektirani na sustavu.${NC}"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
else
    echo -e "${RED}[Upozorenje] nvidia-smi nije pronađen! Provjerite jesu li Nvidia driveri ispravno instalirani.${NC}"
fi

# 4. Pokretanje Docker Compose-a
echo -e "Pokretanje Docker kontejnera..."
docker compose up -d

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}====================================================================${NC}"
    echo -e "${GREEN}MARUS 2.0 kontejner je uspješno pokrenut u pozadini!${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "Za ulazak u kontejner (bash terminal) koristite:"
    echo -e "  ${YELLOW}docker compose exec marus2_simulator bash${NC}"
    echo -e "--------------------------------------------------------------------"
    echo -e "Unutar kontejnera možete pokrenuti:"
    echo -e "  1. ROS 2 Lyrical adapter: ${YELLOW}ros2 launch grpc_ros_adapter ros2_server_launch.py${NC}"
    echo -e "  2. Unity Hub:             ${YELLOW}unityhub${NC}"
    echo -e "====================================================================\n"
else
    echo -e "${RED}[Greška] Došlo je do problema prilikom podizanja kontejnera.${NC}"
fi