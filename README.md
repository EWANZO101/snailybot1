# SnailyCAD Bot - Quick Installation Guide

## 🚀 One-Command Installation

### Option 1: Direct Download & Run (Recommended)

**Linux/macOS:**
```bash
wget https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh && chmod +x snailycad-bot-setup.sh && ./snailycad-bot-setup.sh
```

**Alternative with curl:**
```bash
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh && chmod +x snailycad-bot-setup.sh && ./snailycad-bot-setup.sh
```

**Windows (Git Bash):**
```bash
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh && bash snailycad-bot-setup.sh
```

### Option 2: Clone Repository Method

```bash
# Clone the setup repository
git clone https://github.com/EWANZO101/snailybot1.git
cd snailybot1

# Make script executable
chmod +x snailycad-bot-setup.sh

# Run the setup
./snailycad-bot-setup.sh
```

---

## 📋 What You'll Need Before Running

### 1. Discord Bot Token
Get your bot token from Discord Developer Portal:
1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Go to "Bot" section → "Add Bot"
4. Copy the token (keep it safe!)

### 2. PostgreSQL Password
- You'll need your PostgreSQL superuser password
- Usually the user is `postgres`
- Set during PostgreSQL installation

### 3. Required Software
The script will check for these (install if missing):
- **Git**
- **Node.js** (v18+)
- **Yarn** (`npm install -g yarn`)
- **PostgreSQL** (v14+)

---

## 🎯 What The Script Does

The automated setup script handles everything:

✅ Checks prerequisites  
✅ Clones SnailyCAD bot repository  
✅ Installs all dependencies  
✅ Creates PostgreSQL database & user  
✅ Generates secure passwords (optional)  
✅ Configures `.env` file  
✅ Builds the bot  
✅ **Creates systemd service (Linux)**  
✅ Sets up helpful command aliases  
✅ Saves all credentials securely  

---

## ⚡ Quick Start Commands

### After Installation

**If systemd service was created (Linux):**
```bash
botstart      # Start the bot
botstop       # Stop the bot
botstatus     # Check bot status
botrestart    # Restart the bot
botlogs       # View live logs
```

**Manual start (all platforms):**
```bash
cd ~/snailycad-bot  # or ~/Documents/snailycad-bot on Windows
yarn start
```

---

## 🐧 Linux Full Installation (Step by Step)

### Ubuntu/Debian

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y git curl wget

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Yarn
npm install --global yarn

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set PostgreSQL password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_secure_password';"

# Download and run setup script
wget https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
chmod +x snailycad-bot-setup.sh
./snailycad-bot-setup.sh
```

### CentOS/RHEL/Fedora

```bash
# Update system
sudo dnf update -y  # or: sudo yum update -y

# Install prerequisites
sudo dnf install -y git curl wget

# Install Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# Install Yarn
npm install --global yarn

# Install PostgreSQL
sudo dnf install -y postgresql-server postgresql-contrib
sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set PostgreSQL password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_secure_password';"

# Download and run setup script
wget https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
chmod +x snailycad-bot-setup.sh
./snailycad-bot-setup.sh
```

---

## 🪟 Windows Installation

### Prerequisites

1. **Install Git for Windows**: https://git-scm.com/download/win
2. **Install Node.js**: https://nodejs.org/ (download LTS version)
3. **Install PostgreSQL**: https://www.postgresql.org/download/windows/
4. **Install Yarn**: Open PowerShell as admin and run:
   ```powershell
   npm install --global yarn
   ```

### Run Setup

Open **Git Bash** (installed with Git for Windows) and run:

```bash
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
bash snailycad-bot-setup.sh
```

**Note:** Systemd service is Linux-only. For Windows, use:
- **Manual**: `yarn start` in the bot directory
- **PM2**: `npm install -g pm2 && pm2 start "yarn start" --name snailycad-bot`

---

## 🍎 macOS Installation

### Using Homebrew

```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install prerequisites
brew install git node yarn postgresql

# Start PostgreSQL
brew services start postgresql

# Set PostgreSQL password (wait a few seconds after starting)
psql postgres -c "ALTER USER $(whoami) PASSWORD 'your_secure_password';"

# Download and run setup script
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
chmod +x snailycad-bot-setup.sh
./snailycad-bot-setup.sh
```

---

## 🔧 Configuration During Setup

The script will prompt you for:

| Setting | Default | Description |
|---------|---------|-------------|
| Database Name | `snailycad_XXXXXXXX` | Auto-generated if blank |
| Database User | `snailycad_user` | Can customize |
| Database Password | Random 16-char | Auto-generated if blank |
| Database Host | `localhost` | Usually localhost |
| Database Port | `5432` | PostgreSQL default |
| Bot Token | **REQUIRED** | From Discord Developer Portal |

**Tip:** Just press Enter to accept defaults!

---

## 📝 Service Management (Linux)

### Systemd Commands

```bash
# Start bot
sudo systemctl start snailycad-bot
# or use alias: botstart

# Stop bot
sudo systemctl stop snailycad-bot
# or use alias: botstop

# Restart bot
sudo systemctl restart snailycad-bot
# or use alias: botrestart

# Check status
sudo systemctl status snailycad-bot
# or use alias: botstatus

# View live logs
sudo journalctl -u snailycad-bot -f
# or use alias: botlogs

# Enable auto-start on boot
sudo systemctl enable snailycad-bot

# Disable auto-start
sudo systemctl disable snailycad-bot
```

### Viewing Logs

```bash
# Live logs (follow mode)
botlogs

# Last 100 lines
sudo journalctl -u snailycad-bot -n 100

# Logs from today
sudo journalctl -u snailycad-bot --since today

# Logs from last hour
sudo journalctl -u snailycad-bot --since "1 hour ago"
```

---

## 🔒 Security Best Practices

### After Installation

1. **Secure Credentials File**
   ```bash
   chmod 600 ~/snailycad-bot/credentials.txt
   ```

2. **Never Commit Secrets**
   - `.env` file is in `.gitignore`
   - Never share `credentials.txt`
   - Never commit bot tokens to GitHub

3. **Regular Updates**
   ```bash
   cd ~/snailycad-bot
   git pull
   yarn upgrade
   yarn build
   botrestart  # if using systemd
   ```

4. **Backup Your Configuration**
   ```bash
   cp ~/.env ~/.env.backup
   cp ~/snailycad-bot/credentials.txt ~/snailycad-bot/credentials.backup
   ```

---

## 🐛 Troubleshooting

### "Permission Denied" Error

```bash
# Fix file permissions
chmod +x snailycad-bot-setup.sh

# If in bot directory
sudo chown -R $USER:$USER ~/snailycad-bot
```

### PostgreSQL Connection Failed

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start PostgreSQL if stopped
sudo systemctl start postgresql

# Test connection
psql -U postgres -h localhost
```

### "Command Not Found"

```bash
# Verify installations
node -v
yarn -v
git --version
psql --version

# If missing, reinstall the missing tool
```

### Bot Won't Start

```bash
# Check logs
botlogs  # or: sudo journalctl -u snailycad-bot -n 50

# Verify .env file
cat ~/snailycad-bot/.env

# Rebuild bot
cd ~/snailycad-bot
yarn build
botrestart
```

### Port Already in Use

```bash
# Find process using port
sudo lsof -i :PORT_NUMBER

# Kill process
sudo kill -9 PID
```

---

## 🔄 Updating the Bot

### Automatic Update Script

Create an update script:

```bash
cat > ~/snailycad-bot/update.sh << 'EOF'
#!/bin/bash
cd ~/snailycad-bot
echo "Stopping bot..."
botstop 2>/dev/null || yarn stop
echo "Pulling latest changes..."
git pull
echo "Installing dependencies..."
yarn install
echo "Building bot..."
yarn build
echo "Starting bot..."
botstart 2>/dev/null || yarn start
EOF

chmod +x ~/snailycad-bot/update.sh
```

Run updates:
```bash
~/snailycad-bot/update.sh
```

---

## 📚 Additional Resources

- **SnailyCAD Documentation**: https://docs.snailycad.org
- **SnailyCAD Bot GitHub**: https://github.com/SnailyCAD/snailycad-bot
- **Discord API Documentation**: https://discord.com/developers/docs
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/

---

## 🆘 Getting Help

### Check Logs First
```bash
botlogs  # View live logs
```

### Common Issues
- **Bot token invalid**: Regenerate token from Discord Developer Portal
- **Database connection**: Check PostgreSQL is running
- **Permission errors**: Run commands with appropriate permissions

### Community Support
- **SnailyCAD Discord**: Join for community support
- **GitHub Issues**: Report bugs at https://github.com/SnailyCAD/snailycad-bot/issues

---

## 📄 Files Created by Setup

| File | Location | Purpose |
|------|----------|---------|
| `credentials.txt` | `~/snailycad-bot/` | All credentials and passwords |
| `.env` | `~/snailycad-bot/` | Environment variables |
| `service-commands.txt` | `~/snailycad-bot/` | Service management commands |
| `snailycad-bot.service` | `/etc/systemd/system/` | Systemd service file (Linux) |

---

## ✨ Features

### Auto-Generated Credentials
- Secure random passwords (16 characters)
- Unique database names
- All saved to `credentials.txt`

### Systemd Integration (Linux)
- Auto-start on boot
- Automatic restart on crash
- Centralized logging with journald
- Easy management with aliases

### Cross-Platform Support
- Linux (systemd service)
- macOS (manual/PM2)
- Windows (manual/PM2)

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**GitHub**: https://github.com/EWANZO101/snailybot1# SnailyCAD Bot - Quick Installation Guide

## 🚀 One-Command Installation

### Option 1: Direct Download & Run (Recommended)

**Linux/macOS:**
```bash
wget https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh && chmod +x snailycad-bot-setup.sh && ./snailycad-bot-setup.sh
```

**Alternative with curl:**
```bash
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh && chmod +x snailycad-bot-setup.sh && ./snailycad-bot-setup.sh
```

**Windows (Git Bash):**
```bash
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh && bash snailycad-bot-setup.sh
```

### Option 2: Clone Repository Method

```bash
# Clone the setup repository
git clone https://github.com/EWANZO101/snailybot1.git
cd snailybot1

# Make script executable
chmod +x snailycad-bot-setup.sh

# Run the setup
./snailycad-bot-setup.sh
```

---

## 📋 What You'll Need Before Running

### 1. Discord Bot Token
Get your bot token from Discord Developer Portal:
1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Go to "Bot" section → "Add Bot"
4. Copy the token (keep it safe!)

### 2. PostgreSQL Password
- You'll need your PostgreSQL superuser password
- Usually the user is `postgres`
- Set during PostgreSQL installation

### 3. Required Software
The script will check for these (install if missing):
- **Git**
- **Node.js** (v18+)
- **Yarn** (`npm install -g yarn`)
- **PostgreSQL** (v14+)

---

## 🎯 What The Script Does

The automated setup script handles everything:

✅ Checks prerequisites  
✅ Clones SnailyCAD bot repository  
✅ Installs all dependencies  
✅ Creates PostgreSQL database & user  
✅ Generates secure passwords (optional)  
✅ Configures `.env` file  
✅ Builds the bot  
✅ **Creates systemd service (Linux)**  
✅ Sets up helpful command aliases  
✅ Saves all credentials securely  

---

## ⚡ Quick Start Commands

### After Installation

**If systemd service was created (Linux):**
```bash
botstart      # Start the bot
botstop       # Stop the bot
botstatus     # Check bot status
botrestart    # Restart the bot
botlogs       # View live logs
```

**Manual start (all platforms):**
```bash
cd ~/snailycad-bot  # or ~/Documents/snailycad-bot on Windows
yarn start
```

---

## 🐧 Linux Full Installation (Step by Step)

### Ubuntu/Debian

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y git curl wget

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Yarn
npm install --global yarn

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set PostgreSQL password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_secure_password';"

# Download and run setup script
wget https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
chmod +x snailycad-bot-setup.sh
./snailycad-bot-setup.sh
```

### CentOS/RHEL/Fedora

```bash
# Update system
sudo dnf update -y  # or: sudo yum update -y

# Install prerequisites
sudo dnf install -y git curl wget

# Install Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# Install Yarn
npm install --global yarn

# Install PostgreSQL
sudo dnf install -y postgresql-server postgresql-contrib
sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set PostgreSQL password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_secure_password';"

# Download and run setup script
wget https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
chmod +x snailycad-bot-setup.sh
./snailycad-bot-setup.sh
```

---

## 🪟 Windows Installation

### Prerequisites

1. **Install Git for Windows**: https://git-scm.com/download/win
2. **Install Node.js**: https://nodejs.org/ (download LTS version)
3. **Install PostgreSQL**: https://www.postgresql.org/download/windows/
4. **Install Yarn**: Open PowerShell as admin and run:
   ```powershell
   npm install --global yarn
   ```

### Run Setup

Open **Git Bash** (installed with Git for Windows) and run:

```bash
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
bash snailycad-bot-setup.sh
```

**Note:** Systemd service is Linux-only. For Windows, use:
- **Manual**: `yarn start` in the bot directory
- **PM2**: `npm install -g pm2 && pm2 start "yarn start" --name snailycad-bot`

---

## 🍎 macOS Installation

### Using Homebrew

```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install prerequisites
brew install git node yarn postgresql

# Start PostgreSQL
brew services start postgresql

# Set PostgreSQL password (wait a few seconds after starting)
psql postgres -c "ALTER USER $(whoami) PASSWORD 'your_secure_password';"

# Download and run setup script
curl -O https://raw.githubusercontent.com/EWANZO101/snailybot1/main/snailycad-bot-setup.sh
chmod +x snailycad-bot-setup.sh
./snailycad-bot-setup.sh
```

---

## 🔧 Configuration During Setup

The script will prompt you for:

| Setting | Default | Description |
|---------|---------|-------------|
| Database Name | `snailycad_XXXXXXXX` | Auto-generated if blank |
| Database User | `snailycad_user` | Can customize |
| Database Password | Random 16-char | Auto-generated if blank |
| Database Host | `localhost` | Usually localhost |
| Database Port | `5432` | PostgreSQL default |
| Bot Token | **REQUIRED** | From Discord Developer Portal |

**Tip:** Just press Enter to accept defaults!

---

## 📝 Service Management (Linux)

### Systemd Commands

```bash
# Start bot
sudo systemctl start snailycad-bot
# or use alias: botstart

# Stop bot
sudo systemctl stop snailycad-bot
# or use alias: botstop

# Restart bot
sudo systemctl restart snailycad-bot
# or use alias: botrestart

# Check status
sudo systemctl status snailycad-bot
# or use alias: botstatus

# View live logs
sudo journalctl -u snailycad-bot -f
# or use alias: botlogs

# Enable auto-start on boot
sudo systemctl enable snailycad-bot

# Disable auto-start
sudo systemctl disable snailycad-bot
```

### Viewing Logs

```bash
# Live logs (follow mode)
botlogs

# Last 100 lines
sudo journalctl -u snailycad-bot -n 100

# Logs from today
sudo journalctl -u snailycad-bot --since today

# Logs from last hour
sudo journalctl -u snailycad-bot --since "1 hour ago"
```

---

## 🔒 Security Best Practices

### After Installation

1. **Secure Credentials File**
   ```bash
   chmod 600 ~/snailycad-bot/credentials.txt
   ```

2. **Never Commit Secrets**
   - `.env` file is in `.gitignore`
   - Never share `credentials.txt`
   - Never commit bot tokens to GitHub

3. **Regular Updates**
   ```bash
   cd ~/snailycad-bot
   git pull
   yarn upgrade
   yarn build
   botrestart  # if using systemd
   ```

4. **Backup Your Configuration**
   ```bash
   cp ~/.env ~/.env.backup
   cp ~/snailycad-bot/credentials.txt ~/snailycad-bot/credentials.backup
   ```

---

## 🐛 Troubleshooting

### "Permission Denied" Error

```bash
# Fix file permissions
chmod +x snailycad-bot-setup.sh

# If in bot directory
sudo chown -R $USER:$USER ~/snailycad-bot
```

### PostgreSQL Connection Failed

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start PostgreSQL if stopped
sudo systemctl start postgresql

# Test connection
psql -U postgres -h localhost
```

### "Command Not Found"

```bash
# Verify installations
node -v
yarn -v
git --version
psql --version

# If missing, reinstall the missing tool
```

### Bot Won't Start

```bash
# Check logs
botlogs  # or: sudo journalctl -u snailycad-bot -n 50

# Verify .env file
cat ~/snailycad-bot/.env

# Rebuild bot
cd ~/snailycad-bot
yarn build
botrestart
```

### Port Already in Use

```bash
# Find process using port
sudo lsof -i :PORT_NUMBER

# Kill process
sudo kill -9 PID
```

---

## 🔄 Updating the Bot

### Automatic Update Script

Create an update script:

```bash
cat > ~/snailycad-bot/update.sh << 'EOF'
#!/bin/bash
cd ~/snailycad-bot
echo "Stopping bot..."
botstop 2>/dev/null || yarn stop
echo "Pulling latest changes..."
git pull
echo "Installing dependencies..."
yarn install
echo "Building bot..."
yarn build
echo "Starting bot..."
botstart 2>/dev/null || yarn start
EOF

chmod +x ~/snailycad-bot/update.sh
```

Run updates:
```bash
~/snailycad-bot/update.sh
```

---

## 📚 Additional Resources

- **SnailyCAD Documentation**: https://docs.snailycad.org
- **SnailyCAD Bot GitHub**: https://github.com/SnailyCAD/snailycad-bot
- **Discord API Documentation**: https://discord.com/developers/docs
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/

---

## 🆘 Getting Help

### Check Logs First
```bash
botlogs  # View live logs
```

### Common Issues
- **Bot token invalid**: Regenerate token from Discord Developer Portal
- **Database connection**: Check PostgreSQL is running
- **Permission errors**: Run commands with appropriate permissions

### Community Support
- **SnailyCAD Discord**: Join for community support
- **GitHub Issues**: Report bugs at https://github.com/SnailyCAD/snailycad-bot/issues

---

## 📄 Files Created by Setup

| File | Location | Purpose |
|------|----------|---------|
| `credentials.txt` | `~/snailycad-bot/` | All credentials and passwords |
| `.env` | `~/snailycad-bot/` | Environment variables |
| `service-commands.txt` | `~/snailycad-bot/` | Service management commands |
| `snailycad-bot.service` | `/etc/systemd/system/` | Systemd service file (Linux) |

---

## ✨ Features

### Auto-Generated Credentials
- Secure random passwords (16 characters)
- Unique database names
- All saved to `credentials.txt`

### Systemd Integration (Linux)
- Auto-start on boot
- Automatic restart on crash
- Centralized logging with journald
- Easy management with aliases

### Cross-Platform Support
- Linux (systemd service)
- macOS (manual/PM2)
- Windows (manual/PM2)

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**GitHub**: https://github.com/EWANZO101/snailybot1
