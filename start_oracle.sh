#!/bin/bash

# ─────────────────────────────────────────────
#  Oracle XE Auto Starter + Auto Setup Script
#  Author: Anupam
# ─────────────────────────────────────────────

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

ORACLE_CONTAINER="oracle-db"
ORACLE_IMAGE="gvenzl/oracle-xe"
ORACLE_PASSWORD="main"
ORACLE_PORT=1521

echo -e "${BLUE}🔹 Starting Docker service...${RESET}"
sudo systemctl start docker 2>/dev/null

if ! sudo systemctl is-active --quiet docker; then
  echo -e "${RED}❌ Docker failed to start. Please check your Docker installation.${RESET}"
  exit 1
fi
echo -e "${GREEN}✅ Docker is running.${RESET}"

# ─────────────────────────────────────────────
#  Check if Oracle container exists
# ─────────────────────────────────────────────
if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^${ORACLE_CONTAINER}$"; then
  echo -e "${YELLOW}⚠️  Oracle container not found. Creating a new one...${RESET}"
  sudo docker run -d \
    --name ${ORACLE_CONTAINER} \
    -p ${ORACLE_PORT}:1521 \
    -e ORACLE_PASSWORD=${ORACLE_PASSWORD} \
    ${ORACLE_IMAGE}

  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create Oracle container.${RESET}"
    exit 1
  fi
  echo -e "${GREEN}✅ Oracle container created successfully.${RESET}"
else
  echo -e "${BLUE}🔹 Starting existing Oracle container...${RESET}"
  sudo docker start ${ORACLE_CONTAINER} >/dev/null 2>&1
fi

# ─────────────────────────────────────────────
#  Wait for Oracle Database to start
# ─────────────────────────────────────────────
echo -e "${YELLOW}⏳ Waiting for Oracle Database to initialize...${RESET}"
until sudo docker logs ${ORACLE_CONTAINER} 2>&1 | grep -q "DATABASE IS READY TO USE!"; do
  sleep 5
  echo -e "${YELLOW}   ...still waiting for Oracle to initialize...${RESET}"
done
echo -e "${GREEN}✅ Oracle Database is ready!${RESET}"

# ─────────────────────────────────────────────
#  Connect to Oracle SQL
# ─────────────────────────────────────────────
echo -e "${BLUE}🔗 Connecting to Oracle SQL as SYSTEM...${RESET}"
sudo docker exec -it ${ORACLE_CONTAINER} sqlplus system/${ORACLE_PASSWORD}@XEPDB1 || \
sudo docker exec -it ${ORACLE_CONTAINER} sqlplus system/${ORACLE_PASSWORD}@XE
