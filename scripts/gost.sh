source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh
install_gost() {
    if systemctl is-active --quiet gost; then
        if ! (whiptail --title "Confirm Installation" --yesno "GOST service is already installed. Do you want to reinstall?" 8 60); then
            whiptail --title "Installation Cancelled" --msgbox "Installation cancelled. GOST service remains installed." 8 60
            return
        fi
    fi

    {
        echo "10"
        curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh | bash -s -- --install > /dev/null 2>&1
        echo "50"
        sudo wget -q -O /usr/lib/systemd/system/gost.service "$repository_url"/config/gost.service > /dev/null 2>&1
        sleep 1
        echo "70"
    } | dialog --title "GOST Installation" --gauge "Installing GOST..." 10 60

    domain=$(whiptail --inputbox "Enter your domain or IP:" 8 60 --title "GOST Installation" 3>&1 1>&2 2>&3)
    while : ; do
        port=$(whiptail --inputbox "Enter the port number (1-65535):" 8 60 --title "Port Input" 3>&1 1>&2 2>&3)
        if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
        fi
    done

    {
        echo "80"
        sudo sed -i "s|ExecStart=/usr/local/bin/gost -L=tcp://:\$port/\$domain:\$port|ExecStart=/usr/local/bin/gost -L=tcp://:$port/$domain:$port|g" /usr/lib/systemd/system/gost.service > /dev/null 2>&1
        sudo systemctl daemon-reload > /dev/null 2>&1
        sudo systemctl start gost > /dev/null 2>&1
        sudo systemctl enable gost > /dev/null 2>&1
        echo "100"
        sleep 1
    } | dialog --title "GOST Configuration" --gauge "Configuring GOST service..." 10 60

    status=$(sudo systemctl is-active gost)

    if [ "$status" = "active" ]; then
        whiptail --title "GOST Service Status" --msgbox "GOST tunnel is installed and active." 8 60
    else
        whiptail --title "GOST Installation" --msgbox "GOST service is not active. Status: $status." 8 60
    fi
    clear
}

check_port_gost() {
    gost_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep gost | awk '{print $9}')
    status=$(sudo systemctl is-active gost)
    service_status="gost Service Status: $status"
    info="Service Status and Ports in Use:\n\nPorts in use:\n$gost_ports\n\n$service_status"
    whiptail --title "gost Service Status and Ports" --msgbox "$info" 15 70
}

add_port_gost() {
    if ! systemctl is-active --quiet gost; then
        whiptail --title "GOST Not Active" --msgbox "GOST service is not active.\nPlease start GOST before adding new configuration." 8 60
        return
    fi

    last_port=$(sudo lsof -i -P -n -sTCP:LISTEN | grep gost | awk '{print $9}' | awk -F ':' '{print $NF}' | sort -n | tail -n 1)

    new_domain=$(whiptail --inputbox "Enter your domain or IP:" 8 60  --title "GOST Installation" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status != 0 ]; then
        whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
        return
    fi

    while : ; do
        new_port=$(whiptail --inputbox "Enter the port (numeric only):" 8 60 --title "Port Input" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status != 0 ]; then
            whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
            return
        fi
        
        if [[ "$new_port" =~ ^[0-9]+$ ]]; then
            if (( new_port >= 0 && new_port <= 65535 )); then
                if sudo lsof -i -P -n -sTCP:LISTEN | grep ":$new_port " > /dev/null 2>&1; then
                    whiptail --title "Port Already in Use" --msgbox "Port $new_port is already in use. Please choose another port." 8 60
                else
                    break
                fi
            else
                whiptail --title "Invalid Port Number" --msgbox "Port number must be between 1 and 65535. Please try again." 8 60
            fi
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value. Please try again." 8 60
        fi
    done

    sudo sed -i "/ExecStart/s/$/ -L=tcp:\/\/:$new_port\/$new_domain:$new_port/" /usr/lib/systemd/system/gost.service > /dev/null 2>&1
    sudo systemctl daemon-reload > /dev/null 2>&1
    sudo systemctl restart gost > /dev/null 2>&1
    whiptail --title "GOST configuration" --msgbox "New domain and port added." 8 60
}

remove_port_gost() {
    ports=$(grep -oP '(?<=-L=tcp://:)\d+(?=/)' /usr/lib/systemd/system/gost.service)

    if [ -z "$ports" ]; then
        whiptail --title "Remove Port" --msgbox "No ports found in the GOST configuration." 8 60
        return
    fi

    port_list=()
    for port in $ports; do
        port_list+=("$port" "")
    done

    selected_port=$(whiptail --title "Remove Port" --menu "Choose the port to remove:" 15 60 5 "${port_list[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_port" ]; then
        whiptail --title "Remove Port" --msgbox "No port selected. No changes made." 8 60
        return
    fi

    line=$(grep -oP "ExecStart=.*-L=tcp://:$selected_port/[^ ]+" /usr/lib/systemd/system/gost.service)
    domain=$(echo "$line" | grep -oP "(?<=-L=tcp://:$selected_port/).+")

    if whiptail --title "Confirm Removal" --yesno "Are you sure you want to remove the port $selected_port with domain/IP $domain?" 8 60; then
        sudo sed -i "\|ExecStart=.*-L=tcp://:$selected_port/$domain|s| -L=tcp://:$selected_port/$domain||" /usr/lib/systemd/system/gost.service

        {
            echo "50"
            sudo systemctl daemon-reload > /dev/null 2>&1
            sudo systemctl restart gost > /dev/null 2>&1
            echo "100"
        } | dialog --title "GOST Configuration" --gauge "Removing port $selected_port from GOST service..." 10 60

        whiptail --title "Remove Port" --msgbox "Port $selected_port with domain/IP $domain has been removed from the GOST configuration." 8 60
    else
        whiptail --title "Remove Port" --msgbox "No changes made." 8 60
    fi
}

uninstall_gost() {
    if whiptail --title "Confirm Uninstallation" --yesno "Are you sure you want to uninstall GOST?" 8 60; then
        {
            echo "20" "Stopping GOST service..."
            sudo systemctl stop gost > /dev/null 2>&1
            sleep 1
            echo "40" "Disabling GOST service..."
            sudo systemctl disable gost > /dev/null 2>&1
            sleep 1
            echo "60" "Reloading systemctl daemon..."
            sudo systemctl daemon-reload > /dev/null 2>&1
            sleep 1
            echo "80" "Removing GOST service and binary..."
            sudo rm -f /usr/lib/systemd/system/gost.service /usr/local/bin/gost
            sleep 1
        } | dialog --title "GOST Uninstallation" --gauge "Uninstalling GOST..." 10 60 0
        clear
        whiptail --title "GOST Uninstallation" --msgbox "GOST Service Uninstalled." 8 60
    else
        whiptail --title "GOST Uninstallation" --msgbox "Uninstallation cancelled." 8 60
    fi
}