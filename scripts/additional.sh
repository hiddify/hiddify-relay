source /opt/hiddify-relay/scripts/path.sh
source /opt/hiddify-relay/scripts/package.sh

configure_dns() {

    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    sudo rm /etc/resolv.conf > /dev/null 2>&1

    dns1=$(whiptail --inputbox "Enter DNS Server 1 (like 8.8.8.8):" 8 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    
    if [ $exitstatus != 0 ] || [ -z "$dns1" ]; then
        whiptail --title "DNS Configuration" --msgbox "Operation cancelled or invalid input. Restoring default DNS configuration." 8 60
        restore_dns
        exit 1
    fi

    dns2=$(whiptail --inputbox "Enter DNS Server 2 (like 8.8.4.4):" 8 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    
    if [ $exitstatus != 0 ] || [ -z "$dns2" ]; then
        whiptail --title "DNS Configuration" --msgbox "Operation cancelled or invalid input. Restoring default DNS configuration." 8 60
        restore_dns
        exit 1
    fi

    echo "nameserver $dns1" | sudo tee -a /etc/resolv.conf > /dev/null
    echo "nameserver $dns2" | sudo tee -a /etc/resolv.conf > /dev/null

    whiptail --title "DNS Configuration" --msgbox "DNS Configuration completed." 8 60
    clear
}

restore_dns() {
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf > /dev/null
}

function update_server() {
    (
        sudo $PACKAGE_MANAGER update -y
        echo "100" "Update completed."
    ) | dialog --title "Update Server" --progressbox 30 120

    whiptail --title "Update Server" --msgbox "Server Update completed." 8 60
    clear
}

function ping_websites() {
    websites=("github.com" "google.com" "www.cloudflare.com")
    results_file=$(mktemp)

    for website in "${websites[@]}"; do
        gauge_title="Pinging $website"
        gauge_percentage=0
        success=false

        (
            for _ in {1..5}; do
                sleep 1  
                ((gauge_percentage += 20))
                echo "$gauge_percentage"
                echo "# $gauge_title"
                echo "Pinging $website..."
                
                if ping -c 1 $website &> /dev/null; then
                    success=true
                fi
            done
            echo "100" 
        ) | dialog --title "Ping $website" --gauge "$gauge_title" 10 80 0

        result=$(ping -c 5 $website | tail -n 2)
        echo -e "\n\nPing results for $website:\n$result" >> "$results_file"
    done

    whiptail --title "Ping Websites" --textbox "$results_file" 30 80
    clear

    rm "$results_file"
}