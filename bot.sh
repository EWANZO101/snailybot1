#!/bin/bash

# SnailyCAD Bot Automated Setup Script with Self-Healing
# This script automates the installation and configuration of the SnailyCAD bot
# with automatic error detection, recovery, and healing capabilities

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Self-healing configuration
MAX_RETRY_ATTEMPTS=3
RETRY_DELAY=5
HEALTH_CHECK_INTERVAL=30
LOG_FILE="$HOME/snailycad-setup.log"
STATE_FILE="$HOME/.snailycad-setup-state"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS" "$1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_message "WARNING" "$1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
}

print_healing() {
    echo -e "${MAGENTA}[HEALING]${NC} $1"
    log_message "HEALING" "$1"
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

# Function to save setup state
save_state() {
    local step="$1"
    echo "$step" > "$STATE_FILE"
    log_message "STATE" "Saved state: $step"
}

# Function to get current state
get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "none"
    fi
}

# Function to clear state
clear_state() {
    rm -f "$STATE_FILE"
    log_message "STATE" "Cleared state file"
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

# Function to retry command with exponential backoff
retry_command() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local command="$@"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_info "Attempt $attempt of $max_attempts: $command"
        
        if eval "$command"; then
            print_success "Command succeeded on attempt $attempt"
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                print_warning "Command failed. Retrying in ${delay}s..."
                sleep $delay
                delay=$((delay * 2))  # Exponential backoff
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    print_error "Command failed after $max_attempts attempts"
    return 1
}

# Function to check and heal network connectivity
heal_network() {
    print_healing "Checking network connectivity..."
    
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_warning "Network connectivity issue detected"
        print_healing "Attempting to restore network..."
        
        # Try to restart network manager (if available)
        if command_exists nmcli; then
            retry_command 2 3 "sudo nmcli networking off && sleep 2 && sudo nmcli networking on"
        fi
        
        # Wait and recheck
        sleep 5
        if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            print_error "Unable to restore network connectivity. Please check your network settings."
            return 1
        fi
        
        print_success "Network connectivity restored"
    fi
    
    return 0
}

# Function to check and install missing dependencies
heal_dependencies() {
    print_healing "Checking and healing dependencies..."
    
    local missing_deps=()
    local need_install=false
    
    # Check each dependency
    if ! command_exists git; then
        missing_deps+=("git")
        need_install=true
    fi
    
    if ! command_exists node; then
        missing_deps+=("nodejs")
        need_install=true
    fi
    
    if ! command_exists yarn; then
        missing_deps+=("yarn")
        need_install=true
    fi
    
    if ! command_exists psql; then
        missing_deps+=("postgresql")
        need_install=true
    fi
    
    if [ "$need_install" = true ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        print_healing "Attempting to install missing dependencies..."
        
        # Detect package manager and install
        if command_exists apt-get; then
            print_info "Detected apt package manager"
            retry_command 3 5 "sudo apt-get update"
            
            for dep in "${missing_deps[@]}"; do
                if [ "$dep" = "nodejs" ]; then
                    retry_command 3 5 "sudo apt-get install -y nodejs npm"
                elif [ "$dep" = "yarn" ]; then
                    retry_command 3 5 "sudo npm install -g yarn"
                elif [ "$dep" = "postgresql" ]; then
                    retry_command 3 5 "sudo apt-get install -y postgresql postgresql-contrib"
                    retry_command 2 3 "sudo systemctl start postgresql"
                    retry_command 2 3 "sudo systemctl enable postgresql"
                else
                    retry_command 3 5 "sudo apt-get install -y $dep"
                fi
            done
        elif command_exists yum; then
            print_info "Detected yum package manager"
            for dep in "${missing_deps[@]}"; do
                if [ "$dep" = "nodejs" ]; then
                    retry_command 3 5 "sudo yum install -y nodejs npm"
                elif [ "$dep" = "yarn" ]; then
                    retry_command 3 5 "sudo npm install -g yarn"
                else
                    retry_command 3 5 "sudo yum install -y $dep"
                fi
            done
        elif command_exists brew; then
            print_info "Detected Homebrew package manager"
            for dep in "${missing_deps[@]}"; do
                if [ "$dep" = "nodejs" ]; then
                    retry_command 3 5 "brew install node"
                elif [ "$dep" = "yarn" ]; then
                    retry_command 3 5 "brew install yarn"
                elif [ "$dep" = "postgresql" ]; then
                    retry_command 3 5 "brew install postgresql"
                    retry_command 2 3 "brew services start postgresql"
                else
                    retry_command 3 5 "brew install $dep"
                fi
            done
        else
            print_error "Could not detect package manager. Please install dependencies manually:"
            echo "  ${missing_deps[*]}"
            return 1
        fi
        
        print_success "Dependencies installed/healed successfully"
    fi
    
    return 0
}

# Function to check prerequisites with healing
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check network first
    if ! heal_network; then
        print_error "Network healing failed. Cannot continue."
        exit 1
    fi
    
    # Check and heal dependencies
    if ! heal_dependencies; then
        print_error "Dependency healing failed. Please install manually."
        exit 1
    fi
    
    # Verify all dependencies are now available
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
        print_error "Still missing required dependencies after healing: ${missing_deps[*]}"
        print_info "Please install the missing dependencies manually and run this script again."
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_warning "Node.js version 18 or higher is recommended. Current version: $(node -v)"
        print_healing "Attempting to upgrade Node.js..."
        
        if command_exists nvm; then
            retry_command 2 5 "nvm install 18 && nvm use 18"
        else
            print_warning "Cannot auto-upgrade Node.js. Please upgrade manually if issues occur."
        fi
    fi
    
    print_success "All prerequisites are installed and verified!"
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
    
    # Ensure directory exists and is writable
    if [ ! -d "$TARGET_DIR" ]; then
        print_healing "Creating target directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi
    
    if [ ! -w "$TARGET_DIR" ]; then
        print_error "Directory $TARGET_DIR is not writable"
        return 1
    fi
    
    cd "$TARGET_DIR" || exit 1
    print_success "Changed directory to: $(pwd)"
}

# Function to verify and heal git repository
heal_repository() {
    print_healing "Verifying repository integrity..."
    
    if [ ! -d ".git" ]; then
        print_error "Not a git repository. Repository needs to be cloned."
        return 1
    fi
    
    # Check if repository is corrupted
    if ! git status >/dev/null 2>&1; then
        print_warning "Git repository appears corrupted"
        print_healing "Attempting to repair..."
        
        git fsck --full 2>/dev/null || {
            print_error "Repository is severely corrupted. Will need to re-clone."
            cd ..
            rm -rf snailycad-bot
            return 1
        }
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "Uncommitted changes detected"
        print_healing "Stashing changes..."
        git stash push -m "Auto-stash before healing $(date)"
    fi
    
    # Ensure we're on the correct branch and up to date
    print_healing "Updating repository..."
    git fetch origin || {
        print_warning "Could not fetch updates. Continuing with local version."
        return 0
    }
    
    # Get default branch name
    DEFAULT_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs)
    
    git checkout "$DEFAULT_BRANCH" 2>/dev/null || git checkout main 2>/dev/null || git checkout master 2>/dev/null
    git pull origin "$DEFAULT_BRANCH" 2>/dev/null || print_warning "Could not pull latest changes"
    
    print_success "Repository verified and updated"
    return 0
}

# Function to clone repository with healing
clone_repository() {
    print_info "Checking if repository already exists..."
    
    if [ -d "snailycad-bot" ]; then
        print_warning "Directory 'snailycad-bot' already exists."
        cd snailycad-bot || exit 1
        
        if heal_repository; then
            print_success "Using existing repository"
            return 0
        else
            print_warning "Repository healing failed, will re-clone"
            cd ..
            rm -rf snailycad-bot
        fi
    fi
    
    print_info "Cloning SnailyCAD bot repository..."
    
    if ! retry_command 3 5 "git clone https://github.com/SnailyCAD/snailycad-bot.git"; then
        print_error "Failed to clone repository after multiple attempts"
        exit 1
    fi
    
    cd snailycad-bot || exit 1
    print_success "Repository cloned successfully!"
    save_state "repository_cloned"
}

# Function to heal corrupted node_modules
heal_node_modules() {
    print_healing "Checking node_modules integrity..."
    
    if [ -d "node_modules" ]; then
        # Check if node_modules is corrupted or incomplete
        if [ ! -f "node_modules/.yarn-integrity" ] && [ ! -f "node_modules/.package-lock.json" ]; then
            print_warning "node_modules appears corrupted or incomplete"
            print_healing "Removing and reinstalling..."
            rm -rf node_modules
            rm -f yarn.lock package-lock.json
            return 1
        fi
    fi
    
    return 0
}

# Function to install dependencies with healing
install_dependencies() {
    print_info "Installing dependencies with yarn..."
    
    # Heal node_modules if needed
    heal_node_modules
    
    # Clear yarn cache if previous attempts failed
    if ! retry_command 2 5 "yarn install"; then
        print_warning "Installation failed. Clearing cache and retrying..."
        yarn cache clean
        rm -rf node_modules yarn.lock
        
        if ! retry_command 2 10 "yarn install"; then
            print_error "Failed to install dependencies after multiple attempts"
            exit 1
        fi
    fi
    
    print_success "Dependencies installed successfully!"
    save_state "dependencies_installed"
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

# Function to test database connectivity
test_database_connection() {
    local host="$1"
    local port="$2"
    local user="$3"
    local db="$4"
    local password="$5"
    
    PGPASSWORD="$password" psql -h "$host" -p "$port" -U "$user" -d "$db" -c "SELECT 1;" >/dev/null 2>&1
}

# Function to heal PostgreSQL service
heal_postgresql() {
    print_healing "Checking PostgreSQL service..."
    
    # Check if PostgreSQL is running
    if ! pgrep -x postgres >/dev/null && ! pgrep -x postgresql >/dev/null; then
        print_warning "PostgreSQL is not running"
        print_healing "Attempting to start PostgreSQL..."
        
        if command_exists systemctl; then
            retry_command 2 3 "sudo systemctl start postgresql"
            retry_command 2 3 "sudo systemctl enable postgresql"
        elif command_exists service; then
            retry_command 2 3 "sudo service postgresql start"
        elif command_exists brew; then
            retry_command 2 3 "brew services start postgresql"
        else
            print_error "Cannot start PostgreSQL automatically. Please start it manually."
            return 1
        fi
        
        # Wait for PostgreSQL to be ready
        sleep 5
        print_success "PostgreSQL started"
    fi
    
    return 0
}

# Function to configure database with healing
configure_database() {
    print_info "Setting up PostgreSQL database..."
    echo
    
    # Heal PostgreSQL first
    if ! heal_postgresql; then
        print_error "PostgreSQL healing failed"
        exit 1
    fi
    
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
    
    # Create database and user with retry logic
    print_info "Creating database and user..."
    
    # Create user
    if ! retry_command 2 3 "psql -U \"$PG_SUPERUSER\" -h \"$DB_HOST\" -p \"$DB_PORT\" -c \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';\""; then
        print_warning "User '$DB_USER' might already exist, continuing..."
    fi
    
    # Create database
    if ! retry_command 2 3 "psql -U \"$PG_SUPERUSER\" -h \"$DB_HOST\" -p \"$DB_PORT\" -c \"CREATE DATABASE $DB_NAME OWNER $DB_USER;\""; then
        print_warning "Database '$DB_NAME' might already exist, continuing..."
    fi
    
    # Grant privileges
    if ! retry_command 2 3 "psql -U \"$PG_SUPERUSER\" -h \"$DB_HOST\" -p \"$DB_PORT\" -c \"GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;\""; then
        print_warning "Could not grant privileges, user might already have them..."
    fi
    
    # Test connection
    print_info "Testing database connection..."
    if test_database_connection "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_NAME" "$DB_PASSWORD"; then
        print_success "Database connection successful!"
    else
        print_error "Database connection failed. Please verify credentials."
        exit 1
    fi
    
    print_success "Database setup complete!"
    save_state "database_configured"
}

# Function to validate .env file
validate_env_file() {
    print_healing "Validating .env file..."
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found"
        return 1
    fi
    
    # Check for required variables
    local required_vars=("POSTGRES_PASSWORD" "POSTGRES_USER" "DB_HOST" "DB_PORT" "POSTGRES_DB" "BOT_TOKEN")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" .env; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required variables in .env: ${missing_vars[*]}"
        return 1
    fi
    
    print_success ".env file validated"
    return 0
}

# Function to configure .env file with validation
configure_env() {
    print_info "Configuring environment variables..."
    
    # Check if .env.example exists
    if [ ! -f ".env.example" ]; then
        print_error ".env.example file not found!"
        exit 1
    fi
    
    # Backup existing .env if it exists
    if [ -f ".env" ]; then
        print_info "Backing up existing .env file..."
        cp .env .env.backup.$(date +%Y%m%d%H%M%S)
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
    
    # Validate .env file
    if ! validate_env_file; then
        print_error ".env file validation failed"
        exit 1
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
    save_state "env_configured"
}

# Function to build the bot with error handling
build_bot() {
    print_info "Building the bot..."
    echo
    
    if ! retry_command 2 5 "yarn build"; then
        print_error "Build failed after multiple attempts"
        print_healing "Attempting to clean and rebuild..."
        
        # Clean build artifacts
        rm -rf dist build .next
        
        # Try building again
        if ! retry_command 2 10 "yarn build"; then
            print_error "Build failed. Please check the logs above for errors."
            exit 1
        fi
    fi
    
    echo
    print_success "Bot built successfully!"
    save_state "bot_built"
}

# Function to create health check script
create_health_check() {
    print_info "Creating health check script..."
    
    cat > health-check.sh << 'EOF'
#!/bin/bash

# SnailyCAD Bot Health Check Script

SERVICE_NAME="snailycad-bot"
LOG_FILE="$HOME/snailycad-health.log"
MAX_RESTARTS=3
RESTART_COUNT=0

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if service is running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "✓ Service is running"
    
    # Check if process is responding (additional checks can be added here)
    if pgrep -f "snailycad-bot" > /dev/null; then
        log "✓ Process is active"
        exit 0
    else
        log "✗ Process not found despite service running"
    fi
else
    log "✗ Service is not running"
fi

# Attempt to restart
log "Attempting to restart service..."
if systemctl restart "$SERVICE_NAME"; then
    log "✓ Service restarted successfully"
    RESTART_COUNT=$((RESTART_COUNT + 1))
    
    if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
        log "⚠ Maximum restart attempts reached. Manual intervention required."
        # Send notification (customize as needed)
        # echo "SnailyCAD bot requires manual intervention" | mail -s "Bot Alert" admin@example.com
    fi
else
    log "✗ Failed to restart service"
    exit 1
fi
EOF
    
    chmod +x health-check.sh
    
    # Create cron job for health check
    print_info "Setting up automated health checks..."
    
    read -p "Do you want to set up automated health checks every 5 minutes? (y/n): " -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Add to crontab
        (crontab -l 2>/dev/null; echo "*/5 * * * * $(pwd)/health-check.sh") | crontab -
        print_success "Health check cron job created"
    fi
}

# Function to create systemd service with restart policies
create_systemd_service() {
    print_info "Setting up systemd service with self-healing..."
    echo
    
    local bot_dir=$(pwd)
    local service_name="snailycad-bot"
    
    read -p "Do you want to create a systemd service to auto-start the bot? (y/n): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping systemd service creation."
        return
    fi
    
    # Create service file with enhanced restart policies
    cat > /tmp/${service_name}.service << EOF
[Unit]
Description=SnailyCAD Discord Bot
After=network.target postgresql.service
Wants=postgresql.service
StartLimitIntervalSec=200
StartLimitBurst=5

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

# Self-healing configurations
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
TimeoutStartSec=60

# Resource limits (adjust as needed)
MemoryLimit=1G
CPUQuota=80%

# Restart conditions
RestartPreventExitStatus=0

[Install]
WantedBy=multi-user.target
EOF
    
    # Install service
    print_info "Installing systemd service..."
    sudo cp /tmp/${service_name}.service /etc/systemd/system/${service_name}.service
    sudo chmod 644 /etc/systemd/system/${service_name}.service
    sudo systemctl daemon-reload
    
    print_success "Systemd service created with self-healing capabilities!"
    
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
        sleep 3
        
        # Verify service started
        if systemctl is-active --quiet ${service_name}; then
            print_success "Bot service started successfully!"
            sudo systemctl status ${service_name} --no-pager
        else
            print_error "Service failed to start. Checking logs..."
            sudo journalctl -u ${service_name} -n 50 --no-pager
        fi
    fi
    
    # Create health check script
    create_health_check
    
    # Create helpful aliases
    print_info "Creating helpful command aliases..."
    
    local alias_file=""
    if [ -f "$HOME/.bashrc" ]; then
        alias_file="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        alias_file="$HOME/.zshrc"
    fi
    
    if [ -n "$alias_file" ]; then
        # Check if aliases already exist
        if ! grep -q "# SnailyCAD Bot aliases" "$alias_file"; then
            echo "" >> "$alias_file"
            echo "# SnailyCAD Bot aliases" >> "$alias_file"
            echo "alias botstart='sudo systemctl start ${service_name}'" >> "$alias_file"
            echo "alias botstop='sudo systemctl stop ${service_name}'" >> "$alias_file"
            echo "alias botrestart='sudo systemctl restart ${service_name}'" >> "$alias_file"
            echo "alias botstatus='sudo systemctl status ${service_name}'" >> "$alias_file"
            echo "alias botlogs='sudo journalctl -u ${service_name} -f'" >> "$alias_file"
            echo "alias bothealth='$(pwd)/health-check.sh'" >> "$alias_file"
            
            print_success "Aliases created! Run 'source $alias_file' or restart your terminal."
        fi
        
        # Save aliases info to file
        cat >> service-commands.txt << EOF

SnailyCAD Bot Service Commands (Self-Healing Enabled)
====================================================

Service Management:
- Start bot:     botstart    (or: sudo systemctl start ${service_name})
- Stop bot:      botstop     (or: sudo systemctl stop ${service_name})
- Restart bot:   botrestart  (or: sudo systemctl restart ${service_name})
- Bot status:    botstatus   (or: sudo systemctl status ${service_name})
- View logs:     botlogs     (or: sudo journalctl -u ${service_name} -f)
- Health check:  bothealth   (or: $(pwd)/health-check.sh)

Self-Healing Features:
- Automatic restart on failure (with exponential backoff)
- Resource limits to prevent system overload
- Automated health checks every 5 minutes (if enabled)
- Service restart limit: 5 attempts in 200 seconds

To enable auto-start on boot:
  sudo systemctl enable ${service_name}

To disable auto-start:
  sudo systemctl disable ${service_name}

To reload after editing .env:
  botrestart

Setup Logs:
  Setup log: $LOG_FILE
  Health log: $HOME/snailycad-health.log

Note: Aliases will be available after running 'source $alias_file' or restarting your terminal.
EOF
        
        print_info "Service commands saved to service-commands.txt"
    fi
    
    save_state "service_created"
}

# Function to perform final verification
final_verification() {
    print_info "Performing final verification..."
    
    local issues=()
    
    # Check if all files exist
    if [ ! -f ".env" ]; then
        issues+=(".env file missing")
    fi
    
    if [ ! -f "credentials.txt" ]; then
        issues+=("credentials.txt missing")
    fi
    
    if [ ! -d "node_modules" ]; then
        issues+=("node_modules missing")
    fi
    
    if [ ! -d "dist" ] && [ ! -d "build" ]; then
        issues+=("Build output missing")
    fi
    
    # Check database connectivity
    if ! test_database_connection "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_NAME" "$DB_PASSWORD"; then
        issues+=("Database connection failed")
    fi
    
    if [ ${#issues[@]} -ne 0 ]; then
        print_warning "Verification found issues:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        print_info "You may need to review these issues before running the bot."
    else
        print_success "All verifications passed!"
    fi
}

# Function to display final instructions
display_final_instructions() {
    echo
    echo "========================================"
    print_success "Setup Complete with Self-Healing!"
    echo "========================================"
    echo
    print_info "Your SnailyCAD bot has been set up with automatic healing capabilities!"
    echo
    
    if [ -f "service-commands.txt" ]; then
        print_info "Bot is running as a systemd service with self-healing enabled!"
        echo
        print_info "Self-healing features:"
        echo "  ✓ Automatic restart on failure"
        echo "  ✓ Resource limits protection"
        echo "  ✓ Health monitoring (if enabled)"
        echo "  ✓ Restart throttling to prevent loops"
        echo
        print_info "Quick commands:"
        echo "  - Start:   botstart"
        echo "  - Stop:    botstop"
        echo "  - Status:  botstatus"
        echo "  - Logs:    botlogs"
        echo "  - Health:  bothealth"
        echo
        print_info "Full service commands saved to: $(pwd)/service-commands.txt"
    else
        print_info "To start the bot manually, run:"
        echo "  cd $(pwd)"
        echo "  yarn start"
        echo
        print_info "For background execution with self-healing:"
        echo "  - Re-run this script and choose systemd service option"
    fi
    
    echo
    print_info "Important files:"
    echo "  - Setup Log: $LOG_FILE"
    echo "  - Credentials: $(pwd)/credentials.txt"
    echo "  - Environment: $(pwd)/.env"
    if [ -f "service-commands.txt" ]; then
        echo "  - Service Commands: $(pwd)/service-commands.txt"
        echo "  - Health Check: $(pwd)/health-check.sh"
    fi
    echo
    print_warning "Security reminders:"
    echo "  - Keep your credentials.txt file secure"
    echo "  - Never commit .env to version control"
    echo "  - Regularly update your dependencies with 'yarn upgrade'"
    echo "  - Monitor logs for any unusual activity"
    echo
    print_info "For troubleshooting, check: $LOG_FILE"
    echo
}

# Function to resume from saved state
resume_from_state() {
    local state=$(get_state)
    
    if [ "$state" != "none" ]; then
        print_info "Previous setup state detected: $state"
        read -p "Do you want to resume from this state? (y/n): " -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Resuming from: $state"
            return 0
        else
            clear_state
            print_info "Starting fresh installation"
            return 1
        fi
    fi
    
    return 1
}

# Main execution
main() {
    echo "========================================"
    echo "  SnailyCAD Bot Setup Script"
    echo "  with Self-Healing Capabilities"
    echo "========================================"
    echo
    
    print_info "Setup log: $LOG_FILE"
    echo
    
    # Check if resuming from previous state
    local resume=false
    if resume_from_state; then
        resume=true
        state=$(get_state)
    fi
    
    # Check prerequisites
    if [ "$resume" = false ] || [ "$state" = "none" ]; then
        check_prerequisites
        navigate_to_safe_directory
        clone_repository
    fi
    
    # Install dependencies
    if [ "$resume" = false ] || [ "$state" = "none" ] || [ "$state" = "repository_cloned" ]; then
        install_dependencies
    fi
    
    # Configure database
    if [ "$resume" = false ] || [ "$state" = "none" ] || [ "$state" = "repository_cloned" ] || [ "$state" = "dependencies_installed" ]; then
        configure_database
    fi
    
    # Configure .env
    if [ "$resume" = false ] || [ "$state" = "none" ] || [ "$state" = "repository_cloned" ] || [ "$state" = "dependencies_installed" ] || [ "$state" = "database_configured" ]; then
        configure_env
    fi
    
    # Build bot
    if [ "$resume" = false ] || [ "$state" = "none" ] || [ "$state" = "repository_cloned" ] || [ "$state" = "dependencies_installed" ] || [ "$state" = "database_configured" ] || [ "$state" = "env_configured" ]; then
        build_bot
    fi
    
    # Create systemd service (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ "$resume" = false ] || [ "$state" != "service_created" ]; then
            create_systemd_service
        fi
    else
        print_warning "Systemd service creation is only available on Linux."
        print_info "For other platforms, use PM2 or run manually with 'yarn start'."
    fi
    
    # Final verification
    final_verification
    
    # Clear state after successful completion
    clear_state
    
    # Display final instructions
    display_final_instructions
}

# Trap errors and provide helpful messages
trap 'print_error "An error occurred on line $LINENO. Check $LOG_FILE for details."; exit 1' ERR

# Run main function
main
