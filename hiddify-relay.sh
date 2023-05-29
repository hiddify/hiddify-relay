#!/bin/bash
HEIGHT=20
WIDTH=60
CHOICE_HEIGHT=10
BACKTITLE="Welcome to Hiddify Relay"
TITLE="Enter your tunnel mode"
MENU="Choose one of the following options:"


# Menu options
OPTIONS=(
    "ssh"         "SSH"
    "tcp"         "TCPSocket"
    "ws"          "WebSocket"
    "wss"         "WebSocket+TLS"
    "tls+h1"      "TLS HTTP 1.1"
    "tls+h2"      "TLS HTTP2"
    "tls+h3"      "TLS HTTP3"
    "grpc"        "GRPC"
    "iptable"     "iptables tunnel"
)

function set_data() {
    local key=$1
    local value=$2
    local config_file="/opt/hiddify-relay/data.conf"

    # Set the data in the configuration file
    echo "$key=$value" >> "$config_file"
}

function get_data() {
    local key=$1
    local config_file="/opt/hiddify-relay/data.conf"

    # Read the value associated with the key from the configuration file
    local value=$(grep "^$key=" "$config_file" | cut -d'=' -f2)

    echo "$value"
}
function show_tunnel_ports_dialog() {
    local server_ports

    # Dialog for server ports
    server_ports=$(dialog --clear \
                          --backtitle "$BACKTITLE" \
                          --title "Enter the Ports to Forward" \
                          --inputbox "Enter the server ports (comma-separated or range):" $HEIGHT $WIDTH \
                          --default-item  $(get_data TUNNEL_PORTS)\
                          2>&1 >/dev/tty)

    # Check if the user canceled the input
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Validate and parse the server ports
    local valid_ports=()
    IFS=',' read -ra port_list <<< "$server_ports"
    for port_item in "${port_list[@]}"; do
        if [[ $port_item =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start_port=${BASH_REMATCH[1]}
            end_port=${BASH_REMATCH[2]}
            for (( port=start_port; port<=end_port; port++ )); do
                valid_ports+=("$port")
            done
        elif [[ $port_item =~ ^[0-9]+$ ]]; then
            valid_ports+=("$port_item")
        fi
    done

    # Check if any valid ports were found
    if [[ ${#valid_ports[@]} -eq 0 ]]; then
        dialog --clear \
               --backtitle "$BACKTITLE" \
               --title "Invalid Input" \
               --msgbox "No valid ports were provided. Please try again." 7 40
        return 1
    fi

    # Return the valid server ports as an array
    server_ports=("${valid_ports[@]}")
    echo "${valid_ports[@]}"
}
# Function to display the SSH server details dialog
function show_ssh_dialog() {
    local ssh_address
    local ssh_port
    local ssh_password
    local ssh_user

    # Generate public key if it doesn't exist
    if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
        echo "Generating a new public key for the server..."
        ssh-keygen -t rsa -f "$HOME/.ssh/id_rsa" -N "" -q
        echo "Public key generated."
    fi
    if [[ -f "/opt/hiddify-relay/data.conf" ]]; then
        # Read the SSH server details from the configuration file
        source "/opt/hiddify-relay/data.conf"

        # Set the default values from the configuration file
        ssh_address=$(get_data SSH_SERVER)
        ssh_port=$(get_data SSH_PORT)
        ssh_port=${ssh_port:-22}
        ssh_user=$(get_data SSH_USER)
        ssh_user=${ssh_user:-root}
    fi
    # Dialog for server details
    SERVER_DETAILS=$(dialog --clear \
                            --backtitle "$BACKTITLE" \
                            --title "SSH Server Details" \
                            --form "Enter server details: You do not need to re-enter password" $HEIGHT $WIDTH 0 \
                            "User:" 1 1 "$ssh_user" 1 20 40 0 \
                            "Server Address:" 2 1 "$ssh_address" 2 20 40 0 \
                            "Server Port:" 3 1 "$ssh_port" 3 20 10 0 \
                            "Server Password:" 4 1 "" 4 20 40 0 \
                            2>&1 >/dev/tty)

    # Read server details from the dialog output
    ssh_user=$(echo "$SERVER_DETAILS" | awk 'NR==1{print $NF}')
    ssh_address=$(echo "$SERVER_DETAILS" | awk 'NR==2{print $NF}')
    ssh_port=$(echo "$SERVER_DETAILS" | awk 'NR==3{print $NF}')
    ssh_password=$(echo "$SERVER_DETAILS" | awk 'NR==4{print $NF}')

    # Check if the user canceled the input
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Check if the required fields are empty
    if [[ -z "$ssh_address" || -z "$ssh_port" ]]; then
        return 1
    fi

    # Check if SSH user is provided
    if [[ -z "$ssh_user" ]]; then
        dialog --clear \
               --backtitle "$BACKTITLE" \
               --title "SSH User Error" \
               --msgbox "SSH user is required." 7 40
        return 1
    fi

    # Check if password is provided or use public key authentication
    if [[ -n "$ssh_password" ]]; then
        # SSH with password
        sshpass -p "$ssh_password" ssh-copy-id -p "$ssh_port" "$ssh_user@$ssh_address"
    else
        # SSH with public key authentication
    fi

    # Check SSH access
    if ssh -q -o BatchMode=yes -p "$ssh_port" "$ssh_user@$ssh_address" exit; then
        echo "SSH access granted."
    else
        dialog --clear \
               --backtitle "$BACKTITLE" \
               --title "SSH Access Error" \
               --msgbox "Failed to establish SSH connection. Please check your credentials and try again." 7 60
        return 1
    fi
    

    # Save server details to file
    set_data SSH_SERVER "$ssh_address"
    set_data SSH_PORT "$ssh_port"
    set_data SSH_USER "$ssh_user"
    
}
function convert_to_individual_ports() {
    local input_ports=("$@")
    local individual_ports=()

    for port_range in "${input_ports[@]}"; do
        if [[ $port_range =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start_port=${BASH_REMATCH[1]}
            end_port=${BASH_REMATCH[2]}
            for ((port=start_port; port<=end_port; port++)); do
                individual_ports+=("$port")
            done
        elif [[ $port_range =~ ^[0-9]+$ ]]; then
            individual_ports+=("$port_range")
        fi
    done

    echo "${individual_ports[@]}"
}
function setup_ssh_tunnel(){
    ln -sf $(pwd)/hiddify-tunnel.service /etc/systemd/system/hiddify-tunnel.service
    systemctl daemon-reload
    systemctl enable hiddify-tunnel
    systemctl restart hiddify-tunnel
    tunnel_ports=$(show_tunnel_ports_dialog)
    individual_ports=$(convert_to_individual_ports "${tunnel_ports}") 
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 1001
    iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 1002
    iptables-save | tee /etc/iptables/rules.v4

    dialog --clear \
               --backtitle "$BACKTITLE" \
               --title "SSH Tunnel Setup Successfully" \
               --msgbox "Please share if it is useful." 7 60
}

function setup_gost_tunnel(){
    ln -sf $(pwd)/gost-tunnel.service /etc/systemd/system/gost-tunnel.service
    systemctl daemon-reload
    systemctl enable gost-tunnel
    systemctl restart gost-tunnel

    # rules=$(iptables -S | grep -E "\--dport (80|443)")
    rules=$(iptables -S | grep -E "\--dport")

    # Iterate through the rules and remove them
    while IFS= read -r rule; do
        iptables -D $(echo "$rule" | cut -d' ' -f1-2)
    done <<< "$rules"

    iptables-save | tee /etc/iptables/rules.v4

    dialog --clear \
               --backtitle "$BACKTITLE" \
               --title "Gost Tunnel Setup Successfully" \
               --msgbox "Please share if it is useful." 7 60
}

while true; do

    CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)
    if [[ $? -ne 0 ]]; then
        break
    fi
    case $CHOICE in
        "ssh")
            echo "Selected option: SSH"
            show_ssh_dialog && setup_ssh_tunnel
            ;;
        "ws")
            echo "Selected option: WebSocket"
            # Add WebSocket mode handling here
            ;;
        "wss")
            echo "Selected option: WebSocket+TLS"
            # Add WebSocket+TLS mode handling here
            ;;
        "tls+h1")
            echo "Selected option: TLS HTTP 1.1"
            # Add TLS HTTP 1.1 mode handling here
            ;;
        "tls+h2")
            echo "Selected option: TLS HTTP2"
            # Add TLS HTTP2 mode handling here
            ;;
        "tls+h3")
            echo "Selected option: TLS HTTP3"
            # Add TLS HTTP3 mode handling here
            ;;
        "grpc")
            echo "Selected option: GRPC"
            # Add GRPC mode handling here
            ;;
        "tcp")
            echo "Selected option: TCP socket"
            local server_address
            server_address=$(dialog --clear \
                                    --backtitle "$BACKTITLE" \
                                    --title "Remote Server Address" \
                                    --inputbox "Enter the remote server address:" $HEIGHT $WIDTH \
                                    2>&1 >/dev/tty)

            COMMAND="gost"
            command_args=""
            individual_ports=$(convert_to_individual_ports "${tunnel_ports}") 
            for port in "${individual_ports[@]}"; do
                command_args+=" -L=tcp://:$(echo "$port" | tr -d ' ')/$server_address:$port"
            done
            full_command="$COMMAND $command_args"
            set_data COMMAND "$full_command"                        
            setup_gost_tunnel
            ;;
        "iptable")
            echo "Selected option: iptables tunnel"
            # Add iptables tunnel mode handling here
            ;;
        *)
            echo "Invalid option"
                exit 0
            ;;
    esac
done         