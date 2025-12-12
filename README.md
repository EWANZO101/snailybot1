# SnailyCAD Bot Automated Setup Script

This script automates the complete installation and configuration of the SnailyCAD Discord bot.

## What This Script Does

1. ✅ Checks all prerequisites (Git, Node.js, Yarn, PostgreSQL)
2. ✅ Navigates to the correct installation directory
3. ✅ Clones the SnailyCAD bot repository
4. ✅ Installs all required dependencies
5. ✅ Creates PostgreSQL database and user
6. ✅ Configures all environment variables
7. ✅ Builds the bot
8. ✅ Saves credentials for future reference

## Prerequisites

Before running this script, ensure you have installed:

- **Git** - Version control system
- **Node.js** (v18.x or higher)
- **Yarn** - Package manager (`npm install --global yarn`)
- **PostgreSQL** (v14 or higher)

### Installation Guides

**Windows:**
- Node.js: Download from [nodejs.org](https://nodejs.org/)
- PostgreSQL: Download from [postgresql.org](https://www.postgresql.org/download/windows/)
- Git: Download from [git-scm.com](https://git-scm.com/download/win)

**Linux (Ubuntu/Debian):**
```bash
# Update package list
sudo apt update

# Install Git
sudo apt install git

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Yarn
npm install --global yarn

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib
```

**macOS:**
```bash
# Using Homebrew
brew install git node yarn postgresql
```

## Usage

### Step 1: Download the Script

Download `snailycad-bot-setup.sh` to your computer.

### Step 2: Make it Executable

**Linux/macOS:**
```bash
chmod +x snailycad-bot-setup.sh
```

**Windows (Git Bash):**
```bash
chmod +x snailycad-bot-setup.sh
```

### Step 3: Run the Script

**Linux/macOS:**
```bash
./snailycad-bot-setup.sh
```

**Windows (Git Bash):**
```bash
bash snailycad-bot-setup.sh
```

## What You'll Need

### Discord Bot Token

Before running the script, create a Discord bot application:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click "New Application"
3. Give it a name and click "Create"
4. Go to the "Bot" section
5. Click "Add Bot"
6. Under "Token", click "Copy" to copy your bot token
7. **Save this token** - you'll need it during setup

### PostgreSQL Superuser Password

You'll need the password for your PostgreSQL superuser (usually `postgres`). 

**Don't know your PostgreSQL password?**

**Linux:**
```bash
# Reset PostgreSQL password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_new_password';"
```

**Windows:**
- The password was set during PostgreSQL installation
- Check your installation notes or reset it via pgAdmin

## Script Workflow

### 1. Prerequisites Check
The script verifies all required tools are installed.

### 2. Directory Navigation
- **Windows**: Navigates to `Documents` folder
- **Linux/macOS**: Navigates to home folder

### 3. Repository Clone
Clones the official SnailyCAD bot repository from GitHub.

### 4. Dependencies Installation
Installs all required Node.js packages via Yarn.

### 5. Database Setup
You'll be prompted for:
- Database name (auto-generated if blank)
- Database user (auto-generated if blank)
- Database password (auto-generated if blank)
- Database host (default: `localhost`)
- Database port (default: `5432`)
- PostgreSQL superuser credentials

The script then:
- Creates the database
- Creates the database user
- Sets up proper permissions

### 6. Environment Configuration
You'll be prompted for:
- Discord Bot Token (required)

The script then:
- Copies `.env.example` to `.env`
- Fills in all database credentials
- Adds your bot token
- Saves credentials to `credentials.txt`

### 7. Build Process
Runs `yarn build` to compile the bot.

### 8. Completion
Displays next steps and important reminders.

## After Setup

### Starting the Bot

Navigate to the bot directory and start it:

```bash
cd ~/snailycad-bot  # or ~/Documents/snailycad-bot on Windows
yarn start
```

### Running in Background

**Using PM2 (Recommended):**
```bash
# Install PM2 globally
npm install -g pm2

# Start the bot
pm2 start "yarn start" --name snailycad-bot

# View logs
pm2 logs snailycad-bot

# Restart bot
pm2 restart snailycad-bot

# Stop bot
pm2 stop snailycad-bot
```

**Using screen (Linux):**
```bash
# Start a new screen session
screen -S snailycad-bot

# Run the bot
yarn start

# Detach from screen: Press Ctrl+A, then D
# Reattach to screen: screen -r snailycad-bot
```

### Your Credentials

All credentials are saved in `credentials.txt` in the bot directory:
- Database name
- Database user
- Database password
- Bot token

**⚠️ SECURITY WARNING:**
- Keep `credentials.txt` secure
- Never commit `.env` or `credentials.txt` to version control
- Never share these files publicly

## Troubleshooting

### "Command not found" errors

**Missing Node.js/npm/yarn:**
```bash
# Verify installation
node -v
npm -v
yarn -v
```

**Missing PostgreSQL:**
```bash
# Verify installation
psql --version
```

### Database Connection Issues

1. **Check PostgreSQL is running:**
   ```bash
   # Linux
   sudo systemctl status postgresql
   
   # Start if not running
   sudo systemctl start postgresql
   ```

2. **Verify connection:**
   ```bash
   psql -U postgres -h localhost
   ```

3. **Check credentials** in `.env` file

### Permission Issues

**Linux:**
```bash
# If you get permission errors
sudo chown -R $USER:$USER ~/snailycad-bot
```

### Build Failures

```bash
# Clear cache and reinstall
cd snailycad-bot
rm -rf node_modules
yarn cache clean
yarn install
yarn build
```

## Manual Setup

If the automated script fails, you can follow these manual steps:

### 1. Clone Repository
```bash
cd ~ # or ~/Documents on Windows
git clone https://github.com/SnailyCAD/snailycad-bot.git
cd snailycad-bot
```

### 2. Install Dependencies
```bash
yarn install
```

### 3. Create Database
```bash
psql -U postgres
CREATE DATABASE snailycad_db;
CREATE USER snailycad_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE snailycad_db TO snailycad_user;
\q
```

### 4. Configure .env
```bash
cp .env.example .env
nano .env  # or use any text editor
```

Add your values:
```
POSTGRES_PASSWORD="your_password"
POSTGRES_USER="snailycad_user"
DB_HOST="localhost"
DB_PORT="5432"
POSTGRES_DB="snailycad_db"
BOT_TOKEN="your_discord_bot_token"
```

### 5. Build
```bash
yarn build
```

### 6. Start
```bash
yarn start
```

## Getting Help

- **SnailyCAD Documentation**: [docs.snailycad.org](https://docs.snailycad.org)
- **Discord Support**: Join the SnailyCAD Discord server
- **GitHub Issues**: [github.com/SnailyCAD/snailycad-bot/issues](https://github.com/SnailyCAD/snailycad-bot/issues)

## Script Features

### Auto-Generated Credentials
If you don't provide values, the script generates:
- Random database name: `snailycad_XXXXXXXX`
- Default username: `snailycad_user`
- Random secure password (16 characters)

### Safety Features
- Checks if directory already exists
- Validates prerequisites before starting
- Creates backup of existing configurations
- Saves all credentials for reference
- Sets secure file permissions (600) on credentials

### Cross-Platform Support
- Works on Linux, macOS, and Windows (Git Bash)
- Automatically detects OS and adjusts paths
- Uses compatible commands across platforms

## License

This script is provided as-is for setting up the SnailyCAD bot. The SnailyCAD bot itself is subject to its own license.

## Credits

- **SnailyCAD Bot**: [github.com/SnailyCAD/snailycad-bot](https://github.com/SnailyCAD/snailycad-bot)
- **Setup Script**: Automated installation helper

---

**Last Updated**: December 2024  
**Script Version**: 1.0.0
