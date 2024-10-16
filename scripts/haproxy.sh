source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh

install_haproxy() {
    if systemctl is-active --quiet haproxy; then
        if ! (whiptail --title "Confirm Installation" --yesno "HAProxy service is already active. Do you want to reinstall?" 8 60); then
            whiptail --title "Installation Cancelled" --msgbox "Installation cancelled. HAProxy service remains active." 8 60
            return
        fi
    fi

    {
        echo "10" "Installing HAProxy..."
        sudo $PACKAGE_MANAGER install haproxy -y > /dev/null 2>&1
        sleep 1
        echo "30" "Downloading haproxy.cfg..."
        wget -q -O /tmp/haproxy.cfg "$repository_url"/config/haproxy.cfg > /dev/null 2>&1
        sleep 1
        echo "50" "Removing existing haproxy.cfg..."
        sudo rm /etc/haproxy/haproxy.cfg > /dev/null 2>&1
        sleep 1
        echo "70" "Moving new haproxy.cfg to /etc/haproxy..."
        sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
        sleep 1
    } | dialog --title "HAProxy Installation" --gauge "Installing HAProxy..." 10 60 0

    whiptail --title "HAProxy Installation" --msgbox "HAProxy installation completed." 8 60

    while true; do
        target_iport=$(whiptail --inputbox "Enter Relay-Server Free Port (1-65535):" 8 60 --title "HAProxy Installation" 3>&1 1>&2 2>&3)
        if [[ "$target_iport" =~ ^[0-9]+$ ]] && [ "$target_iport" -ge 1 ] && [ "$target_iport" -le 65535 ]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Please enter a valid numeric port between 1 and 65535." 8 60
        fi
    done

    target_ip=$(whiptail --inputbox "Enter Main-Server IP or Domain:" 8 60 --title "HAProxy Installation" 3>&1 1>&2 2>&3)

    while true; do
        target_port=$(whiptail --inputbox "Enter Main-Server Port (1-65535):" 8 60 --title "HAProxy Installation" 3>&1 1>&2 2>&3)
        if [[ "$target_port" =~ ^[0-9]+$ ]] && [ "$target_port" -ge 1 ] && [ "$target_port" -le 65535 ]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Please enter a valid numeric port between 1 and 65535." 8 60
        fi
    done

    if [[ -n "$target_ip" ]]; then
        sudo sed -i "s/\$iport/$target_iport/g; s/\$IP/$target_ip/g; s/\$port/$target_port/g" /etc/haproxy/haproxy.cfg > /dev/null 2>&1
        sudo systemctl restart haproxy > /dev/null 2>&1

        status=$(sudo systemctl is-active haproxy)
        if [ "$status" = "active" ]; then
            whiptail --title "HAProxy Installation" --msgbox "HAProxy tunnel is installed and active." 8 60
        else
            whiptail --title "HAProxy Installation" --msgbox "HAProxy service is not active. Status: $status." 8 60
        fi
    else
        whiptail --title "HAProxy Installation" --msgbox "Invalid IP input. Please ensure the field is filled correctly." 8 60
    fi
}

check_haproxy() {
    haproxy_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep haproxy | awk '{print $9}')
    status=$(sudo systemctl is-active haproxy)
    service_status="haproxy Service Status: $status"
    info="Service Status and Ports in Use:\n\nPorts in use:\n$haproxy_ports\n\n$service_status"
    whiptail --title "haproxy Service Status and Ports" --msgbox "$info" 15 70
}

add_frontend_backend() {

    if ! systemctl is-active --quiet haproxy; then
        whiptail --title "HAProxy Not Active" --msgbox "HAProxy service is not active.\nPlease start HAProxy before adding new configuration." 8 60
        return
    fi

    while true; do
        frontend_port=$(whiptail --inputbox "Enter Relay-Server Free Port (1-65535):" 8 60 --title "HAProxy Installation" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status != 0 ]; then
            whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
            return
        fi
        
        if [[ "$frontend_port" =~ ^[0-9]+$ ]] && [ "$frontend_port" -ge 1 ] && [ "$frontend_port" -le 65535 ]; then
            if grep -q "frontend tunnel-$frontend_port" /etc/haproxy/haproxy.cfg; then
                whiptail --title "Port Already Used" --msgbox "Port $frontend_port is already in use. Please choose another port." 8 60
            else
                break
            fi
        else
            whiptail --title "Invalid Input" --msgbox "Please enter a valid numeric port between 1 and 65535." 8 60
        fi
    done

    backend_ip=$(whiptail --inputbox "Enter Main-Server IP or Domain:" 8 60 --title "Add Frontend/Backend" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status != 0 ]; then
        whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
        return
    fi

    while true; do
        backend_port=$(whiptail --inputbox "Enter Main-Server Port (1-65535):" 8 60 --title "HAProxy Installation" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status != 0 ]; then
            whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
            return
        fi
        
        if [[ "$backend_port" =~ ^[0-9]+$ ]] && [ "$backend_port" -ge 1 ] && [ "$backend_port" -le 65535 ]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Please enter a valid numeric port between 1 and 65535." 8 60
        fi
    done

    {
        echo ""
        echo "frontend tunnel-$frontend_port"
        echo "    bind :::$frontend_port"
        echo "    mode tcp"
        echo "    default_backend tunnel-$backend_port"
        echo ""
        echo "backend tunnel-$backend_port"
        echo "    mode tcp"
        echo "    server target_server $backend_ip:$backend_port"
    } | sudo tee -a /etc/haproxy/haproxy.cfg > /dev/null

    sudo systemctl restart haproxy > /dev/null 2>&1

    whiptail --title "Frontend/Backend Added" --msgbox "New frontend and backend added successfully.\n\nFrontend: tunnel-$frontend_port\nBackend: tunnel-$backend_port" 10 60
}

remove_frontend_backend() {
    
    frontends=$(grep -E '^frontend ' /etc/haproxy/haproxy.cfg | awk '{print $2}')
    
    
    options=""
    for frontend in $frontends; do
        default_backend=$(grep -E "^frontend $frontend$" /etc/haproxy/haproxy.cfg -A 10 | grep 'default_backend' | awk '{print $2}')
        options+="$frontend \"$default_backend\" "
    done

    
    selected=$(whiptail --menu "Select Frontend to Remove" 20 60 10 $options 3>&1 1>&2 2>&3)

    if [[ -n "$selected" ]]; then
        frontend_name=$selected
        backend_name=$(grep -E "^frontend $frontend_name$" /etc/haproxy/haproxy.cfg -A 10 | grep 'default_backend' | awk '{print $2}')

        
        if [[ -n "$backend_name" ]]; then
            
            sudo sed -i "/^frontend $frontend_name$/,/^$/d" /etc/haproxy/haproxy.cfg

            
            sudo sed -i "/^backend $backend_name$/,/^$/d" /etc/haproxy/haproxy.cfg

            
            sudo systemctl restart haproxy > /dev/null 2>&1

            
            whiptail --title "Frontend/Backend Removed" --msgbox "Frontend '$frontend_name' and Backend '$backend_name' removed successfully." 8 60
        else
            
            whiptail --title "Error" --msgbox "Could not find the default backend for frontend '$frontend_name'." 8 60
        fi
    else
        
        whiptail --title "Cancelled" --msgbox "No frontend selected. Operation cancelled." 8 60
    fi
}

uninstall_haproxy() {
    if (whiptail --title "Confirm Uninstallation" --yesno "Are you sure you want to uninstall HAProxy?" 8 60); then
        {
            echo "20" "Stopping HAProxy service..."
            sudo systemctl stop haproxy > /dev/null 2>&1
            sleep 1
            echo "40" "Disabling HAProxy service..."
            sudo systemctl disable haproxy > /dev/null 2>&1
            sleep 1
            echo "60" "Removing HAProxy..."
            sudo $PACKAGE_MANAGER remove haproxy -y > /dev/null 2>&1
            sleep 1
        } | dialog --title "HAProxy Uninstallation" --gauge "Uninstalling HAProxy..." 10 60 0

        whiptail --title "HAProxy Uninstallation" --msgbox "HAProxy Uninstalled." 8 60
        clear
    else
        whiptail --title "HAProxy Uninstallation" --msgbox "Uninstallation cancelled." 8 60
        clear
    fi
}