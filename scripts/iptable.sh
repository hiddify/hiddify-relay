source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh

install_iptables() {
    IP=$(whiptail --inputbox "Enter your main server IP like (1.1.1.1):" 8 60 3>&1 1>&2 2>&3)
    TCP_PORTS=$(whiptail --inputbox "Enter ports separated by commas (e.g., 80,443):" 8 60 80,443 3>&1 1>&2 2>&3)

    {
        echo "10" "Installing iptables..."
        sudo $PACKAGE_MANAGER install iptables -y > /dev/null 2>&1
        echo "30" "Enabling net.ipv4.ip_forward..."
        sudo sysctl net.ipv4.ip_forward=1 > /dev/null 2>&1
        echo "50" "Configuring iptables rules for TCP..."
        sudo iptables -t nat -A POSTROUTING -p tcp --match multiport --dports $TCP_PORTS -j MASQUERADE > /dev/null 2>&1
        echo "60" "Configuring iptables rules for TCP DNAT..."
        sudo iptables -t nat -A PREROUTING -p tcp --match multiport --dports $TCP_PORTS -j DNAT --to-destination $IP > /dev/null 2>&1
        echo "75" "Configuring iptables rules for UDP..."
        sudo iptables -t nat -A POSTROUTING -p udp --match multiport --dports $TCP_PORTS -j MASQUERADE > /dev/null 2>&1
        echo "85" "Configuring iptables rules for UDP DNAT..."
        sudo iptables -t nat -A PREROUTING -p udp --match multiport --dports $TCP_PORTS -j DNAT --to-destination $IP > /dev/null 2>&1
        echo "95" "Creating /etc/iptables/..."
        sudo mkdir -p /etc/iptables/ > /dev/null 2>&1
        sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
        echo "100" "Starting iptables service..."
        sudo systemctl start iptables
    } | dialog --title "IPTables Installation" --gauge "Installing IPTables..." 10 100 0
    clear
    whiptail --title "IPTables Installation" --msgbox "IPTables installation completed." 8 60
}

check_port_iptables() {
    ip_ports=$(iptables-save | awk '/-A (PREROUTING|POSTROUTING)/ && /-p tcp -m multiport --dports/ {split($0, parts, "--to-destination "); split(parts[2], dest_port, "[:]"); split(parts[1], src_port, " --dports "); split(src_port[2], port_list, ","); for (i in port_list) { if(dest_port[1] != "") { if (index(port_list[i], " ")) { split(port_list[i], split_port, " "); print dest_port[1], split_port[1] } else print dest_port[1], port_list[i] }}}'
)
    status=$(sudo systemctl is-active iptables)
    service_status="iptables Service Status: $status"
    info="Service Status and Ports in Use:\n$ip_ports\n\n$service_status"
    whiptail --title "iptables Service Status and Ports" --msgbox "$info" 15 70
}

uninstall_iptables() {
    if whiptail --title "Confirm Uninstallation" --yesno "Are you sure you want to uninstall IPTables?" 8 60; then
        {
            echo "10" ; echo "Flushing iptables rules..."
            sudo iptables -F > /dev/null 2>&1
            sleep 1
            echo "20" ; echo "Deleting all user-defined chains..."
            sudo iptables -X > /dev/null 2>&1
            sleep 1
            echo "40" ; echo "Flushing NAT table..."
            sudo iptables -t nat -F > /dev/null 2>&1
            sleep 1
            echo "50" ; echo "Deleting user-defined chains in NAT table..."
            sudo iptables -t nat -X > /dev/null 2>&1
            sleep 1
            echo "70" ; echo "Removing /etc/iptables/rules.v4..."
            sudo rm /etc/iptables/rules.v4 > /dev/null 2>&1
            sleep 1
            echo "80" ; echo "Stopping iptables service..."
            sudo systemctl stop iptables > /dev/null 2>&1
            sleep 1
            echo "100" ; echo "IPTables Uninstallation completed!"
        } | whiptail --gauge "Uninstalling IPTables..." 10 70 0
        clear
        whiptail --title "IPTables Uninstallation" --msgbox "IPTables Uninstalled." 8 60
    else
        whiptail --title "IPTables Uninstallation" --msgbox "Uninstallation cancelled." 8 60
        clear
    fi
}