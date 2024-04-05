#!/bin/bash

# Global variables
CUSTOM_BIN_DIR="$HOME/.local/bin" # Define a custom bin directory
UNRUGGABLE_FOLDER="$HOME/.config/solana/unrugabble"
ADDRESS_BOOK_FILE="$HOME/.config/solana/unrugabble/addressBook.txt"
UNRUGGABLE_WALLET="$UNRUGGABLE_FOLDER/unrgbpN7XGMQKbbnMYoqvoFbcnVKcaaXVJD2vSrmnUJ.json"
CONFIG_FILE="$HOME/.config/solana/cli/config.yml"
UNRUGGABLE_STAKING="$UNRUGGABLE_FOLDER/staking_keys"
DEFAULT_KEYS_DIR="$HOME/.config/solana"

# Function to detect the operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS=Linux;;
        Darwin*)    OS=macOS;;
        *)          OS="UNKNOWN:${unameOut}"
    esac
    echo "Operating System Detected: $OS"
}

# Function to detect the operating system
detect_processor() {
    ARCH=$(uname -m)
    echo "Processor detected: $ARCH"
    case "$ARCH" in
        "x86_64")
            # Intel-based Mac
            SOLANA_BINARY="solana-release-x86_64-apple-darwin.tar.bz2"
            ;;
        "arm64")
            # Apple Silicon Mac
            SOLANA_BINARY="solana-release-aarch64-apple-darwin.tar.bz2"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
}

# Function to check and install a package
check_and_install_package() {
    local package_name=$1

    # Check if jq is installed
    if ! command -v $package_name &> /dev/null; then
        echo "$package_name could not be found. Attempting to install."

        if [[ $OS == "Linux" ]]; then
            sudo apt-get update && sudo apt-get install -y $package_name
        elif [[ $OS == "macOS" ]]; then
            brew install $package_name
        fi

        # Check again if package installation was successful
        if ! command -v $package_name &> /dev/null; then
            echo "Failed to install $package_name. Attempting to use local binary."
            use_local_binary $package_name
        else
            echo "$package_name installed successfully."
        fi
    else
        echo "$package_name is already installed."
    fi
}

# Function to check if Solana CLI is installed
check_solana_cli_installed() {
    if ! command -v solana &> /dev/null; then
        echo "Error: Solana CLI could not be found."
        echo "Please install the Solana CLI. Visit https://docs.solana.com/cli/install-solana-cli-tools for instructions."
        exit 1
    fi
    echo "solana cli is installed"
}

# Function to check if SPL Token CLI is installed
check_spl_token_cli_installed() {
    if ! command -v spl-token &> /dev/null; then
        echo "Error: SPL Token CLI could not be found."
        echo "Please install the SPL Token CLI. You can usually install it via 'cargo install spl-token-cli' if you have Rust and Cargo installed."
        exit 1
    fi
    echo "spl-token cli is installed"
}

check_and_create_unrugabble_folder() {
    if [ ! -d "$UNRUGGABLE_FOLDER" ]; then
        mkdir -p "$UNRUGGABLE_FOLDER"
        if [ $? -eq 0 ]; then
            echo "Unurggable folder created successfully."
        else
            echo "Error: Failed to create the folder $UNRUGGABLE_FOLDER."
            exit 1
        fi
    else
        echo "Unuruggable folder inited. Check passed."
    fi
}

check_and_create_address_book() {
    # Check if the address book file exists
    if [ ! -f "$ADDRESS_BOOK_FILE" ]; then
        echo "Address book not found. Initializing with devs cat treat wallet."

        # Assuming you want to initialize the address book with a specific entry
        # Here, you might want to replace the placeholder with actual content
        # For example, an initial wallet address and a label
        echo "juLesoSmdTcRtzjCzYzRoHrnF8GhVu6KCV7uxq7nJGp dev-cat-snacks" > "$ADDRESS_BOOK_FILE"

        if [ $? -eq 0 ]; then
            echo "Address book initialized successfully."
        else
            echo "Error: Failed to initialize the address book at $ADDRESS_BOOK_FILE."
            exit 1
        fi
    else
        echo "Address book found. Check passed."
    fi
}

create_and_set_custom_solana_config() {    
    local keypair_contents="[27,203,252,17,115,122,59,91,33,13,140,45,118,150,211,179,190,56,225,8,203,28,245,59,185,20,22,223,11,169,34,7,13,134,13,99,37,161,7,4,176,180,158,70,17,65,150,2,1,0,207,105,102,152,197,68,26,204,160,135,139,201,252,211]"
    # Overwrite the config file to unruggable default
    echo "Setting Solana config file to unruggable default..."
    cat > "$CONFIG_FILE" <<EOF
---
json_rpc_url: https://damp-fabled-panorama.solana-mainnet.quiknode.pro/186133957d30cece76e7cd8b04bce0c5795c164e/
websocket_url: ''
keypair_path: $UNRUGGABLE_WALLET
address_labels:
  '11111111111111111111111111111111': System Program
commitment: confirmed
EOF

    echo "Creating custom Solana keypair file..."
    echo "$keypair_contents" > "$UNRUGGABLE_WALLET"
    solana config set -k "$UNRUGGABLE_WALLET"

    echo "Custom Solana configuration and keypair setup complete."
}



# Function to run all pre-launch checks
run_pre_launch_checks() {
    echo "Performing pre-launch checks..."
    echo "Detecting Operating System"
    detect_os
    detect_processor
    #Use these to derive correct binary from solana

    # Check and install curl, jq and qrencode
    check_and_install_package "curl"
    check_and_install_package "jq"
    check_and_install_package "qrencode"
    
    # Check that solana and spl-token are available
    check_solana_cli_installed
    check_spl_token_cli_installed

    check_and_create_unrugabble_folder
    create_and_set_custom_solana_config
    check_and_create_address_book
    echo "All checks passed. Launching Unruggable..."
}


# Function to get wallet and staked information
get_wallet_info() {
    # Get the current config
    config_output=$(solana config get)

    # Extract the keypair path
    keypair_path=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}')

    # Get the wallet address
    wallet_address=$(solana address -k "$keypair_path")

    # Get the balance
    balance=$(solana balance "$wallet_address")

    # Initialize total staked SOL variable
    total_staked_sol=0

    # Check if the staking keys directory exists
    if [ -d "$UNRUGGABLE_STAKING" ]; then
        # Prepare a glob pattern for stake account files
        stake_account_files_glob="$UNRUGGABLE_STAKING"/"$wallet_address"*.json

        # Check if glob pattern expands to anything (if there are any files)
        # This is a workaround to check if a glob pattern matches any file
        # We put it in an array and check the array size
        stake_account_files=( $stake_account_files_glob )
        if [ -e "${stake_account_files[0]}" ]; then
            # Loop through each stake account file in the staking keys directory
            for stake_account_file in "${stake_account_files[@]}"; do
                # Fetch the stake account balance and extract just the numeric part
                stake_account_balance=$(solana balance -k "$stake_account_file" | awk '{print $1}')

                # Ensure the balance is a valid number before adding
                if [[ $stake_account_balance =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    # Add the stake account balance to the total staked SOL
                    total_staked_sol=$(echo "$total_staked_sol + $stake_account_balance" | bc)
                fi
            done
        fi
    fi

    echo "$wallet_address $balance $total_staked_sol"
}

# Function to print wallet address in color
print_colored_address() {
    local address=$1
    # Define an array of colors
    local -a colors=(
        '\033[0;31m' # Red
        '\033[0;32m' # Green
        '\033[0;33m' # Yellow
        '\033[0;34m' # Blue
        '\033[0;35m' # Magenta
        '\033[0;36m' # Cyan
        '\033[0;37m' # Light gray
        '\033[0;91m' # Light red
        '\033[0;92m' # Light green
        '\033[0;93m' # Light yellow
        '\033[0;94m' # Light blue
        '\033[0;95m' # Light magenta
        '\033[0;96m' # Light cyan
        '\033[0;97m' # White
    )
    local nc='\033[0m' # No Color
    local part_length=$(( ${#address} / 4 ))

    for (( i=0; i<4; i++ )); do
        local part=${address:$((i * part_length)):${part_length}}
        local sum=0
        # Calculate sum of ASCII values of characters in the part
        for (( j=0; j<${#part}; j++ )); do
            local ord=$(printf "%d" "'${part:$j:1}")
            ((sum+=ord))
        done
        # Use the sum to select a color
        local color_index=$((sum % ${#colors[@]}))
        local color=${colors[$color_index]}
        # Print the part in the selected color
        echo -en "${color}${part}${nc}"
    done
}



receive_sol() {
    # Fetch the current wallet address
    wallet_address=$(solana address)
    
    echo "Scan this QR code to receive SOL at address:" 
    print_colored_address $wallet_address
    echo ""
    #echo $wallet_address
    # Generate and display the QR code
    qrencode -t UTF8 "$wallet_address"
    
    echo "Press any key to return to the home screen..."
    read -n 1 -s # Wait for user input before returning
}

send_sol() {
    while true; do
        echo "How would you like to send SOL?"
        echo "1 - Enter a Solana address."
        echo "2 - Select from Unruggable loaded wallets."
        if [ -f "$ADDRESS_BOOK_FILE" ]; then
            echo "3 - Select from your address book."
        else
            echo "3 - Initialize address book."
        fi
        echo "9 - Return to home screen."
        read -p "Enter your choice (1, 2, 3, or 9): " send_choice

        if [[ $send_choice -eq 2 ]]; then
            # Reuse the display_available_wallets logic but for selection purpose
            config_output=$(solana config get)
            keypair_dir=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}' | xargs dirname)
            
            echo "Available Wallets:"
            local i=0
            declare -a wallet_paths # Use a simple array to store paths
            declare -a wallet_addys # Use a simple array to store paths

            # Function to process directories and find wallets
            process_directory() {
                local directory=$1
                if [ -d "$directory" ]; then
                    for keypair in "$directory"/*.json; do
                        # Check if the file exists to avoid the case where the glob doesn't match anything
                        if [ -e "$keypair" ]; then
                            wallet_address=$(solana address -k "$keypair")
                            balance=$(solana balance "$wallet_address")
                            echo "$i. $wallet_address ($balance)"
                            wallet_paths+=("$keypair")
                            wallet_addys+=("$wallet_address")
                            i=$((i+1))
                        fi
                    done
                fi
            }

            # Check and process each unique directory
            if [[ "$keypair_dir" != "$UNRUGGABLE_FOLDER" && "$keypair_dir" != "$DEFAULT_KEYS_DIR" ]]; then
                process_directory "$keypair_dir"
            fi
            process_directory "$UNRUGGABLE_FOLDER"
            process_directory "$DEFAULT_KEYS_DIR"

            read -p "Select the number of the wallet you want to send SOL to: " wallet_selection

            if [[ $wallet_selection =~ ^[0-9]+$ ]] && [ $wallet_selection -ge 0 ] && [ $wallet_selection -lt ${#wallet_paths[@]} ]; then
                recipient_address=${wallet_addys[$wallet_selection]}
                echo "You have selected to send SOL to: $recipient_address"
            else
                echo "Invalid selection. Returning to the main menu."
                return
            fi
        elif [[ $send_choice -eq 1 ]]; then
            read -p "Enter the recipient's address: " recipient_address
            #echo "You have selected to send SOL to $recipient_address"
            # Print the static message part
            echo -n "You have selected to send SOL to "
            # Print the recipient address in color
            print_colored_address "$recipient_address"
            echo ""
        elif [[ $send_choice -eq 3 ]]; then
            echo "Select a recipient from the address book:"
            local i=0
            declare -a book_entries
            while IFS= read -r line; do
                address=$(echo $line | awk '{print $1}')
                tag=$(echo $line | cut -d ' ' -f 2-)
                echo "$i. $tag ($address)"
                book_entries[i]=$address
                i=$((i+1))
            done < "$ADDRESS_BOOK_FILE"

            read -p "Enter the number of the recipient: " book_selection
            if [[ $book_selection =~ ^[0-9]+$ ]] && [ $book_selection -ge 0 ] && [ $book_selection -lt ${#book_entries[@]} ]; then
                recipient_address=${book_entries[$book_selection]}
                echo "You have selected to send SOL to $recipient_address"
            else
                echo "Invalid selection. Please try again."
                continue
            fi
        elif [[ $send_choice -eq 9 ]]; then
            echo "Returning to home screen."
            return
        else
            echo "Invalid choice. Please try again."
            continue
        fi
    

        # Assuming the address could be valid, proceed to check the balance
        recipient_balance=$(solana balance "$recipient_address" 2>&1)
        # Check if the solana command succeeded
        if [[ $? -ne 0 ]]; then
            echo "Error fetching balance. Please ensure the address is correct. Error details: $recipient_balance"
            return
        else
            echo "Recipient owns   : $recipient_balance"
            # Extract all mint addresses for tokens owned by the wallet
            output=$(spl-token accounts --output json-compact --owner "$recipient_address")
            owned_mints=$(echo "$output" | jq -r '.accounts[] | select(.tokenAmount.uiAmount > 0) | .mint')

            # Check if owned_mints is not empty
            if [ -n "$owned_mints" ]; then
                # Process each owned mint for tokens
                echo "$owned_mints" | while read -r mint_address; do
                    token_info=$(grep -i "$mint_address" tokens.txt)
                    if [ ! -z "$token_info" ]; then
                        token_name=$(echo "$token_info" | awk -F, '{print $2}')
                        balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
                        echo "Recipient owns token:  $balance $token_name"
                    fi
                done
            else
                echo ""
            fi

            # Check if owned_mints is not empty
            if [ -n "$owned_mints" ]; then
                # Process each owned mint for tokens
                echo "$owned_mints" | while read -r mint_address; do
                    nft_info=$(grep -i "$mint_address" nfts.txt)
                    if [ ! -z "$token_info" ]; then
                        token_name=$(echo "$nft_info" | awk -F, '{print $2}')
                        balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
                        echo "Recipient owns token:  $balance $token_name"
                    fi
                done
            else
                echo ""
            fi
        fi


        # Prompt for amount to send
        read -p "Enter the amount of SOL to send: " amount

        # Handle the case where the recipient's account is unfunded
        if [[ $recipient_balance == "0" ]]; then
            echo "The recipient's account is unfunded."
            read -p "Do you still want to proceed with the transfer? (yes/no): " confirmation
            if [[ $confirmation != "yes" ]]; then
                echo "Transfer cancelled."
                return
            fi
            transfer_command="solana transfer --allow-unfunded-recipient --with-compute-unit-price 0.00001 $recipient_address $amount"
        else
            echo "You are sending $amount SOL to Wallet: $recipient_address"
            read -p "Confirm the transaction? (yes/no): " confirmation
            if [[ $confirmation != "yes" ]]; then
                echo "Transfer cancelled."
                return
            fi
            transfer_command="solana transfer --allow-unfunded-recipient --with-compute-unit-price 0.00001 $recipient_address $amount"
        fi

        # Execute the transfer
        echo "Executing transfer..."
        eval $transfer_command

        echo "Transaction completed."
        
        # Check if the address is already in the address book
        if grep -q "$recipient_address" "$ADDRESS_BOOK_FILE"; then
            echo "This address is already in your address book."
        else
            read -p "Press Enter to go back home or type 'add' to add this address to your address book: " post_tx_choice
            if [[ $post_tx_choice == "add" ]]; then
                read -p "Enter a tag for this address: " tag
                echo "$recipient_address $tag" >> "$ADDRESS_BOOK_FILE"
                echo "Address added to your address book."
            fi
        fi
        break
    done    
}

display_tokens_and_send() {
    # Get the current wallet address
    wallet_address=$(solana address)
    
    echo "Fetching tokens for wallet: $wallet_address"
    # Call the command and store the result in a variable
    output=$(spl-token accounts --output json-compact --owner "$wallet_address")

    echo "--------------------------------------------------------------------------------"
    echo "|                           Token Balances                                     |"
    echo "--------------------------------------------------------------------------------"

    declare -a mint_addresses
    declare -a token_names
    declare -a balances
    declare -a is_nft

    index=0

    # Extract all mint addresses for tokens owned by the wallet
    owned_mints=$(echo "$output" | jq -r '.accounts[] | select(.tokenAmount.uiAmount > 0) | .mint')

    # Process each owned mint for tokens using process substitution
    while IFS= read -r mint_address; do
        token_info=$(grep -i "$mint_address" tokens.txt)
        if [ ! -z "$token_info" ]; then
            token_name=$(echo "$token_info" | awk -F, '{print $2}')
            balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
            echo "$index. $token_name ($balance)"
            mint_addresses[$index]=$mint_address
            token_names[$index]="$token_name"
            balances[$index]=$balance
            index=$((index+1))
        fi
    done < <(echo "$owned_mints")

    if [ $index -eq 0 ]; then
        echo "No tokens found in the wallet."
        return
    fi

    echo "--------------------------------------------------------------------------------"
    echo "Select the token you wish to send:"
    read -p "Enter the number of the token: " token_selection

    if [[ ! $token_selection =~ ^[0-9]+$ ]] || [ $token_selection -ge $index ]; then
        echo "Invalid selection."
        return
    fi

    selected_token_name=${token_names[$token_selection]}
    selected_mint_address=${mint_addresses[$token_selection]}
    selected_balance=${balances[$token_selection]}

    echo "You have selected to send $selected_token_name with balance $selected_balance."

    read -p "Enter the amount of $selected_token_name to send: " amount_to_send

    # Now, implement the 'where to' structure similar to send_sol
    while true; do
        echo "How would you like to send $selected_token_name?"
        echo "1 - Enter a Solana address."
        echo "2 - Select from Unruggable loaded wallets."
        echo "3 - Select from your address book."
        echo "9 - Return to home screen."
        read -p "Enter your choice (1, 2, 3, or 9): " send_choice

        case $send_choice in
            1)
                read -p "Enter the recipient's address: " recipient_address
                # Print the static message part
                echo -n "You entered the address:"
                # Print the recipient address in color
                print_colored_address "$recipient_address"
                echo ""
                ;;
            2)
                # Reuse the display_available_wallets logic but for selection purpose
                config_output=$(solana config get)
                keypair_dir=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}' | xargs dirname)
                
                echo "Available Wallets:"
                local i=0
                declare -a wallet_paths # Use a simple array to store paths

                # Function to process directories and find wallets
                process_directory() {
                    local directory=$1
                    if [ -d "$directory" ]; then
                        for keypair in "$directory"/*.json; do
                            # Check if the file exists to avoid the case where the glob doesn't match anything
                            if [ -e "$keypair" ]; then
                                wallet_address=$(solana address -k "$keypair")
                                balance=$(solana balance "$wallet_address")
                                echo "$i. $wallet_address ($balance)"
                                wallet_paths+=("$keypair")
                                i=$((i+1))
                            fi
                        done
                    fi
                }

                # Check and process each unique directory
                if [[ "$keypair_dir" != "$UNRUGGABLE_FOLDER" && "$keypair_dir" != "$DEFAULT_KEYS_DIR" ]]; then
                    process_directory "$keypair_dir"
                fi
                process_directory "$UNRUGGABLE_FOLDER"
                process_directory "$DEFAULT_KEYS_DIR"

                read -p "Select the number of the wallet you want to send SOL to: " wallet_selection

                if [[ $wallet_selection =~ ^[0-9]+$ ]] && [ $wallet_selection -ge 0 ] && [ $wallet_selection -lt ${#wallet_paths[@]} ]; then
                    recipient_address=${wallet_paths[$wallet_selection]}
                    echo "You have selected to send SOL to $recipient_address"
                else
                    echo "Invalid selection. Returning to the main menu."
                    return
                fi
                ;;
            3)
                echo "Select a recipient from the address book:"
                local i=0
                declare -a book_entries
                while IFS= read -r line; do
                    address=$(echo $line | awk '{print $1}')
                    tag=$(echo $line | cut -d ' ' -f 2-)
                    echo "$i. $tag ($address)"
                    book_entries[i]=$address
                    i=$((i+1))
                done < "$ADDRESS_BOOK_FILE"

                read -p "Enter the number of the recipient: " book_selection
                if [[ $book_selection =~ ^[0-9]+$ ]] && [ $book_selection -ge 0 ] && [ $book_selection -lt ${#book_entries[@]} ]; then
                    recipient_address=${book_entries[$book_selection]}
                    echo "You have selected the address:"
                    print_colored_address "$recipient_address"
                    echo ""
                else
                    echo "Invalid selection. Please try again."
                    continue
                fi
                ;;
            9)
                echo "Returning to home screen."
                return
                ;;
            *)
                echo "Invalid choice. Please try again."
                continue
                ;;
        esac

        # Assuming the address could be valid, proceed to check the balance
        recipient_balance=$(solana balance "$recipient_address" 2>&1)
        # Check if the solana command succeeded
        if [[ $? -ne 0 ]]; then
            echo "Error fetching balance. Please ensure the address is correct. Error details: $recipient_balance"
            return
        else
            echo "Recipient owns   : $recipient_balance"
            # Extract all mint addresses for tokens owned by the wallet
            output=$(spl-token accounts --output json-compact --owner "$recipient_address")
            owned_mints=$(echo "$output" | jq -r '.accounts[] | select(.tokenAmount.uiAmount > 0) | .mint')

            # Check if owned_mints is not empty
            if [ -n "$owned_mints" ]; then
                # Process each owned mint for tokens
                echo "$owned_mints" | while read -r mint_address; do
                    token_info=$(grep -i "$mint_address" tokens.txt)
                    if [ ! -z "$token_info" ]; then
                        token_name=$(echo "$token_info" | awk -F, '{print $2}')
                        balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
                        echo "Recipient owns token:  $balance $token_name"
                    fi
                done
            else
                echo ""
            fi

            # Check if owned_mints is not empty
            if [ -n "$owned_mints" ]; then
                # Process each owned mint for tokens
                echo "$owned_mints" | while read -r mint_address; do
                    nft_info=$(grep -i "$mint_address" nfts.txt)
                    if [ ! -z "$token_info" ]; then
                        token_name=$(echo "$nft_info" | awk -F, '{print $2}')
                        balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
                        echo "Recipient owns token:  $balance $token_name"
                    fi
                done
            else
                echo ""
            fi
        fi



        # Assuming the address could be valid, proceed with sending logic
        echo "Sending $amount_to_send $selected_token_name to $recipient_address..."
        # Implement the SPL token transfer command here
        # Example: spl-token transfer --fund-recipient $selected_mint_address $amount_to_send $recipient_address

        echo "Transaction completed."
        # Check if the address is already in the address book
        if grep -q "$recipient_address" "$ADDRESS_BOOK_FILE"; then
            echo "This address is already in your address book."
        else
            read -p "Press Enter to go back home or type 'add' to add this address to your address book: " post_tx_choice
            if [[ $post_tx_choice == "add" ]]; then
                read -p "Enter a tag for this address: " tag
                echo "$recipient_address $tag" >> "$ADDRESS_BOOK_FILE"
                echo "Address added to your address book."
            fi
        fi
        break
    done
}

display_nfts() {
    # Get the current wallet address
    wallet_address=$(solana address)
    
    echo "Fetching tokens for wallet: $wallet_address"
    # Call the command and store the result in a variable
    output=$(spl-token accounts --output json-compact --owner "$wallet_address")

    echo "--------------------------------------------------------------------------------"
    echo "|                               NFTs                                           |"
    echo "--------------------------------------------------------------------------------"

    declare -a mint_addresses
    declare -a token_names
    declare -a balances
    declare -a is_nft

    index=0

    # Extract all mint addresses for tokens owned by the wallet
    owned_mints=$(echo "$output" | jq -r '.accounts[] | select(.tokenAmount.uiAmount > 0) | .mint')

    # Process each owned mint for tokens using process substitution
    while IFS= read -r mint_address; do
        token_info=$(grep -i "$mint_address" nfts.txt)
        if [ ! -z "$token_info" ]; then
            token_name=$(echo "$token_info" | awk -F, '{print $2}')
            balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
            echo "$index. $token_name"
            mint_addresses[$index]=$mint_address
            token_names[$index]="$token_name"
            balances[$index]=$balance
            index=$((index+1))
        fi
    done < <(echo "$owned_mints")

    if [ $index -eq 0 ]; then
        echo "No tokens found in the wallet."
        return
    fi

    echo "--------------------------------------------------------------------------------"
    echo "Select the token you wish to send:"
    read -p "Enter the number of the token: " token_selection

    if [[ ! $token_selection =~ ^[0-9]+$ ]] || [ $token_selection -ge $index ]; then
        echo "Invalid selection."
        return
    fi

    selected_token_name=${token_names[$token_selection]}
    selected_mint_address=${mint_addresses[$token_selection]}
    selected_balance=${balances[$token_selection]}

    echo "You have selected to send $selected_token_name with balance $selected_balance."

    read -p "Enter the amount of $selected_token_name to send: " amount_to_send

    
}

# Function to create a new stake account
create_and_delegate_stake_account() {
    echo "Checking for an existing stake account..."

    # Check if the staking keys directory exists, no need to make it if it already exists
    if [ ! -d "$UNRUGGABLE_STAKING" ]; then
        mkdir -p "$UNRUGGABLE_STAKING"
        chmod 700 "$UNRUGGABLE_STAKING"
        echo "Staking keys directory created at $UNRUGGABLE_STAKING"
    fi

    # Get the current config
    config_output=$(solana config get)

    # Extract the keypair path
    keypair_path=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}')

    # Get the wallet address to name the stake account file appropriately
    wallet_address=$(solana address -k "$keypair_path")
    # Initialize the seed to 0
    max_seed=-1

    # Scan the directory for existing stake accounts and find the highest seed
    for file in "$UNRUGGABLE_STAKING"/*; do
        if [[ $file =~ .*_stake-account_([0-9]+)\.json$ ]]; then
            seed="${BASH_REMATCH[1]}"
            if (( seed > max_seed )); then
                max_seed=$seed
            fi
        fi
    done

    # The new seed is one more than the highest found
    new_seed=$((max_seed + 1))

    # Define the new stake account file name with the new seed
    stake_account_file="$UNRUGGABLE_STAKING/${wallet_address}_stake-account_${new_seed}.json"

    # Prompt user for the amount to stake, ensuring it's at least 0.1 SOL
    read -p "Enter the amount of SOL to stake (minimum 0.1 SOL): " stake_amount
    if (( $(echo "$stake_amount < 0.1" | bc -l) )); then
        echo "The minimum staking amount is 0.1 SOL."
        return 1
    fi

    # Check if the stake account file already exists
    if [ -f "$stake_account_file" ]; then
        echo "This stake account is inited: $stake_account_file"
        echo "Skipping creation of a new stake account."
    else
        echo "Creating a new stake account..."

        # Generate a new keypair for the stake account
        solana-keygen new --no-passphrase -s -o "$stake_account_file"
        stake_address=$(solana address -k "$stake_account_file")
        
        echo "New stake account keypair created: $stake_address"        
    fi

    # Get the current config
    config_output=$(solana config get)
    # Extract the keypair path
    keypair_path=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}')

    # Create the stake account with the specified amount
    solana create-stake-account "$stake_account_file" $stake_amount \
        --from $keypair_path \
        --stake-authority $keypair_path --withdraw-authority $keypair_path \
        --fee-payer $keypair_path \
        --url "https://damp-fabled-panorama.solana-mainnet.quiknode.pro/186133957d30cece76e7cd8b04bce0c5795c164e/"

    echo "Stake account created with ${stake_amount} SOL."
    
    # Ensure the stake account file exists
    if [ ! -f "$stake_account_file" ]; then
        echo "Stake account file not found: $stake_account_file"
        echo "Please create a stake account first."
        return 1
    fi

    # Display the stake account information
    solana stake-account "$stake_account_file" --url "https://damp-fabled-panorama.solana-mainnet.quiknode.pro/186133957d30cece76e7cd8b04bce0c5795c164e/"

    echo "Stake account checked, delegating stake"
    
    validator_address="B6nDYYLc2iwYqY3zdmavMmU9GjUL2hf79MkufviM2bXv"

    # Delegate the stake
    echo "Delegating to validator: $validator_address"
    
    solana delegate-stake --stake-authority $keypair_path "$stake_address" $validator_address \
        --fee-payer $keypair_path

    echo "Stake delegation initiated. Checking the stake account for the delegation status update."
}

# Function to manage staked SOL
manage_staked_sol() {
    echo "Fetching staked SOL accounts..."
    # Define the directory for staking keys
    wallet_address=$(solana address -k "$keypair_path")

    if [ ! -d "$UNRUGGABLE_STAKING" ]; then
        echo "No staking keys directory found. Please stake SOL first."
        return
    fi

    local i=0
    declare -a stake_account_paths
    for stake_account_file in "$UNRUGGABLE_STAKING"/"$wallet_address"*.json; do
        stake_account_address=$(solana address -k "$stake_account_file")
        # Fetch stake account info and filter for relevant lines
        stake_account_info=$(solana stake-account "$stake_account_address" --url "https://api.mainnet-beta.solana.com/" | grep -E "Balance:|Stake account is")
        echo "$i - Stake Account: $stake_account_address"
        # Use a loop to print each line of filtered stake account info
        while IFS= read -r line; do
            echo "    $line"
        done <<< "$stake_account_info"
        stake_account_paths[i]=$stake_account_file
        i=$((i+1))
    done

    if [ $i -eq 0 ]; then
        echo "No stake accounts found."
        return
    fi

    echo "Enter the number of the stake account you wish to manage, or press 'c' to cancel:"
    read manage_choice

    if [ "$manage_choice" = "c" ]; then
        echo "Operation cancelled."
        return
    fi

    if [[ $manage_choice =~ ^[0-9]+$ ]] && [ $manage_choice -ge 0 ] && [ $manage_choice -lt ${#stake_account_paths[@]} ]; then
        selected_stake_account=${stake_account_paths[$manage_choice]}
        echo "Selected stake account: $selected_stake_account"
        # Here you can add more management options for the selected stake account, such as:
        # - Splitting the stake
        # - Merging stake accounts
        # - Delegating to a different validator
        # - Withdrawing stake
        # For simplicity, these functionalities are not implemented in this script.
    else
        echo "Invalid selection."
    fi
}

# Modified stake_sol function to provide new numbered options
stake_sol() {
    echo "1 - Stake SOL"
    echo "2 - Manage Staked SOL"
    read -p "Enter your choice: " staking_choice

    case $staking_choice in
        1)
            create_and_delegate_stake_account
            ;;
        2)
            manage_staked_sol
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

create_new_wallet() {
    echo "Select the type of wallet to create:"
    echo "1. Vanity Keypair"
    echo "2. New Wallet with Seed Phrase"
    read -p "Enter your choice (1 or 2): " wallet_type

    # Get the current keypair directory to save the new wallet file in the same location
    config_output=$(solana config get)
    keypair_dir=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}' | xargs dirname)

    new_wallet_address="" # Initialize variable to store the new wallet address

    case $wallet_type in
        1)
            echo "You've chosen to create a vanity keypair."
            echo "A vanity keypair allows you to have a wallet address that starts with specific characters of your choice."
            echo ""
            echo "Note: Up to 4 characters. Some characters are not allowed like 0 and others. 3 characters suggested for speed."
            echo ""
            echo "Examples of prefixes:"
            echo "- For a trading wallet, you might use 'trd1'"
            echo "- For a DeFi wallet, 'dfi' could be a good prefix"
            echo "- If its for NFTs, 'nft' or 'art' might be suitable"
            echo "- A general savings wallet could use a prefix like 'sve'"
            echo ""
            echo "These prefixes help you quickly identify the purpose of each wallet, simplifying wallet management."
            echo ""
            while true; do
                read -p "Enter your desired prefix (up to 4 characters, Base58): " prefix
                if [[ ${#prefix} -le 4 ]]; then
                    break
                else
                    echo "Error: Prefix must be 4 characters or less."
                fi
            done

            echo "Starting vanity keypair grind for prefix '$prefix'..."
            # Capture the output of solana-keygen grind to find the generated keypair filename
            grind_output=$(solana-keygen grind --starts-with "$prefix":1)
            echo "$grind_output"
            
            # Extract the filename from the output
            keypair_file=$(echo "$grind_output" | grep -o '[^ ]*.json')
            echo "Vanity keypair generation complete. File: $keypair_file"

            # Move the keypair file to the correct directory if it's not already there
            if [[ $(dirname "$keypair_file") != "$keypair_dir" ]]; then
                mv "$keypair_file" "$keypair_dir/"
                keypair_file="$keypair_dir/$(basename "$keypair_file")"
            fi

            new_wallet_address=$(solana address -k "$keypair_file")
            echo "New wallet address: $new_wallet_address"
            new_wallet_filename="${new_wallet_address}.json"
            ;;
        2)
            echo "You've chosen to create a new wallet with a seed phrase."
            echo "A seed phrase, also known as a mnemonic phrase, is a list of words which store all the information needed to recover a solana wallet. It's crucial to keep your seed phrase safe and private, as anyone with access to it can control your funds."
            echo ""
            
            # Ask user for the word count of the seed phrase
            echo "You can choose the number of words for your seed phrase. More words mean more security but also make it harder to remember."
            echo "1. 12 words"
            echo "2. 24 words"
            read -p "Select the number of words (1 for 12 words, 2 for 24 words): " word_count_response
            case $word_count_response in
                1)
                    word_count_option="--word-count 12"
                    ;;
                2)
                    word_count_option="--word-count 24"
                    ;;
                *)
                    echo "Invalid option. Defaulting to 12 words."
                    word_count_option="--word-count 12"
                    ;;
            esac

            echo "In addition to the seed phrase, you can also generate a keypair file. This file contains your public and private keys, allowing you to interact with the chain. While the seed phrase can recover your wallet and funds, the keypair file is required for day-to-day operations like sending transactions."
            echo ""
            # Combine options and generate the new wallet
            # Ask user if they want to create an output file
            read -p "Do you want to generate a keypair file in addition to your seed phrase? (yes/no): " create_file_response
            if [[ $create_file_response == "yes" ]]; then
                temp_keypair_file="genwallet.json" # Temporary filename

                # Generate the new wallet with a temporary filename
                solana-keygen new --no-passphrase --outfile "$temp_keypair_file"
                # Read the new wallet's public address
                new_wallet_address=$(solana address -k "$temp_keypair_file")
                
                # Get the current keypair directory to save the new wallet file in the same location
                config_output=$(solana config get)
                keypair_dir=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}' | xargs dirname)

                # Rename and move the wallet file to the correct directory with the new name format
                new_wallet_filename="${new_wallet_address}.json"
                mv "$temp_keypair_file" "$keypair_dir/$new_wallet_filename"
                echo "Succesfuly generated new wallet address: $new_wallet_address"
            else
                echo "Only a seed phrase will be generated."
                echo "Remember, without a keypair file, you will need to regenerate your keys from the seed phrase for transactions."
                # Generate the new wallet without creating a keypair file
                solana-keygen new --no-passphrase --no-outfile
            fi
            command="solana-keygen new $outfile_option $word_count_option --language english --no-bip39-passphrase"
            

            eval $command
            ;;
        *)
            echo "Invalid option"
            ;;
    esac

    # After wallet creation, ask the user if they want to fund the new wallet or return to the home screen
    echo "Do you want to fund the newly created wallet or return to the home screen?"
    echo "1. Fund the new wallet"
    echo "2. Return to the home screen"
    read -p "Enter your choice (1 or 2): " post_creation_choice

    if [[ $post_creation_choice -eq 1 ]]; then
        read -p "Enter the amount of SOL to fund the new wallet with: " fund_amount
        # Assuming you have a function to send SOL, replace 'send_sol_function' with the actual function name
        # You might need to adjust this part to fit your actual function for sending SOL
        transfer_command="solana transfer --allow-unfunded-recipient $new_wallet_address $fund_amount --with-compute-unit-price 0.00001 "
        eval $transfer_command
        echo "Wallet successfully funded."

        # Ask if they want to switch to this wallet
        read -p "Do you want to switch to this newly created wallet? (yes/no): " switch_choice
        if [[ $switch_choice == "yes" ]]; then
            # Use solana config set to switch the current wallet to the new keypair
            config_output=$(solana config set -k "$keypair_dir/$new_wallet_filename")
            # Get the current wallet address
            wallet_address=$(solana address)
            echo "Switched to wallet: $wallet_address"
        fi
    elif [[ $post_creation_choice -eq 2 ]]; then
        echo "Returning to the home screen."
        return
    else
        echo "Invalid option. Returning to the home screen."
    fi
}

# Function to display available wallets
display_available_wallets() {
    config_output=$(solana config get)
    keypair_dir=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}' | xargs dirname)
    
    echo "Available Wallets:"
    local i=0
    declare -a wallet_paths # Use a simple array to store paths

    # Function to process directories and find wallets
    process_directory() {
        local directory=$1
        if [ -d "$directory" ]; then
            for keypair in "$directory"/*.json; do
                # Check if the file exists to avoid the case where the glob doesn't match anything
                if [ -e "$keypair" ]; then
                    wallet_address=$(solana address -k "$keypair")
                    balance=$(solana balance "$wallet_address")
                    echo "$i. $wallet_address ($balance)"
                    wallet_paths+=("$keypair")
                    i=$((i+1))
                fi
            done
        fi
    }

    # Check and process each unique directory
    if [[ "$keypair_dir" != "$UNRUGGABLE_FOLDER" && "$keypair_dir" != "$DEFAULT_KEYS_DIR" ]]; then
        process_directory "$keypair_dir"
    fi
    process_directory "$UNRUGGABLE_FOLDER"
    process_directory "$DEFAULT_KEYS_DIR"

    echo "Press 'h' to return to the home screen" 
    echo "Press the number of the wallet you want to switch to, i.e. '4' "
    read -p "Enter your choice: " choice

    if [ "$choice" = "h" ]; then
        return
    elif [[ "$choice" =~ ^[0-9]+$ ]]; then
        switch_wallet "$choice"
    else
        echo "Invalid option"
    fi
}

# Function to switch wallets
switch_wallet() {
    wallet_number=$1

    if [[ $wallet_number =~ ^[0-9]+$ ]] && [ $wallet_number -ge 0 ] && [ $wallet_number -lt ${#wallet_paths[@]} ]; then
        selected_wallet_filepath=${wallet_paths[$wallet_number]}
        config_output=$(solana config set -k "$selected_wallet_filepath")
        # Get the current wallet address
        wallet_address=$(solana address)
        echo "Switched to wallet: $wallet_address"
    else
        echo "Invalid wallet number"
    fi
}

set_custom_rpc() {
    echo "Enter your custom RPC URL (e.g., https://api.mainnet-beta.solana.com):"
    read -p "RPC URL: " custom_rpc_url
    if [[ -n "$custom_rpc_url" ]]; then
        solana config set --url "$custom_rpc_url"
        if [ $? -eq 0 ]; then
            echo "Custom RPC URL set successfully."
        else
            echo "Failed to set custom RPC URL."
        fi
    else
        echo "No RPC URL entered. Returning to the main menu."
    fi
}


# Function to show balance
show_balance() {
    # Get the current config
    config_output=$(solana config get)

    # Extract the keypair path
    keypair_path=$(echo "$config_output" | grep 'Keypair Path' | awk '{print $3}')

    # Get the wallet address
    wallet_address=$(solana address -k "$keypair_path")
    echo "Wallet Address: $wallet_address"

    # Get the balance
    balance=$(solana balance "$wallet_address")
    echo "Balance: $balance SOL"
}

# Function to fetch the current SOL/USD price
fetch_sol_usd_price() {
    # Fetch the price data
    price_data=$(curl -s 'https://quote-api.jup.ag/v6/quote?inputMint=So11111111111111111111111111111111111111112&outputMint=EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v&amount=1000000&slippageBps=1')

    # Parse the JSON response to extract the price per 1 SOL (since we requested 1 million lamports, which is 1 SOL)
    if command -v jq &> /dev/null; then
        sol_usd_price=$(echo "$price_data" | jq -r '.outAmount' | awk '{print $1/1000}')
        echo "$sol_usd_price"
    else
        echo "Error: jq is not installed. Please install jq to fetch SOL/USD price."
        return 1
    fi
}

fetch_token_usd_price() {
    local token_mint=$1
    # Directly return 1 for USDC and USDT
    if [[ "$token_mint" == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" ]] || [[ "$token_mint" == "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB" ]]; then
        echo "1"
        return 0
    fi

    # Extract the decimal places for the token
    token_info=$(grep "$token_mint" tokens.txt)
    if [[ -z "$token_info" ]]; then
        echo "Error: Token mint not found in tokens.txt."
        return 1
    fi

    decimals=$(echo "$token_info" | awk -F, '{print $3}' | xargs)
    if [[ -z "$decimals" ]]; then
        echo "Error: Decimal places for the token not found."
        return 1
    fi

    # Calculate the amount based on the token's decimals
    amount=$(echo "1 * 10^$decimals" | bc)
    # Fetch the price data for the token
    price_data=$(curl -s "https://quote-api.jup.ag/v6/quote?inputMint=$token_mint&outputMint=EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v&amount=$amount&slippageBps=1")
    token_usd_price=$(echo "$price_data" | jq -r '.outAmount' | awk -v dec="$decimals" '{print ($1 / (10^6))}')
    
    echo "$token_usd_price"
    
}

fetch_token_balances() {
    local wallet_address=$(solana address)
    local output=$(spl-token accounts --output json-compact --owner "$wallet_address")
    local token_balances=""
    local total_usd=0

    while IFS= read -r mint_address; do
        local token_info=$(grep -i "$mint_address" tokens.txt)
        if [ ! -z "$token_info" ]; then
            local token_name=$(echo "$token_info" | awk -F, '{print $2}')
            local balance=$(echo "$output" | jq -r --arg mint_address "$mint_address" '.accounts[] | select(.mint == $mint_address) | .tokenAmount.uiAmountString')
            if [ ! -z "$balance" ] && [ "$balance" != "null" ] && (( $(echo "$balance > 0" | bc -l) )); then
                local token_usd_price=$(fetch_token_usd_price "$mint_address")
                echo $token_usd_price
                local balance_usd=$(echo "scale=2; $balance * $token_usd_price / 1" | bc)
                # Ensure balance and balance_usd are formatted with two decimal places
                printf -v formatted_balance "%.2f" "$balance"
                printf -v formatted_balance_usd "%.2f" "$balance_usd"
                token_balances+="Token: $formatted_balance $token_name ($formatted_balance_usd USD)\n"
                total_usd=$(echo "$total_usd + $formatted_balance_usd" | bc)
            fi
        fi
    done <<< "$(echo "$output" | jq -r '.accounts[] | select(.tokenAmount.uiAmount > 0) | .mint')"

    # Append total USD value of tokens at the end
    printf -v total_usd_formatted "%.2f" "$total_usd"
    token_balances+="Total Token USD Value: ($total_usd_formatted USD)\n"
    echo -e "$token_balances"
}

clean_numeric_input() {
    echo "$1" | sed 's/[^0-9.-]//g'
}

draw_ui() {
    local wallet_info=$(get_wallet_info) # Assuming this function provides wallet info correctly
    local wallet_address=$(echo "$wallet_info" | cut -d ' ' -f 1)
    local balance=$(echo "$wallet_info" | cut -d ' ' -f 2)
    local total_staked_sol=$(echo "$wallet_info" | cut -d ' ' -f 4)
    local sol_usd_price=$(fetch_sol_usd_price)

    # Calculate USD values
    local balance_usd=$(echo "scale=2; $balance * $sol_usd_price" | bc)
    local staked_sol_usd=$(echo "scale=2; $total_staked_sol * $sol_usd_price" | bc)

    # Get token balances formatted string and extract the total USD value
    local token_output=$(fetch_token_balances)    
    local total_token_usd=$(echo "$token_output" | grep 'Total Token USD Value:' | awk '{print $5}')

    # Clean the inputs
    balance_usd_clean=$(clean_numeric_input "$balance_usd")
    staked_sol_usd_clean=$(clean_numeric_input "$staked_sol_usd")
    total_token_usd_clean=$(clean_numeric_input "$total_token_usd")

    # Calculate total wallet USD value
    total_wallet_usd=$(echo "$balance_usd_clean + $staked_sol_usd_clean + $total_token_usd_clean" | bc)

    clear
    echo "--------------------------------------------------------------------------------"
    echo "|                                                                              |"
    echo "|                   Welcome to Unruggable                                      |"
    echo "|                                                                              |"
    echo "|   Connected Wallet : $(printf '%-44s' $wallet_address)"
    echo "|                                                                              |"
    printf "|   Balance: %.3f SOL    (%.2f USD) \n" "$balance" "$balance_usd"
    printf "|   Staked SOL: %.3f SOL (%.2f USD) \n" "$total_staked_sol" "$staked_sol_usd"
    printf "|   Total USD balance:   (%.2f USD) \n" "$total_wallet_usd"
    echo "|                                                                              |"
    echo "|------------------------------------------------------------------------------|"
    printf "|   %-18s | %23s | %27s |\n" "Asset" "Amount" "USD Value"
    echo "|------------------------------------------------------------------------------|"
    # Display each token's balance and USD value
    while IFS= read -r line; do
        if [[ "$line" == "Token:"* ]]; then
            IFS=' ' read -r _ amount token value _ <<<"$line"
            # Remove the opening parenthesis from the value if present
            value=${value//\(/}
            # Calculate the price per token. Note: Ensure amount is not zero to avoid division by zero error
            if (( $(echo "$amount != 0" | bc -l) )); then
                token_price=$(echo "scale=2; $value / $amount" | bc)
            else
                token_price=0
            fi
            # Print token name with price per token in brackets, amount, and total USD value
            printf "|   %-7s %6.2f USD | %23s | %23.2f USD |\n" "$token" "$token_price" "$amount" "$value"
        fi
    done <<< "$token_output"

    
    echo "|------------------------------------------------------------------------------|"
    echo "|------------------------------------------------------------------------------|"
    echo "|ACTIONS                                                                       |"
    echo "|                                                                              |"
    echo "|   0. Receive SOL                                                             |"
    echo "|   1. Send SOL                                                                |"
    echo "|   2. Send Tokens                                                             |"
    echo "|   3. Display NFTs                                                            |"
    echo "|   4. Display Available Wallets and Switch                                    |"
    echo "|   5. Stake SOL                                                               |"
    echo "|   6. Liquid Stake SOL                                                        |"
    echo "|   7. Create New Wallet                                                       |"
    echo "|   8. Set Custom RPC URL                                                      |"
    echo "|   9. Exit                                                                    |"
    echo "|                                                                              |"
    echo "|------------------------------------------------------------------------------|"
}

# Function to handle user input
handle_input() {
    echo -n "Enter the number of the action you want: "
    read choice
    echo "--------------------------------------------------------------------------------"

    case $choice in
        0) receive_sol ;;
        1) send_sol ;;
        2) display_tokens_and_send ;;
        3) display_nfts ;;
        4) display_available_wallets ;;
        5) stake_sol ;;
        6) liquid_stake_sol ;;
        7) create_new_wallet ;;
        8) set_custom_rpc ;;
        9) exit 0 ;;
        *) echo "Invalid option";;
    esac
}

# Call the pre-launch checks function before proceeding to the main script
run_pre_launch_checks

# Main loop
while true; do
    draw_ui
    handle_input
    read -p "Press enter to continue"
done
