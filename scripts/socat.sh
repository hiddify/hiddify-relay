source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh

install_socat() {
    {
    echo "40" "Install Socat"
    sudo apt-get install socat -y > /dev/null 2>&1
    sleep 1
    echo "80" "Downloading Socat.service..."
    sudo wget -O /etc/systemd/system/socat.service "$repository_url"/config/socat-tunnel.service > /dev/null 2>&1
    sleep 1
    } | dialog --title "Socat Installation" --gauge "Installing Socat..." 10 60 0

    whiptail --title "Socat Installation" --msgbox "Socat installation completed." 8 60
    clear
    ip=$(whiptail --inputbox "Enter Main-Server IP:" 8 60 --title "Enter IP" 3>&1 1>&2 2>&3)
    while : ; do
        port=$(whiptail --inputbox "Enter the Main-Server number (1-65535):" 8 60 --title "Port Input" 3>&1 1>&2 2>&3)
        if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 0 && "$port" -le 65535 ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
        fi
    done

    sudo sed -i "s/\$ip/$ip/g" /etc/systemd/system/socat.service > /dev/null 2>&1
    sudo sed -i "s/\$port/$port/g" /etc/systemd/system/socat.service > /dev/null 2>&1

    sudo systemctl daemon-reload > /dev/null 2>&1
    sudo systemctl enable socat > /dev/null 2>&1
    sudo systemctl start socat > /dev/null 2>&1

    status=$(sudo systemctl is-active socat)
    if [ "$status" = "active" ]; then
        whiptail --title "Socat Installation" --msgbox "Socat tunnel is installed and $status." 8 60
    else
        whiptail --title "Socat Installation" --msgbox "Socat service is not active or $status." 8 60
    fi
}

check_socat_port() {
    socat_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep socat | awk '{print $9}')
    status=$(sudo systemctl is-active socat)
    service_status="socat Service Status: $status"
    info="Service Status and Ports in Use:\n\nPorts in use:\n$socat_ports\n\n$service_status"
    whiptail --title "Socat Service Status and Ports" --msgbox "$info" 15 70
    clear
}

uninstall_socat() {
    (
        sudo systemctl stop socat > /dev/null 2>&1 && echo "25" && sleep 1 &&
        sudo systemctl disable socat > /dev/null 2>&1 && echo "50" && sleep 1 &&
        sudo rm /etc/systemd/system/socat.service && echo "75" && sleep 1 && > /dev/null 2>&1
        sudo apt-get remove socat -y > /dev/null 2>&1 && echo "Socat tunnel Uninstalled."
    ) | dialog --title "Socat Uninstallation" --gauge "Uninstalling Socat..." 10 60
    whiptail --title "Socat Uninstallation" --msgbox "Socat tunnel Uninstalled." 8 60
    clear
}