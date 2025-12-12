#!/bin/bash

# Quick Fix Script for SnailyCAD Bot Issues
# Fixes: Invalid port in DATABASE_URL and missing aliases

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "=========================================="
echo "  SnailyCAD Bot Quick Fix"
echo "=========================================="
echo

# Find the snailycad-bot directory
if [ -d "$HOME/snailycad-bot" ]; then
    BOT_DIR="$HOME/snailycad-bot"
elif [ -d "/root/snailycad-bot" ]; then
    BOT_DIR="/root/snailycad-bot"
else
    print_error "Cannot find snailycad-bot directory"
    exit 1
fi

cd "$BOT_DIR" || exit 1
print_info "Working directory: $BOT_DIR"
echo

# Fix 1: Repair DATABASE_URL in .env
print_info "Fixing DATABASE_URL in .env file..."

if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    exit 1
fi

# Backup current .env
cp .env .env.backup.emergency

# Extract current values
POSTGRES_USER=$(grep "^POSTGRES_USER=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
DB_HOST=$(grep "^DB_HOST=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
DB_PORT=$(grep "^DB_PORT=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
POSTGRES_DB=$(grep "^POSTGRES_DB=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")

print_info "Current configuration:"
echo "  User: $POSTGRES_USER"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $POSTGRES_DB"
echo

# Validate port number
if ! [[ "$DB_PORT" =~ ^[0-9]+$ ]]; then
    print_warning "DB_PORT is not a valid number: '$DB_PORT'"
    print_info "Setting to default: 5432"
    DB_PORT="5432"
    
    # Fix DB_PORT in .env
    if grep -q "^DB_PORT=" .env; then
        sed -i "s/^DB_PORT=.*/DB_PORT=\"5432\"/" .env
    else
        echo 'DB_PORT="5432"' >> .env
    fi
fi

# Construct proper DATABASE_URL
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}:${DB_PORT}/${POSTGRES_DB}"

print_info "New DATABASE_URL format:"
echo "  postgresql://${POSTGRES_USER}:***@${DB_HOST}:${DB_PORT}/${POSTGRES_DB}"
echo

# Update DATABASE_URL in .env
if grep -q "^DATABASE_URL=" .env; then
    # Use pipe delimiter to avoid issues with special characters
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"${DATABASE_URL}\"|" .env
    print_success "Updated existing DATABASE_URL"
elif grep -q "^#DATABASE_URL=" .env; then
    sed -i "s|^#DATABASE_URL=.*|DATABASE_URL=\"${DATABASE_URL}\"|" .env
    print_success "Uncommented and updated DATABASE_URL"
else
    echo "" >> .env
    echo "DATABASE_URL=\"${DATABASE_URL}\"" >> .env
    print_success "Added DATABASE_URL to .env"
fi

# Verify the fix
print_info "Verifying .env file..."
if grep -q "^DATABASE_URL=" .env; then
    CURRENT_URL=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2- | tr -d '"')
    if [[ $CURRENT_URL == postgresql://* ]]; then
        print_success "DATABASE_URL format is now correct"
    else
        print_error "DATABASE_URL still has issues"
        cat .env | grep "DATABASE_URL"
    fi
else
    print_error "DATABASE_URL is missing from .env"
fi

echo

# Fix 2: Test database connection
print_info "Testing database connection..."
if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "Database connection successful!"
else
    print_warning "Database connection failed. Checking database setup..."
    
    # Check if database exists
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
        print_info "Database '$POSTGRES_DB' exists"
    else
        print_warning "Database '$POSTGRES_DB' does not exist. Creating..."
        sudo -u postgres psql -c "CREATE DATABASE \"$POSTGRES_DB\";" 2>/dev/null || print_error "Could not create database"
    fi
    
    # Check if user exists
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'" | grep -q 1; then
        print_info "User '$POSTGRES_USER' exists"
        
        # Reset password just in case
        print_info "Resetting user password..."
        sudo -u postgres psql -c "ALTER USER \"$POSTGRES_USER\" PASSWORD '$POSTGRES_PASSWORD';" 2>/dev/null
    else
        print_warning "User '$POSTGRES_USER' does not exist. Creating..."
        sudo -u postgres psql -c "CREATE USER \"$POSTGRES_USER\" WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';" 2>/dev/null || print_error "Could not create user"
    fi
    
    # Test again
    sleep 2
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
        print_success "Database connection now working!"
    else
        print_error "Database connection still failing. Check credentials in: $BOT_DIR/credentials.txt"
    fi
fi

echo

# Fix 3: Reload shell aliases
print_info "Fixing shell aliases..."

# Find the right shell config file
SHELL_CONFIG=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    print_info "Shell config: $SHELL_CONFIG"
    
    # Check if aliases are present
    if grep -q "# SnailyCAD Bot aliases" "$SHELL_CONFIG"; then
        print_success "Aliases are in $SHELL_CONFIG"
        
        # Source the file
        print_info "Loading aliases..."
        if source "$SHELL_CONFIG" 2>/dev/null; then
            print_success "Aliases loaded!"
        else
            print_warning "Could not source config file automatically"
        fi
    else
        print_warning "Aliases not found in $SHELL_CONFIG. Adding them..."
        
        cat >> "$SHELL_CONFIG" << 'EOF'

# SnailyCAD Bot aliases
alias botstart='sudo systemctl start snailycad-bot'
alias botstop='sudo systemctl stop snailycad-bot'
alias botrestart='sudo systemctl restart snailycad-bot'
alias botstatus='sudo systemctl status snailycad-bot'
alias botlogs='sudo journalctl -u snailycad-bot -f'
alias bothealth='cd ~/snailycad-bot && ./health-check.sh'
EOF
        
        print_success "Aliases added to $SHELL_CONFIG"
        source "$SHELL_CONFIG" 2>/dev/null
    fi
else
    print_warning "Could not find shell config file"
fi

echo

# Fix 4: Update systemd service file (fix deprecated MemoryLimit)
print_info "Fixing systemd service configuration..."

SERVICE_FILE="/etc/systemd/system/snailycad-bot.service"

if [ -f "$SERVICE_FILE" ]; then
    if grep -q "MemoryLimit=" "$SERVICE_FILE"; then
        print_info "Updating deprecated MemoryLimit to MemoryMax..."
        sudo sed -i 's/MemoryLimit=/MemoryMax=/' "$SERVICE_FILE"
        sudo systemctl daemon-reload
        print_success "Service file updated"
    else
        print_success "Service file is already correct"
    fi
else
    print_warning "Service file not found at $SERVICE_FILE"
fi

echo

# Fix 5: Restart the service
print_info "Restarting bot service..."
if sudo systemctl restart snailycad-bot; then
    sleep 3
    
    if systemctl is-active --quiet snailycad-bot; then
        print_success "Bot service is now running!"
        echo
        sudo systemctl status snailycad-bot --no-pager -l
    else
        print_error "Service failed to start. Checking logs..."
        echo
        sudo journalctl -u snailycad-bot -n 20 --no-pager
    fi
else
    print_error "Failed to restart service"
fi

echo
echo "=========================================="
print_success "Fix Complete!"
echo "=========================================="
echo

print_info "To use bot commands in THIS terminal session, run:"
echo "  source $SHELL_CONFIG"
echo

print_info "Or open a new terminal and the aliases will work automatically"
echo

print_info "Available commands:"
echo "  botstart   - Start the bot"
echo "  botstop    - Stop the bot"
echo "  botrestart - Restart the bot"
echo "  botstatus  - Check bot status"
echo "  botlogs    - View live logs"
echo

print_info "Files updated:"
echo "  - $BOT_DIR/.env (backed up to .env.backup.emergency)"
echo "  - $SERVICE_FILE"
echo "  - $SHELL_CONFIG"
echo

print_info "Next steps:"
echo "  1. Run: source $SHELL_CONFIG"
echo "  2. Check status: botstatus"
echo "  3. View logs: botlogs"
echo
