#!/bin/bash

# Define partial functions
##############################
## Functions for iptables setup
install_iptables() {
    read -p 'Enter your main server IP like(1.1.1.1): ' IP
    echo "The main server IP is $IP"
    sudo apt install -y iptables iptables-persistent
    sudo sysctl net.ipv4.ip_forward=1
    sudo iptables -t nat -A POSTROUTING -p tcp --match multiport --dports 80,443 -j MASQUERADE
    sudo iptables -t nat -A PREROUTING -p tcp --match multiport --dports 80,443 -j DNAT --to-destination $IP
    sudo iptables -t nat -A POSTROUTING -p udp -j MASQUERADE
    sudo iptables -t nat -A PREROUTING -p udp -j DNAT --to-destination $IP

    sudo mkdir -p /etc/iptables/
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
    clear
    echo "---------------------------------------------------------------"
    echo -e "\e[32mIP-Tables configured\e[0m"
    echo "---------------------------------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

check_port_iptables() {
    echo "----------------- Ports in Use for iptables -------------------"
    sudo iptables -L -n -v
    echo "---------------------------------------------------------------"

    status=$(sudo systemctl is-active iptables)

    if [ "$status" = "active" ]; then
        echo "---------------iptables service status---------------------"
        echo -e "\e[32miptables Service Status: $status\e[0m"
        echo "--------------------------------------------"
    else
        echo "---------------iptables service status---------------------"
        echo -e "\e[31miptables Service Status: $status\e[0m"
        echo "-------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

uninstall_iptables() {
    sudo iptables -F
    sudo iptables -X
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    rm /etc/iptables/rules.v4
    echo "---------------------------------------------------------------"
    echo -e "\e[31mIP-Tables rules cleared\e[0m"
    echo "---------------------------------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

##########################
## Functions for GOST setup
install_gost() {

    # Install required packages
    sudo apt update

    # Download and install GOST
    wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz
    gunzip gost-linux-amd64-2.11.5.gz
    sudo mv gost-linux-amd64-2.11.5 /usr/local/bin/gost
    sudo chmod +x /usr/local/bin/gost
    clear

    # Download the gost.service file from GitHub
    sudo wget -O /usr/lib/systemd/system/gost.service https://raw.githubusercontent.com/hiddify/hiddify-relay/main/gost.service
    clear
    # Prompt user for port number and domain
    read -p "Enter port number: " port
    read -p "Enter domain: " domain

    # Modify the gost.service file with user input
    sudo sed -i "s|ExecStart=/usr/local/bin/gost -L=tcp://:\$port/\$domain:\$port|ExecStart=/usr/local/bin/gost -L=tcp://:$port/$domain:$port|g" /usr/lib/systemd/system/gost.service

    # Start and enable the GOST service
    sudo systemctl start gost
    sudo systemctl enable gost
    clear
    echo "-----------------------------------------"
    echo -e "\e[32mGost tunnel is installed and activated.\e[0m"
    echo "-----------------------------------------"
    status=$(sudo systemctl is-active gost)

    if [ "$status" = "active" ]; then
        echo "---------------GOST service status---------------------"
        echo -e "\e[32mGost tunnel is installed and $status.\e[0m"
        echo "--------------------------------------------"
    else
        echo "---------------GOST service status---------------------"
        echo -e "\e[31mGOST service is not active or failed.\e[0m"
        echo "-------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

check_port_gost() {
    # Check port in use
    echo "---------------------Port in use---------------------------"
    sudo lsof -i -P -n -sTCP:LISTEN | grep gost | awk '{print "TCP:", $9}'
    echo "-----------------------------------------------------------"
    # Check GOST service status
    status=$(sudo systemctl is-active gost)

    if [ "$status" = "active" ]; then
        echo "---------------GOST service status---------------------"
        echo -e "\e[32mGOST Service Status: $status\e[0m"
        echo "--------------------------------------------"
    else
        echo "---------------GOST service status---------------------"
        echo -e "\e[31mGOST Service Status: $status\e[0m"
        echo "-------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

add_port_gost() {
    # Find last used port for GOST
    last_port=$(sudo lsof -i -P -n -sTCP:LISTEN | grep gost | awk '{print $9}' | awk -F ':' '{print $NF}' | sort -n | tail -n 1)

    read -p "Enter new port: " new_port
    read -p "Enter new domain: " new_domain

    # Modify the GOST configuration file to add a new port and domain
    sudo sed -i "/ExecStart/s/$/ -L=tcp:\/\/:$new_port\/$new_domain:$new_port/" /usr/lib/systemd/system/gost.service

    # Restart the GOST service
    sudo systemctl daemon-reload
    sudo systemctl restart gost
    echo "-----------------------------------------"
    echo -e "\e[32mNew port and domain added\e[0m"
    echo "-----------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

uninstall_gost() {
    sudo systemctl stop gost
    sudo systemctl disable gost
    sudo systemctl daemon-reload
    sudo rm -f /usr/lib/systemd/system/gost.service /usr/local/bin/gost
    clear
    echo "-----------------------------------------"
    echo -e "\e[31mGost Service Uninstalled.\e[0m"
    echo "-----------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

##########################
## Functions for Xray setup
install_xray() {
    sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    clear
    echo "---------------------------------------------------------------"
    echo -e "\e[32mXray installed and now add inbound\e[0m"
    echo "---------------------------------------------------------------"
    echo -e "\e[1;32mEnter the address: \e[0m"
    read -e address
    echo -e "\e[1;32mEnter the port: \e[0m"
    read -e port

    inbound_config=$(cat <<EOF
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
      "listen": null,
      "port": $port,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "$address",
        "followRedirect": false,
        "network": "tcp,udp",
        "port": $port
      },
      "tag": "inbound-1"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF
)

    echo "$inbound_config" > /usr/local/etc/xray/config.json

    sudo systemctl restart xray
    status=$(sudo systemctl is-active xray)

    if [ "$status" = "active" ]; then
        echo "---------------Dokodemo-Door service status---------------------"
        echo -e "\e[32mXray tunnel is installed and $status.\e[0m"
        echo "----------------------------------------------------------------"
    else
        echo "---------------Dokodemo-Door service status---------------------"
        echo -e "\e[31mXray service is not active or failed.\e[0m"
        echo "----------------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."

}

check_service_xray() {
    # Check port in use
    echo "----------------- service status port in use--------------------"
    sudo lsof -i -P -n -sTCP:LISTEN | grep xray | awk '{print "TCP:", $9}'
    echo "---------------------------------------------------------------"
    # Check Xray service status
    status=$(sudo systemctl is-active xray)
    echo "----------------Dokodemo-Door service status--------------------"
    if [ "$status" = "active" ]; then
        echo -e "\e[32mXray Service Status: $status\e[0m"
    else
        echo -e "\e[31mXray Service Status: $status\e[0m"
    fi
    echo "---------------------------------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

add_another_inbound() {
    echo -e "\e[1;32mEnter the new address: \e[0m"
    read -e addressnew
    echo -e "\e[1;32mEnter the new port: \e[0m"
    read -e portnew

    position=$(grep -n -m 1 '"tag": "inbound-1"' /usr/local/etc/xray/config.json | cut -d ':' -f1)

    if [ -n "$position" ]; then
        position=$((position + 1))
        sed -i "${position}i \ \ \ \ },\n \ \ \ {\n \ \ \ \ \ \"listen\": null,\n \ \ \ \ \ \"port\": $portnew,\n \ \ \ \ \ \"protocol\": \"dokodemo-door\",\n \ \ \ \ \ \"settings\": {\n \ \ \ \ \ \ \ \"address\": \"$addressnew\",\n \ \ \ \ \ \ \ \"followRedirect\": false,\n \ \ \ \ \ \ \ \"network\": \"tcp,udp\",\n \ \ \ \ \ \ \ \"port\": $portnew\n \ \ \ \ \ },\n \ \ \ \ \ \"tag\": \"inbound-$portnew\"" /usr/local/etc/xray/config.json
        echo "---------------------------------------------------------------"
        echo "Additional inbound added."
        sudo systemctl restart xray
        echo "---------------------------------------------------------------"
    else
        echo "----------------------------------------------------------------"
        echo "Error: Could not find the position to add inbound configuration."
        echo "----------------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

uninstall_xray() {
    sudo rm /usr/local/etc/xray/config.json
    sudo systemctl stop xray && systemctl disable xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
    clear
    echo "---------------------------------------------------------------"
    echo -e "\e[31mXray Uninstalled\e[0m"
    echo "---------------------------------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

##############################
## Functions for HA-Proxy setup
install_haproxy() {
    # Check if HAProxy is installed
    if ! command -v haproxy &> /dev/null; then
        # If not installed, install HAProxy
        sudo apt-get install haproxy -y
    else
        echo "HAProxy is already installed."
    fi

    # Download haproxy.cfg from GitHub
    wget -O /tmp/haproxy.cfg "https://raw.githubusercontent.com/hiddify/hiddify-relay/main/haproxy.cfg"

    # Remove existing haproxy.cfg
    sudo rm /etc/haproxy/haproxy.cfg

    # Move downloaded haproxy.cfg to /etc/haproxy
    sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg

    # Replace $IP and $port in haproxy.cfg
    clear
    read -p "Enter Relay-Server Free Port: " target_iport
    read -p "Enter Main-Server IP: " target_ip
    read -p "Enter Main-Server Port: " target_port

    sudo sed -i "s/\$iport/$target_iport/g; s/\$IP/$target_ip/g; s/\$port/$target_port/g" /etc/haproxy/haproxy.cfg

    # Restart HA-Proxy
    echo "Restarting HA-Proxy..."
    sudo systemctl restart haproxy
    clear

    status=$(sudo systemctl is-active haproxy)

    if [ "$status" = "active" ]; then
        echo "---------------HA-Proxy service status---------------------"
        echo -e "\e[32mHA-Proxy tunnel is installed and $status.\e[0m"
        echo "-----------------------------------------------------------"
    else
        echo "---------------HA-Proxy service status---------------------"
        echo -e "\e[31mHA-Proxy service is not active or failed.\e[0m"
        echo "-----------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

check_haproxy() {
    # Check port in use
    echo "---------------------Port in use---------------------------"
    sudo lsof -i -P -n -sTCP:LISTEN | grep haproxy | awk '{print "TCP:", $9}'
    echo "-----------------------------------------------------------"
    # Check haproxy service status
    status=$(sudo systemctl is-active haproxy)

    if [ "$status" = "active" ]; then
        echo "---------------HA-Proxy service status---------------------"
        echo -e "\e[32mHA-Proxy Service Status: $status\e[0m"
        echo "-----------------------------------------------------------"
    else
        echo "---------------HA-Proxy service status---------------------"
        echo -e "\e[31mHA-Proxy Service Status: $status\e[0m"
        echo "-----------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

uninstall_haproxy() {
    sudo systemctl stop haproxy
    sudo systemctl disable haproxy
    sudo apt-get remove --purge haproxy -y
    clear
    echo "-------------------------------------------------------"
    echo "HA-Proxy Uninstalled."
    echo "-------------------------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

####################################################
## Function to install Socat and setup tunnel service
install_socat() {
    # Check if Socat is installed
    if ! command -v socat &> /dev/null; then
        # If not installed, install Socat
        sudo apt-get install socat -y
    else
        echo "Socat is already installed."
    fi

    # Clone the service file from GitHub to /etc/systemd/system/
    sudo wget -O /etc/systemd/system/socat.service https://raw.githubusercontent.com/hiddify/hiddify-relay/main/socat-tunnel.service
    clear
    # Get user input for $ip and $port
    read -p "Enter Main-Server IP: " ip
    read -p "Enter Main-Server Port: " port

    # Replace variables in the service file
    sudo sed -i "s/\$ip/$ip/g" /etc/systemd/system/socat.service
    sudo sed -i "s/\$port/$port/g" /etc/systemd/system/socat.service

    # Reload systemd and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable socat
    sudo systemctl start socat
    clear
    status=$(sudo systemctl is-active socat)

    if [ "$status" = "active" ]; then
        echo "---------------socat service status---------------------"
        echo -e "\e[32mSocat tunnel is installed and $status.\e[0m"
        echo "--------------------------------------------"
    else
        echo "---------------socat service status---------------------"
        echo -e "\e[31msocat service is not active or failed.\e[0m"
        echo "-------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

# Function to check port used by Socat
check_socat_port() {
    # Check port in use
    echo "---------------------Port in use---------------------------"
    sudo lsof -i -P -n -sTCP:LISTEN | grep socat | awk '{print "TCP:", $9}'
    echo "-----------------------------------------------------------"
    # Check socat service status
    status=$(sudo systemctl is-active socat)

    if [ "$status" = "active" ]; then
        echo "---------------socat service status---------------------"
        echo -e "\e[32msocat Service Status: $status\e[0m"
        echo "--------------------------------------------"
    else
        echo "---------------socat service status---------------------"
        echo -e "\e[31msocat Service Status: $status\e[0m"
        echo "-------------------------------------------------------"
    fi

# Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

# Function to uninstall Socat
uninstall_socat() {
    sudo systemctl stop socat
    sudo systemctl disable socat
    sudo rm /etc/systemd/system/socat.service
    sudo apt-get remove socat -y
    clear
    echo "-------------------------------------------------------"
    echo "Socat tunnel Uninstalled."
    echo "-------------------------------------------------------"
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

#########################################################
## Function to install wstunnel and setup wstunnel service
install_wstunnel() {
    echo "Installing wstunnel..."
    wget "https://github.com/erebe/wstunnel/releases/download/v5.0/wstunnel-linux-x64"
    sudo chmod +x wstunnel-linux-x64
    sudo mv wstunnel-linux-x64 /bin/wstunnel

    # Download service file for Iran server
    sudo rm /etc/systemd/system/wstunnel.service
    wget -O /etc/systemd/system/wstunnel.service https://raw.githubusercontent.com/Hiddify-Return/hiddify-relay/main/wstunnels.service
    clear
    # Prompt for port and domain
    read -p "Enter the port use for traffic(like 443 or any port): " mport
    read -p "Enter the Main-Server domain: " domain
    read -p "Enter the port used for wstunnel: " port

    sudo sed -i "s/\$mport/$mport/g; s/\$domain/$domain/g; s/\$port/$port/g" /etc/systemd/system/wstunnel.service

    # Start wstunnel service
    sudo systemctl daemon-reload
    sudo systemctl enable wstunnel.service
    sudo systemctl start wstunnel.service
    clear
    echo "Now make ssh to main server for setup wstunnel"

    read -p "Enter the IP of the main server: " main_server_ip
    read -p "Enter the user of the main server: " ssh_user
    read -p "Enter the SSH port of the main server (press Enter for default 22): " main_server_port
    main_server_port=${main_server_port:-22}

    read -p "Enter the port used for wstunnel: " port

    # Download wstunnelm.service and modify the port
    wget -O wstunnelm.service https://raw.githubusercontent.com/Hiddify-Return/hiddify-relay/main/wstunnelm.service
    sed -i "s/\$port/$port/g" wstunnelm.service
    clear
    # Send the modified service file to the main server
    scp -P $main_server_port wstunnelm.service $ssh_user@$main_server_ip:/tmp/wstunnelm.service
    clear
    echo "The service file sent to main server."
    echo "once again type main server Password:"
    # SSH to the main server and replace the wstunnel service file
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
    # Check Wstunnel service status
    status=$(sudo systemctl is-active wstunnel.service)

    if [ "$status" = "active" ]; then
        echo "---------------Wstunnel service status---------------------"
        echo -e "\e[32mWstunnel service is $status and running.\e[0m"
        echo "-----------------------------------------------------------"
    else
        echo "---------------Wstunnel service status---------------------"
        echo -e "\e[31mWstunnel service is not active or failed.\e[0m"
        echo "-----------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

check_wstunnel_port() {
    # Check port in use
    echo "---------------------Port in use---------------------------"
    sudo lsof -i -P -n -sTCP:LISTEN | grep wstunnel | awk '{print "TCP:", $9}'
    echo "-----------------------------------------------------------"
    # Check Wstunnel service status
    status=$(sudo systemctl is-active wstunnel.service)

    if [ "$status" = "active" ]; then
        echo "---------------Wstunnel service status---------------------"
        echo -e "\e[32mWstunnel Service Status: $status\e[0m"
        echo "-----------------------------------------------------------"
    else
        echo "---------------Wstunnel service status---------------------"
        echo -e "\e[31mWstunnel Service Status: $status\e[0m"
        echo "-----------------------------------------------------------"
    fi
    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
}

uninstall_wstunnel() {
    echo "Uninstalling wstunnel..."
    sudo systemctl stop wstunnel.service
    sudo systemctl disable wstunnel.service
    sudo rm -f /etc/systemd/system/wstunnel.service /bin/wstunnel
    clear
    echo -e "\e[31mWstunnel service uninstalled From tunnel server.\e[0m"
    echo "Use ssh to uninstall Wstunnel form main server"
    read -p "Enter the IP of the main server: " main_server_ip
    read -p "Enter the user of the main server: " ssh_user
    read -p "Enter the SSH port of the main server (press Enter for default 22): " main_server_port
    main_server_port=${main_server_port:-22}

    # SSH to the main server and execute commands
    ssh -p $main_server_port $ssh_user@$main_server_ip bash -s << 'ENDSSH'
    sudo systemctl stop wstunnel.service
    sudo systemctl disable wstunnel.service
    sudo rm -f /etc/systemd/system/wstunnel.service /bin/wstunnel
ENDSSH
    clear
    echo "-----------------------------------------"
    echo -e "\e[31mWstunnel Service Uninstalled.\e[0m"
    echo "-----------------------------------------"

    # Wait for user input (press any key to continue)
    read -n 1 -s -r -p "Press any key to return to the menu..."
    
}

################################################################
# Define the functions to be executed when an option is selected

# Graphical functionality for IP-Tables menu
iptables_menu() {
    while true; do
        choice=$(whiptail --backtitle "Hiddify Relay Builder" --title "IP-Tables Menu" --menu "Please choose one of the following options:" 20 60 10 \
        "Install" "Install IP-Tables Rules" \
        "Status" "Check Ports In Use" \
        "Uninstall" "Uninstall IP-Tables Rules" \
        "Back" "Back To Main Menu" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                Install)
                    install_iptables
                    ;;
                Status)
                    check_iptables
                    ;;
                Uninstall)
                    uninstall_iptables
                    ;;
                Back)
                    menu
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

# Graphical functionality for GOST menu
gost_menu() {
    while true; do
        choice=$(whiptail --backtitle "Hiddify Relay Builder" --title "GOST Menu" --menu "Please choose one of the following options:" 20 60 10 \
        "Install" "Install GOST" \
        "Status" "Check GOST Port And Status" \
        "Add" "Add Another Port And Domain" \
        "Uninstall" "Uninstall GOST" \
        "Back" "Back To Main Menu" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                Install)
                    install_gost
                    ;;
                Status)
                    check_port_gost
                    ;;
                Add)
                    add_port_gost
                    ;;
                Uninstall)
                    uninstall_gost
                    ;;
                Back)
                    menu
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

# Graphical functionality for Dokodemo menu
dokodemo_menu() {
    while true; do
        choice=$(whiptail --backtitle "Hiddify Relay Builder" --title "Dokodemo-Door Menu" --menu "Please choose one of the following options:" 20 60 10 \
        "Install" "Install Xray For Dokodemo-Door And Add Inbound" \
        "Status" "Check Xray Service Status" \
        "Add" "Add Another Inbound" \
        "Uninstall" "Uninstall Xray And Tunnel" \
        "Back" "Back To Main Menu" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                Install)
                    install_xray
                    ;;
                Status)
                    check_service_xray
                    ;;
                Add)
                    add_another_inbound
                    ;;
                Uninstall)
                    uninstall_xray
                    ;;
                Back)
                    menu
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

# Graphical functionality for Socat menu
haproxy_menu() {
    while true; do
        choice=$(whiptail --backtitle "Hiddify Relay Builder" --title "HA-Proxy Menu" --menu "Please choose one of the following options:" 20 60 10 \
        "Install" "Install HA-Proxy" \
        "Status" "Check HA-Proxy Port and Status" \
        "Uninstall" "Uninstall HAProxy" \
        "Back" "Back To Main Menu" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                Install)
                    install_haproxy
                    ;;
                Status)
                    check_haproxy
                    ;;
                Uninstall)
                    uninstall_haproxy
                    ;;
                Back)
                    menu
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

# Graphical functionality for Socat menu
socat_menu() {
    while true; do
        choice=$(whiptail --backtitle "Hiddify Relay Builder" --title "Socat Menu" --menu "Please choose one of the following options:" 20 60 10 \
        "Install" "Install Socat And Setup Tunnel Service" \
        "Status" "Check Socat Port" \
        "Uninstall" "Uninstall Socat And Remove Tunnel Service" \
        "Back" "Back To Main Menu" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                Install)
                    install_socat
                    ;;
                Status)
                    check_socat_port
                    ;;
                Uninstall)
                    uninstall_socat
                    ;;
                Back)
                    menu
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

# Graphical functionality for WSTunnel menu
wstunnel_menu() {
    while true; do
        choice=$(whiptail --backtitle "Hiddify Relay Builder" --title "WS-Tunnel Menu" --menu "Please choose one of the following options:" 20 60 10 \
        "Install" "Install And Configure WS-Tunnel On Both Servers" \
        "Status" "Check WS-Tunnel Service And Port" \
        "Uninstall" "Uninstall WS-Tunnel From Both Servers" \
        "Back" "Back To Main Menu" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                Install)
                    install_wstunnel
                    ;;
                Status)
                    check_wstunnel_port
                    ;;
                Uninstall)
                    uninstall_wstunnel
                    ;;
                Back)
                    menu
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

#################################
# Define the main graphical menu
function menu() {
    while true; do
        choice=$(whiptail --backtitle "Welcome to Hiddify Relay Builder" --title "Choose Your Tunnel Mode" --menu "Please choose one of the following options:" 20 60 10 \
        "IP-Tables" "Manage IP-Tables Tunnel" \
        "GOST" "Manage GOST Tunnel" \
        "Dokodemo-Door" "Manage Dokodemo-Door Tunnel" \
        "HA-Proxy" "Manage HA-Proxy Tunnel" \
        "Socat" "Manage Socat Tunnel" \
        "WST" "Manage Web Socket Tunnel" \
        "Quit" "Exit From The Script" 3>&1 1>&2 2>&3)

        # Check the return value of the whiptail command
        if [ $? -eq 0 ]; then
            # Check if the user selected a valid option
            case $choice in
                IP-Tables)
                    iptables_menu
                    ;;
                GOST)
                    gost_menu
                    ;;
                Dokodemo-Door)
                    dokodemo_menu
                    ;;
                HA-Proxy)
                    haproxy_menu
                    ;;
                Socat)
                    socat_menu
                    ;;
                WST)
                    wstunnel_menu
                    ;;
                Quit)
                    exit 0
                    ;;
                *)
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option." 8 60
                    exit 1
                    ;;
            esac
        else
            exit 1
        fi
    done
}

# Call the menu function
menu
