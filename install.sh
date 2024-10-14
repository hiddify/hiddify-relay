#!/bin/bash

if sudo -n true 2>/dev/null; then
    echo "This User has sudo permissions"
else
    echo "This User does not have sudo permissions"
    exit 1
fi

if [ -f /etc/redhat-release ]; then
    if grep -q "Rocky" /etc/redhat-release; then
        OS="Rocky"
        PACKAGE_MANAGER="dnf"
        SERVICE_MANAGER="systemctl"
    elif grep -q "AlmaLinux" /etc/redhat-release; then
        OS="AlmaLinux"
        PACKAGE_MANAGER="dnf"
        SERVICE_MANAGER="systemctl"
    else
        OS="CentOS"
        PACKAGE_MANAGER="yum"
        SERVICE_MANAGER="systemctl"
    fi
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu)
            OS="Ubuntu"
            PACKAGE_MANAGER="apt"
            SERVICE_MANAGER="systemctl"
            ;;
        debian)
            OS="Debian"
            PACKAGE_MANAGER="apt"
            SERVICE_MANAGER="systemctl"
            ;;
        fedora)
            OS="Fedora"
            PACKAGE_MANAGER="dnf"
            SERVICE_MANAGER="systemctl"
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
    sudo apt update -qq
    echo "Update Server"
else
    sudo $PACKAGE_MANAGER update -y -q
    echo "Update Server"
fi

install_package() {
    package=$1
    if ! command -v $package &> /dev/null; then
        echo -n "Installing $package..."
        if sudo $PACKAGE_MANAGER install $package -y -qq; then
            echo -e "✅"
        else
            echo -e " \e[31m✘\e[0m"
            exit 1
        fi
    else
        echo "$package is already installed ✅"
    fi
}

install_package dialog
install_package whiptail
install_package jq
install_package lsof
install_package tar 
install_package wget

if ! grep -q "alias relay='bash -c \"/opt/hiddify-relay/menu.sh\"'" ~/.bashrc; then
    echo "alias relay='bash -c \"/opt/hiddify-relay/menu.sh\"'" >> ~/.bashrc
    echo "Alias added to .bashrc"
    source ~/.bashrc
else
    echo "Alias already exists in .bashrc"
    source ~/.bashrc
fi

sleep 5
clear


git clone -b beta https://github.com/hiddify/hiddify-relay  /opt/hiddify-relay

cd /opt/hiddify-relay
chmod +x menu.sh
./menu.sh
