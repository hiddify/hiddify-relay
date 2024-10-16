#!/bin/bash

if [ -f /etc/redhat-release ]; then
    if grep -q "Rocky" /etc/redhat-release; then
        OS="Rocky"
    elif grep -q "AlmaLinux" /etc/redhat-release; then
        OS="AlmaLinux"
    else
        OS="CentOS"
    fi
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu)
            OS="Ubuntu"
            ;;
        debian)
            OS="Debian"
            ;;
        fedora)
            OS="Fedora"
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

case "$OS" in
    "Ubuntu"|"Debian")
        PACKAGE_MANAGER="apt"
        SERVICE_MANAGER="systemctl"
        ;;
    "Rocky"|"AlmaLinux")
        PACKAGE_MANAGER="dnf"
        SERVICE_MANAGER="systemctl"
        ;;
    "CentOS")
        PACKAGE_MANAGER="yum"
        SERVICE_MANAGER="systemctl"
        ;;
    "Fedora")
        PACKAGE_MANAGER="dnf"
        SERVICE_MANAGER="systemctl"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac
