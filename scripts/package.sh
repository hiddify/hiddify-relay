detect_os_and_managers() {
    OS=$1

    # Detect the package manager and service manager based on the OS
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

    # Export these variables to be available in the rest of the script
    export PACKAGE_MANAGER
    export SERVICE_MANAGER
}
