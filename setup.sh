#!/usr/bin/env bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (with sudo)${NC}"
   exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}=== NixOS Configuration Setup ===${NC}\n"

# Step 1: Add home-manager channel if not already added
echo -e "${YELLOW}Step 1: Checking home-manager channel...${NC}"
if ! nix-channel --list | grep -q "home-manager"; then
    echo "Adding home-manager channel..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
else
    echo "home-manager channel already exists"
fi

# Step 2: Update channels
echo -e "\n${YELLOW}Step 2: Updating channels...${NC}"
nix-channel --update

# Step 3: Interactive host selection
echo -e "\n${YELLOW}Step 3: Select your host${NC}"

# Discover available hosts from the hosts/ directory
HOSTS_DIR="$SCRIPT_DIR/hosts"
if [[ ! -d "$HOSTS_DIR" ]]; then
    echo -e "${RED}Error: hosts/ directory not found${NC}"
    exit 1
fi

# Get list of host directories
mapfile -t HOSTS < <(find "$HOSTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

if [[ ${#HOSTS[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No hosts found in hosts/ directory${NC}"
    exit 1
fi

echo "Available hosts:"
for i in "${!HOSTS[@]}"; do
    echo "  $((i+1))) ${HOSTS[$i]}"
done
echo ""
read -p "Enter your choice (1-${#HOSTS[@]}): " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#HOSTS[@]} ]]; then
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

HOST="${HOSTS[$((choice-1))]}"

echo -e "\n${GREEN}Selected host: $HOST${NC}"

# Step 4: Create symlinks
echo -e "\n${YELLOW}Step 4: Creating symlinks...${NC}"

# Symlink configuration.nix
echo "Linking configuration-${HOST}.nix -> /etc/nixos/configuration.nix"
ln -sf "$SCRIPT_DIR/configuration-${HOST}.nix" /etc/nixos/configuration.nix

# Symlink hardware-configuration.nix if it exists
if [[ -f "$SCRIPT_DIR/hosts/${HOST}/hardware-configuration.nix" ]]; then
    echo "Linking hosts/${HOST}/hardware-configuration.nix -> /etc/nixos/hardware-configuration.nix"
    ln -sf "$SCRIPT_DIR/hosts/${HOST}/hardware-configuration.nix" /etc/nixos/hardware-configuration.nix
else
    echo -e "${YELLOW}Warning: No hardware-configuration.nix found for $HOST${NC}"
    echo "You may need to generate it with: nixos-generate-config --show-hardware-config"
fi

# Symlink modules directory
echo "Linking modules/ -> /etc/nixos/modules"
ln -sf "$SCRIPT_DIR/modules" /etc/nixos/modules

# Symlink home directory
echo "Linking home/ -> /etc/nixos/home"
ln -sf "$SCRIPT_DIR/home" /etc/nixos/home

# Step 5: Ask before rebuilding
echo -e "\n${YELLOW}Step 5: Rebuild system${NC}"
read -p "Run 'nixos-rebuild switch' now? (y/N): " rebuild

if [[ $rebuild =~ ^[Yy]$ ]]; then
    echo -e "\n${GREEN}Running nixos-rebuild switch...${NC}"
    nixos-rebuild switch
    echo -e "\n${GREEN}Setup complete!${NC}"
else
    echo -e "\n${YELLOW}Symlinks created. Run 'sudo nixos-rebuild switch' when ready.${NC}"
fi

echo -e "\n${GREEN}Done!${NC}"
