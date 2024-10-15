#!/bin/bash

if sudo -n true 2>/dev/null; then
    echo "This user has sudo permissions"
else
    echo "This user does not have sudo permissions"
    exit 1
fi

if [ -f /etc/redhat-release ]; then
    if grep -q "Rocky" /etc/redhat-release; then
        OS="Rocky"
        PACKAGE_MANAGER="dnf"
    elif grep -q "AlmaLinux" /etc/redhat-release; then
        OS="AlmaLinux"
        PACKAGE_MANAGER="dnf"
    else
        OS="CentOS"
        PACKAGE_MANAGER="yum"
    fi
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            OS="Debian/Ubuntu"
            PACKAGE_MANAGER="apt"
            ;;
        fedora)
            OS="Fedora"
            PACKAGE_MANAGER="dnf"
            ;;
        *)
            echo "Unsupported OS"
            exit 1
            ;;
    esac
else
    echo "Unsupported OS"
    exit 1
fi

if [ "$PACKAGE_MANAGER" = "apt" ]; then
    echo "Updating server"
    sudo apt update -qq > /dev/null 2>&1 && echo "Server updated ✓"
else
    echo "Updating server"
    sudo $PACKAGE_MANAGER update -y -q > /dev/null 2>&1 && echo "Server updated ✓"
fi

necessary_packages=(
    dialog
    whiptail
    jq
    lsof
    tar
    wget
    git
)

install_package() {
    package=$1
    if ! command -v $package &> /dev/null; then
        echo -n "Installing $package... "
        if sudo $PACKAGE_MANAGER install $package -y -qq > /dev/null 2>&1; then
            echo "✓"
        else
            echo "✕"
            exit 1
        fi
    else
        echo "$package is already installed ✓"
    fi
}

for package in "${necessary_packages[@]}"; do
    install_package "$package"
done

if ! grep -q "alias relay='bash -c \"/opt/hiddify-relay/menu.sh\"'" ~/.bashrc; then
    echo "alias relay='bash -c \"/opt/hiddify-relay/menu.sh\"'" >> ~/.bashrc
    echo "Alias added to .bashrc"
    source ~/.bashrc
else
    echo "Alias already exists in .bashrc"
    source ~/.bashrc
fi

sleep 3
clear

git clone -b beta https://github.com/hiddify/hiddify-relay /opt/hiddify-relay > /dev/null 2>&1
cd /opt/hiddify-relay
chmod +x menu.sh
./menu.sh
