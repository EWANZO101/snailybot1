#!/bin/bash

# SnailyCAD Bot Automated Setup Script
# This script automates the installation and configuration of the SnailyCAD bot

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate random password
generate_password() {
    openssl rand -base64 16 | tr -d "=+/" | cut -c1-16
}

# Function to generate random database name
generate_db_name() {
    echo "snailycad_$(openssl rand -hex 4)"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if ! command_exists node; then
        missing_deps+=("node.js")
    fi
    
    if ! command_exists yarn; then
        missing_deps+=("yarn")
    fi
    
    if ! command_exists psql; then
        missing_deps+=("postgresql")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and run this script again."
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_warning "Node.js version 18 or higher is recommended. Current version: $(node -v)"
    fi
    
    print_success "All prerequisites are installed!"
}

# Function to navigate to appropriate directory
navigate_to_safe_directory() {
    print_info "Navigating to safe installation directory..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        TARGET_DIR="$HOME"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        TARGET_DIR="$HOME/Documents"
    else
        TARGET_DIR="$HOME"
    fi
    
    cd "$TARGET_DIR" || exit 1
    print_success "Changed directory to: $(pwd)"
}

# Function to clone repository
clone_repository() {
    print_info "Checking if repository already exists..."
    
    if [ -d "snailycad-bot" ]; then
        print_warning "Directory 'snailycad-bot' already exists."
        read -p "Do you want to remove it and clone fresh? (y/n): " -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf snailycad-bot
            print_info "Removed existing directory."
        else
            print_info "Using existing directory."
            cd snailycad-bot || exit 1
            return
        fi
    fi
    
    print_info "Cloning SnailyCAD bot repository..."
    git clone https://github.com/SnailyCAD/snailycad-bot.git
    cd snailycad-bot || exit 1
    print_success "Repository cloned successfully!"
}

# Function to install dependencies
install_dependencies() {
    print_info "Installing dependencies with yarn..."
    yarn install
    print_success "Dependencies installed successfully!"
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

# Function to get password input (hidden)
get_password() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [ -n "$default" ]; then
        read -sp "$prompt [$default]: " value
        echo
        echo "${value:-$default}"
    else
        read -sp "$prompt: " value
        echo
        echo "$value"
    fi
}

# Function to configure database
configure_database() {
    print_info "Setting up PostgreSQL database..."
    echo
    
    # Generate defaults
    DEFAULT_DB_NAME=$(generate_db_name)
    DEFAULT_DB_USER="snailycad_user"
    DEFAULT_DB_PASSWORD=$(generate_password)
    
    # Get database configuration from user
    print_info "Please provide database configuration (or press Enter for defaults):"
    echo
    
    DB_NAME=$(get_input "Database name" "$DEFAULT_DB_NAME")
    DB_USER=$(get_input "Database user" "$DEFAULT_DB_USER")
    DB_PASSWORD=$(get_password "Database password" "$DEFAULT_DB_PASSWORD")
    DB_HOST=$(get_input "Database host" "localhost")
    DB_PORT=$(get_input "Database port" "5432")
    
    echo
    print_info "Database configuration:"
    print_info "  Database: $DB_NAME"
    print_info "  User: $DB_USER"
    print_info "  Host: $DB_HOST"
    print_info "  Port: $DB_PORT"
    echo
    
    # Get PostgreSQL superuser credentials
    print_info "Enter PostgreSQL superuser credentials (usually 'postgres'):"
    PG_SUPERUSER=$(get_input "PostgreSQL superuser" "postgres")
    
    # Create database and user
    print_info "Creating database and user..."
    
    # Create user
    psql -U "$PG_SUPERUSER" -h "$DB_HOST" -p "$DB_PORT" -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || {
        print_warning "User '$DB_USER' might already exist, continuing..."
    }
    
    # Create database
    psql -U "$PG_SUPERUSER" -h "$DB_HOST" -p "$DB_PORT" -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || {
        print_warning "Database '$DB_NAME' might already exist, continuing..."
    }
    
    # Grant privileges
    psql -U "$PG_SUPERUSER" -h "$DB_HOST" -p "$DB_PORT" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || {
        print_warning "Could not grant privileges, user might already have them..."
    }
    
    print_success "Database setup complete!"
}

# Function to configure .env file
configure_env() {
    print_info "Configuring environment variables..."
    
    # Check if .env.example exists
    if [ ! -f ".env.example" ]; then
        print_error ".env.example file not found!"
        exit 1
    fi
    
    # Copy .env.example to .env
    cp .env.example .env
    print_success "Copied .env.example to .env"
    
    # Get bot token
    echo
    print_info "Please provide your Discord bot token:"
    print_warning "To get a bot token, visit: https://discord.com/developers/applications"
    BOT_TOKEN=$(get_password "Discord Bot Token")
    
    # Update .env file
    print_info "Updating .env file with configuration..."
    
    # Use sed or perl to update the .env file
    if command_exists sed; then
        sed -i.bak "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=\"$DB_PASSWORD\"/" .env
        sed -i.bak "s/^POSTGRES_USER=.*/POSTGRES_USER=\"$DB_USER\"/" .env
        sed -i.bak "s/^DB_HOST=.*/DB_HOST=\"$DB_HOST\"/" .env
        sed -i.bak "s/^DB_PORT=.*/DB_PORT=\"$DB_PORT\"/" .env
        sed -i.bak "s/^POSTGRES_DB=.*/POSTGRES_DB=\"$DB_NAME\"/" .env
        sed -i.bak "s/^BOT_TOKEN=.*/BOT_TOKEN=\"$BOT_TOKEN\"/" .env
        rm -f .env.bak
    else
        # Manual update if sed is not available
        cat > .env << EOF
POSTGRES_PASSWORD="$DB_PASSWORD"
POSTGRES_USER="$DB_USER"
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"
POSTGRES_DB="$DB_NAME"
BOT_TOKEN="$BOT_TOKEN"
EOF
    fi
    
    print_success ".env file configured successfully!"
    
    # Save credentials to a file for reference
    print_info "Saving credentials to credentials.txt for your reference..."
    cat > credentials.txt << EOF
SnailyCAD Bot Credentials
========================
Generated on: $(date)

Database Configuration:
- Database Name: $DB_NAME
- Database User: $DB_USER
- Database Password: $DB_PASSWORD
- Database Host: $DB_HOST
- Database Port: $DB_PORT

Bot Token: $BOT_TOKEN

IMPORTANT: Keep this file secure and do not share it publicly!
EOF
    
    chmod 600 credentials.txt
    print_success "Credentials saved to credentials.txt"
}

# Function to build the bot
build_bot() {
    print_info "Building the bot..."
    echo
    yarn build
    echo
    print_success "Bot built successfully!"
}

# Function to create systemd service
create_systemd_service() {
    print_info "Setting up systemd service..."
    echo
    
    local bot_dir=$(pwd)
    local service_name="snailycad-bot"
    
    read -p "Do you want to create a systemd service to auto-start the bot? (y/n): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping systemd service creation."
        return
    fi
    
    # Create service file
    cat > /tmp/${service_name}.service << EOF
[Unit]
Description=SnailyCAD Discord Bot
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$bot_dir
ExecStart=$(which yarn) start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=snailycad-bot

[Install]
WantedBy=multi-user.target
EOF
    
    # Install service
    print_info "Installing systemd service..."
    sudo cp /tmp/${service_name}.service /etc/systemd/system/${service_name}.service
    sudo chmod 644 /etc/systemd/system/${service_name}.service
    sudo systemctl daemon-reload
    
    print_success "Systemd service created!"
    
    # Ask if user wants to enable and start
    read -p "Do you want to enable the service to start on boot? (y/n): " -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl enable ${service_name}
        print_success "Service enabled for auto-start on boot!"
    fi
    
    read -p "Do you want to start the bot service now? (y/n): " -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl start ${service_name}
        sleep 2
        sudo systemctl status ${service_name} --no-pager
        print_success "Bot service started!"
    fi
    
    # Create helpful aliases
    print_info "Creating helpful command aliases..."
    
    local alias_file=""
    if [ -f "$HOME/.bashrc" ]; then
        alias_file="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        alias_file="$HOME/.zshrc"
    fi
    
    if [ -n "$alias_file" ]; then
        echo "" >> "$alias_file"
        echo "# SnailyCAD Bot aliases" >> "$alias_file"
        echo "alias botstart='sudo systemctl start ${service_name}'" >> "$alias_file"
        echo "alias botstop='sudo systemctl stop ${service_name}'" >> "$alias_file"
        echo "alias botrestart='sudo systemctl restart ${service_name}'" >> "$alias_file"
        echo "alias botstatus='sudo systemctl status ${service_name}'" >> "$alias_file"
        echo "alias botlogs='sudo journalctl -u ${service_name} -f'" >> "$alias_file"
        
        print_success "Aliases created! Run 'source $alias_file' or restart your terminal."
        
        # Save aliases info to file
        cat >> service-commands.txt << EOF

SnailyCAD Bot Service Commands
==============================

Service Management:
- Start bot:     botstart    (or: sudo systemctl start ${service_name})
- Stop bot:      botstop     (or: sudo systemctl stop ${service_name})
- Restart bot:   botrestart  (or: sudo systemctl restart ${service_name})
- Bot status:    botstatus   (or: sudo systemctl status ${service_name})
- View logs:     botlogs     (or: sudo journalctl -u ${service_name} -f)

To enable auto-start on boot:
  sudo systemctl enable ${service_name}

To disable auto-start:
  sudo systemctl disable ${service_name}

To reload after editing .env:
  botrestart

Note: Aliases will be available after running 'source $alias_file' or restarting your terminal.
EOF
        
        print_info "Service commands saved to service-commands.txt"
    fi
}

# Function to display final instructions
display_final_instructions() {
    echo
    echo "========================================"
    print_success "Setup Complete!"
    echo "========================================"
    echo
    print_info "Your SnailyCAD bot has been set up successfully!"
    echo
    
    if [ -f "service-commands.txt" ]; then
        print_info "Bot is running as a systemd service!"
        echo
        print_info "Quick commands:"
        echo "  - Start:   botstart"
        echo "  - Stop:    botstop"
        echo "  - Status:  botstatus"
        echo "  - Logs:    botlogs"
        echo
        print_info "Full service commands saved to: $(pwd)/service-commands.txt"
    else
        print_info "To start the bot manually, run:"
        echo "  cd $(pwd)"
        echo "  yarn start"
        echo
        print_info "For background execution, consider:"
        echo "  - Re-run this script and choose systemd service option"
        echo "  - Or use PM2: npm install -g pm2 && pm2 start 'yarn start' --name snailycad-bot"
    fi
    
    echo
    print_info "Important files:"
    echo "  - Credentials: $(pwd)/credentials.txt"
    echo "  - Environment: $(pwd)/.env"
    if [ -f "service-commands.txt" ]; then
        echo "  - Service Commands: $(pwd)/service-commands.txt"
    fi
    echo
    print_warning "Security reminders:"
    echo "  - Keep your credentials.txt file secure"
    echo "  - Never commit .env to version control"
    echo "  - Regularly update your dependencies with 'yarn upgrade'"
    echo
}

# Main execution
main() {
    echo "========================================"
    echo "  SnailyCAD Bot Setup Script"
    echo "========================================"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Navigate to safe directory
    navigate_to_safe_directory
    
    # Clone repository
    clone_repository
    
    # Install dependencies
    install_dependencies
    
    # Configure database
    configure_database
    
    # Configure .env
    configure_env
    
    # Build bot
    build_bot
    
    # Create systemd service (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        create_systemd_service
    else
        print_warning "Systemd service creation is only available on Linux."
        print_info "For other platforms, use PM2 or run manually with 'yarn start'."
    fi
    
    # Display final instructions
    display_final_instructions
}

# Run main function
main
