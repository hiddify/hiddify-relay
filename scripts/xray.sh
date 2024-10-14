source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh

install_xray() {
    if systemctl is-active --quiet xray; then
        if ! (whiptail --title "Confirm Installation" --yesno "Xray service is already active. Do you want to reinstall?" 8 60); then
            whiptail --title "Installation Cancelled" --msgbox "Installation cancelled. Xray service remains active." 8 60
            return
        fi
    fi

    bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>&1 | dialog --title "Xray Installation" --progressbox 30 120

    whiptail --title "Xray Installation" --msgbox "Xray installation completed!" 8 60

    address=$(whiptail --inputbox "Enter your domain or IP:" 8 60 --title "Address Input" 3>&1 1>&2 2>&3)
    while : ; do
        port=$(whiptail --inputbox "Enter the port (numeric only 1-65535):" 8 60 --title "Port Input" 3>&1 1>&2 2>&3)
        if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
        fi
    done

    wget -q -O /tmp/config.json "$repository_url"/config/config.json

    jq --arg address "$address" --arg port "$port" '.inbounds[1].port = ($port | tonumber) | .inbounds[1].settings.address = $address | .inbounds[1].settings.port = ($port | tonumber) | .inbounds[1].tag = "inbound-" + $port' /tmp/config.json > /usr/local/etc/xray/config.json
    clear
    sudo systemctl restart xray
    status=$(sudo systemctl is-active xray)

    if [ "$status" = "active" ]; then
        whiptail --title "Install Xray" --msgbox "Xray installed successfully!" 8 60
    else
        whiptail --title "Install Xray" --msgbox "Xray service is not active or failed." 8 60
    fi

    rm /tmp/config.json
}

check_service_xray() {
    xray_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep xray | awk '{print $9}')

    status=$(sudo systemctl is-active xray)
    service_status="Xray Service Status: $status"

    info="Service Status and Ports in Use:\n\nPorts in use:\n$xray_ports\n\n$service_status"

    whiptail --title "Xray Service Status and Ports" --msgbox "$info" 15 70

}

trafficstat() {
    if ! systemctl is-active --quiet xray; then
    whiptail --title "Install Xray" --msgbox "xray service is not active.\nPlease start xray before check traffic." 8 60
        return
    fi
    
    local RESET=$1
    local APISERVER="127.0.0.1:10085"
    local XRAY="/usr/local/bin/xray"
    local ARGS=""
    
    if [[ "$RESET" == "reset" ]]; then
        ARGS="reset: true"
    fi

    local DATA=$($XRAY api statsquery --server="$APISERVER" "$ARGS" | awk '
    {
        if (match($1, /"name":/)) {
            f=1; gsub(/^"|link"|,$/, "", $2);
            split($2, p,  ">>>");
            printf "%s:%s->%s\t", p[1], p[2], p[4];
        } else if (match($1, /"value":/) && f) {
            f=0;
            gsub(/"/, "", $2);
            printf "%.0f\n\n", $2;
        } else if (match($0, /}/) && f) {
            f=0; 
            print 0;
        }
    }')

    local PREFIX="inbound"
    local SORTED=$(echo "$DATA" | grep "^${PREFIX}" | grep -v "inbound:api" | sort -r)
    local TOTAL_UP=0
    local TOTAL_DOWN=0

    while IFS= read -r LINE; do
        if [[ "$LINE" == *"->up"* ]]; then
            SIZE=$(echo "$LINE" | awk '{print $2}')
            TOTAL_UP=$((TOTAL_UP + SIZE))
        elif [[ "$LINE" == *"->down"* ]]; then
            SIZE=$(echo "$LINE" | awk '{print $2}')
            TOTAL_DOWN=$((TOTAL_DOWN + SIZE))
        fi
    done <<< "$SORTED"

    local OUTPUT=$(echo -e "${SORTED}\n" | numfmt --field=2 --suffix=B --to=iec | column -t)
    local TOTAL_UP_FMT=$(numfmt --to=iec <<< $TOTAL_UP)
    local TOTAL_DOWN_FMT=$(numfmt --to=iec <<< $TOTAL_DOWN)

    whiptail --msgbox "Inbound Traffic Statistics:\n\n${OUTPUT}\nTotal Up: ${TOTAL_UP_FMT}\nTotal Down: ${TOTAL_DOWN_FMT}" 20 80
}

add_another_inbound() {
    if ! systemctl is-active --quiet xray; then
    whiptail --title "Install Xray" --msgbox "xray service is not active.\nPlease start xray before adding new configuration." 8 60
        return
    fi
    addressnew=$(whiptail --inputbox "Enter the new address:" 8 60 --title "Address Input" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status != 0 ]; then
        whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
        return
    fi

    while : ; do
        portnew=$(whiptail --inputbox "Enter the new port (numeric only):" 8 60 --title "Port Input" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status != 0 ]; then
            whiptail --title "Cancelled" --msgbox "Operation cancelled. Returning to menu." 8 60
            return
        fi
        
        if ! [[ "$portnew" =~ ^[0-9]+$ ]] || ! (( portnew >= 1 && portnew <= 65535 )); then
            whiptail --title "Invalid Input" --msgbox "Port must be a numeric value between 1 and 65535. Please try again." 8 60
            continue
        fi

        if jq --arg port "$portnew" '.inbounds[] | select(.port == ($port | tonumber))' /usr/local/etc/xray/config.json | grep -q .; then
            whiptail --title "Port In Use" --msgbox "The port $portnew is already in use. Please enter a different port." 8 60
        else
            break
        fi
    done

    if jq --arg address "$addressnew" --arg port "$portnew" '.inbounds += [{ "listen": null, "port": ($port | tonumber), "protocol": "dokodemo-door", "settings": { "address": $address, "followRedirect": false, "network": "tcp,udp", "port": ($port | tonumber) }, "tag": ("inbound-" + $port) }]' /usr/local/etc/xray/config.json > /tmp/config.json.tmp; then
        sudo mv /tmp/config.json.tmp /usr/local/etc/xray/config.json
        sudo systemctl restart xray
        whiptail --title "Install Xray" --msgbox "Additional inbound added." 8 60
    else
        whiptail --title "Install Xray" --msgbox "Error: Failed to add inbound configuration." 8 60
    fi
}

remove_inbound() {
    inbounds=$(jq -r '.inbounds[] | select(.tag != "api") | "\(.tag):\(.port)"' /usr/local/etc/xray/config.json)
    
    if [ -z "$inbounds" ]; then
        whiptail --title "Remove Inbound" --msgbox "No inbound configurations found." 8 60
        return
    fi
    
    selected=$(whiptail --title "Remove Inbound" --menu "Select the inbound configuration to remove:" 20 60 10 \
    $(echo "$inbounds" | awk -F ':' '{print $1}' | nl -w2 -s ' ') 3>&1 1>&2 2>&3)

    if [ -n "$selected" ]; then
        port=$(echo "$inbounds" | sed -n "${selected}p" | awk -F ':' '{print $2}')
        
        # Confirm removal
        whiptail --title "Confirm Removal" --yesno "Are you sure you want to remove the inbound configuration for port $port?" 8 60
        response=$?
        if [ $response -eq 0 ]; then
            remove_inbound_by_port "$port"
        else
            whiptail --title "Remove Inbound" --msgbox "Inbound configuration removal canceled." 8 60
        fi
    fi
}

remove_inbound_by_port() {
    port=$1
    if jq --arg port "$port" 'del(.inbounds[] | select(.port == ($port | tonumber)))' /usr/local/etc/xray/config.json > /tmp/config.json.tmp; then
        sudo mv /tmp/config.json.tmp /usr/local/etc/xray/config.json
        sudo systemctl restart xray
        if grep -q "\"port\": $port" /usr/local/etc/xray/config.json; then
            whiptail --title "Remove Inbound" --msgbox "Failed to remove inbound configuration." 8 60
        else
            whiptail --title "Remove Inbound" --msgbox "Inbound configuration removed successfully!" 8 60
        fi
    else
        whiptail --title "Remove Inbound" --msgbox "Failed to remove inbound configuration." 8 60
    fi
}

uninstall_xray() {
    if whiptail --title "Confirm Uninstallation" --yesno "Are you sure you want to uninstall Xray?" 8 60; then
        (
        echo "10" "Removing Xray configuration..."
        sudo rm /usr/local/etc/xray/config.json > /dev/null 2>&1
        sleep 1
        echo "30" "Stopping and disabling Xray service..."
        sudo systemctl stop xray && sudo systemctl disable xray > /dev/null 2>&1
        sleep 1
        echo "70" "Uninstalling Xray..."
        sudo bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove > /dev/null 2>&1
        sleep 1
        echo "100" "Xray Uninstallation completed!"
        sleep 1
        ) | dialog --title "Xray Uninstallation" --gauge "Xray Uninstallation in progress..." 10 100 0
        whiptail --title "Xray Uninstallation" --msgbox "Xray Uninstallation completed!" 8 60
        clear
    else
        whiptail --title "Xray Uninstallation" --msgbox "Uninstallation cancelled." 8 60
        clear
    fi
}