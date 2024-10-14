source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh

install_wstunnel() {
    {
    echo "20"
    wget "https://github.com/erebe/wstunnel/releases/download/v5.0/wstunnel-linux-x64" > /dev/null 2>&1
    sleep 1
    echo "40"
    sudo chmod +x wstunnel-linux-x64 > /dev/null 2>&1
    sleep 1
    echo "60"
    sudo mv wstunnel-linux-x64 /bin/wstunnel > /dev/null 2>&1
    sleep 1
    echo "80"
    sudo rm /etc/systemd/system/wstunnel.service > /dev/null 2>&1
    sleep 1
    echo "90"
    wget -O /etc/systemd/system/wstunnel.service "$repository_url"/config/wstunnels.service > /dev/null 2>&1
    sleep 1
    } | dialog --title "Wstunnel Installation" --gauge "Installing Wstunnel..." 10 60
    whiptail --title "wstunnel Installation" --msgbox "wstunnel installation completed." 8 60
    clear
    # mport=$(whiptail --inputbox "Enter the port use for traffic(like 443 or any port):" 8 60 --title "Enter IP" 3>&1 1>&2 2>&3)
    # port=$(whiptail --inputbox "Enter the port used for wstunnel:" 8 60 --title "Enter wstunnel port" 3>&1 1>&2 2>&3)
    while : ; do
        mport=$(whiptail --inputbox "Enter the port use for traffic like 443(1-65535):" 8 60 --title "Main-Server Port Input" 3>&1 1>&2 2>&3)
        if [[ "$mport" =~ ^[0-9]+$ && "$mport" -ge 1 && "$mport" -le 65535 ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
        fi
    done
    domain=$(whiptail --inputbox "Enter the Main-Server domain or IP:" 8 60 --title "Enter your domain or IP" 3>&1 1>&2 2>&3)
    while : ; do
        port=$(whiptail --inputbox "Enter the wstunnel port number (1-65535):" 8 60 --title "wstunnel Port Input" 3>&1 1>&2 2>&3)
        if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
        fi
    done

    sudo sed -i "s/\$mport/$mport/g; s/\$domain/$domain/g; s/\$port/$port/g" /etc/systemd/system/wstunnel.service > /dev/null 2>&1

    sudo systemctl daemon-reload > /dev/null 2>&1
    sudo systemctl enable wstunnel.service > /dev/null 2>&1
    sudo systemctl start wstunnel.service > /dev/null 2>&1
    clear
    whiptail --title "wstunnel Installation" --msgbox "Now make ssh to main server for setup wstunnel." 8 60

    main_server_ip=$(whiptail --inputbox "Enter the IP of the main server:" 8 60 --title "Enter the main server IP" 3>&1 1>&2 2>&3)
    ssh_user=$(whiptail --inputbox "Enter the user of the main server:" 8 60 --title "Enter the user" 3>&1 1>&2 2>&3)
    main_server_port=$(whiptail --inputbox "Enter the SSH port of the main server (press Enter for default 22): " 8 60 --title "Enter the SSH port" 3>&1 1>&2 2>&3)
    main_server_port=${main_server_port:-22}

    while : ; do
        port=$(whiptail --inputbox "Enter the wstunnel port number (1-65535):" 8 60 --title "wstunnel Port Input" 3>&1 1>&2 2>&3)
        if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
        fi
    done

    wget -O wstunnelm.service "$repository_url"/config/wstunnelm.service > /dev/null 2>&1
    sed -i "s/\$port/$port/g" wstunnelm.service
    clear
    scp -P $main_server_port wstunnelm.service $ssh_user@$main_server_ip:/tmp/wstunnelm.service
    clear
    whiptail --title "wstunnel Installation" --msgbox "The service file sent to main server." 8 60
    whiptail --title "wstunnel Installation" --msgbox "once again type main server Password:" 8 60
    ssh -p $main_server_port $ssh_user@$main_server_ip << 'ENDSSH'
    sudo mv /tmp/wstunnelm.service /etc/systemd/system/wstunnel.service
    wget "https://github.com/erebe/wstunnel/releases/download/v5.0/wstunnel-linux-x64"
    sudo chmod +x wstunnel-linux-x64
    sudo mv wstunnel-linux-x64 /bin/wstunnel
    sudo systemctl daemon-reload
    sudo systemctl enable wstunnel.service
    sudo systemctl start wstunnel.service
ENDSSH

    clear
    status=$(sudo systemctl is-active wstunnel.service)
    if [ "$status" = "active" ]; then
        whiptail --title "Wstunnel Installation" --msgbox "Wstunnel tunnel is installed and $status." 8 60
    else
        whiptail --title "Wstunnel Installation" --msgbox "Wstunnel service is not active or $status." 8 60
    fi
}

check_wstunnel_port() {
    wstunnel_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep wstunnel | awk '{print $9}')
    status=$(sudo systemctl is-active wstunnel)
    service_status="wstunnel Service Status: $status"
    info="Service Status and Ports in Use:\n\nPorts in use:\n$wstunnel_ports\n\n$service_status"
    whiptail --title "wstunnel Service Status and Ports" --msgbox "$info" 15 70
}

uninstall_wstunnel() {
    (
    echo "10" "Stopping wstunnel service..."
    sudo systemctl stop wstunnel.service > /dev/null 2>&1
    sleep 1
    echo "30" "Disabling wstunnel service..."
    sudo systemctl disable wstunnel.service > /dev/null 2>&1
    sleep 1
    echo "70" "Uninstalling wstunnel..."
    sudo rm -f /etc/systemd/system/wstunnel.service /bin/wstunnel
    sleep 1
    echo "100" "wstunnel Uninstallation completed!"
    sleep 1
    ) | dialog --title "wstunnel Uninstallation" --gauge "wstunnel Uninstallation in progress..." 10 100 0
    whiptail --title "wstunnel Uninstallation" --msgbox "wstunnel Uninstallation completed!" 8 60
    clear
    whiptail --title "wstunnel Uninstallation" --msgbox "Use ssh to uninstall Wstunnel form main server" 8 60

    main_server_ip=$(whiptail --inputbox "Enter the IP of the main server:" 8 60 --title "Enter the main server IP" 3>&1 1>&2 2>&3)
    ssh_user=$(whiptail --inputbox "Enter the user of the main server:" 8 60 --title "Enter the user" 3>&1 1>&2 2>&3)
    main_server_port=$(whiptail --inputbox "Enter the SSH port of the main server (press Enter for default 22): " 8 60 --title "Enter the SSH port" 3>&1 1>&2 2>&3)
    main_server_port=${main_server_port:-22}

    # SSH to the main server and execute commands
    ssh -p $main_server_port $ssh_user@$main_server_ip bash -s << 'ENDSSH'
    sudo systemctl stop wstunnel.service
    sudo systemctl disable wstunnel.service
    sudo rm -f /etc/systemd/system/wstunnel.service /bin/wstunnel
ENDSSH
    clear
    whiptail --title "wstunnel Uninstallation" --msgbox "Wstunnel Service Uninstalled." 8 60
}