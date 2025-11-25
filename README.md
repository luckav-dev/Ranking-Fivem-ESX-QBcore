<div align="center">

# 🏆 FiveM Kill Ranking System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue.svg)](https://fivem.net/)
[![ESX](https://img.shields.io/badge/Framework-ESX-green.svg)](https://github.com/esx-framework/esx-legacy)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-purple.svg)](https://github.com/qbcore-framework/qb-core)

**Advanced kill tracking and ranking system for FiveM servers with Discord integration and multi-framework support**

[Features](#-features) • [Installation](#-installation) • [Configuration](#%EF%B8%8F-configuration) • [Commands](#-commands) • [Support](#-support)

</div>

---

## 📋 Features

✅ **Multi-Framework Support** - Works with ESX Legacy, QBCore, and Standalone  
✅ **Discord Integration** - Fetches player avatars directly from Discord  
✅ **Real-Time Statistics** - Live tracking of kills, deaths, and assists  
✅ **Kill Streak System** - Tracks current and longest kill streaks  
✅ **Headshot Detection** - Special tracking for headshot kills  
✅ **Distance Calculation** - Records kill distance for each elimination  
✅ **Reward System** - Configurable money rewards and death penalties  
✅ **Responsive UI** - Adapts to all screen resolutions and aspect ratios  
✅ **Search Functionality** - Quick player search in the leaderboard  
✅ **MySQL Database** - Persistent data storage with HeidiSQL compatibility  

---

## 📦 Requirements

- **FiveM Server** (Latest Artifact Recommended)
- **oxmysql** (MySQL Resource)
- **ESX Legacy** or **QBCore** (Optional - Works Standalone)
- **Discord Bot Token** (For Avatar Integration)
- **MySQL/MariaDB Database**

---

## 🚀 Installation

### 1. Download & Extract

Download the latest release and extract the `ranking` folder to your server's `resources` directory.

```
server-data/
└── resources/
    └── ranking/
        ├── fxmanifest.lua
        ├── config.lua
        ├── bridge.lua
        ├── install.sql
        ├── client/
        │   └── main.lua
        ├── server/
        │   └── main.lua
        └── html/
            ├── index.html
            ├── style.css
            └── script.js
```

### 2. Database Setup

Open **HeidiSQL** or your preferred MySQL client:

1. Connect to your FiveM database
2. Open and execute the `install.sql` file
3. Verify that `player_stats` and `kill_logs` tables are created

### 3. Discord Bot Configuration

#### Create Discord Bot:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **"New Application"** and name it (e.g., "FiveM Ranking Bot")
3. Navigate to the **"Bot"** section
4. Click **"Reset Token"** and copy the token
5. Enable these **Privileged Gateway Intents**:
   - ✅ SERVER MEMBERS INTENT
   - ✅ MESSAGE CONTENT INTENT

#### Invite Bot to Server:

6. Go to **OAuth2 > URL Generator**
7. Select scopes: `bot`
8. Select bot permissions: `Read Messages/View Channels`
9. Copy the generated URL and open it in your browser
10. Invite the bot to your Discord server

#### Get Guild ID:

11. Enable **Developer Mode** in Discord (Settings > Advanced > Developer Mode)
12. Right-click your server icon
13. Click **"Copy Server ID"**

### 4. Configure `config.lua`

Edit `config.lua` and paste your Discord credentials:

```
Config.Discord = {
    Enabled = true,
    BotToken = 'YOUR_DISCORD_BOT_TOKEN_HERE',
    GuildId = 'YOUR_DISCORD_GUILD_ID_HERE',
    CacheTime = 3600
}
```

### 5. Add to `server.cfg`

```
ensure oxmysql
ensure ranking_system
```

### 6. Restart Server

Restart your FiveM server or use the command:

```
refresh
ensure ranking_system
```

---

## ⚙️ Configuration

### Framework Detection

The script automatically detects ESX or QBCore. To manually set the framework:

```
Config.Framework = 'esx'  -- Options: 'auto', 'esx', 'qbcore', 'standalone'
```

### Kill Rewards & Death Penalties

```
Config.KillReward = {
    Enabled = true,
    Money = 100,
    AccountType = 'money'  -- 'money', 'bank', 'black_money' (ESX) or 'cash', 'bank' (QBCore)
}

Config.DeathPenalty = {
    Enabled = false,
    Money = 50,
    AccountType = 'money'
}
```

### Additional Settings

```
Config.RankingCommand = 'ranking'         -- Command to open the leaderboard
Config.VehicleKillsCount = true           -- Count kills from vehicles
Config.SuicideCountsAsDeath = true        -- Count suicides as deaths
Config.DefaultAvatar = 'https://...'      -- Fallback avatar URL
Config.DebugMode = false                  -- Enable debug commands
```

---

## 🎮 Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/ranking` | Open the kill ranking leaderboard | Everyone |
| `/rankingdebug` | Print player debug information to console | Admin (Debug Mode) |
| `/testranking` | Open UI with mock data for testing | Admin (Debug Mode) |

---

## 📊 Database Schema

### `player_stats` Table

Stores player statistics:

| Column | Type | Description |
|--------|------|-------------|
| `identifier` | VARCHAR(100) | Player identifier (license/citizenid) |
| `player_name` | VARCHAR(255) | Player display name |
| `discord_id` | VARCHAR(50) | Discord user ID |
| `discord_avatar` | TEXT | Discord avatar URL |
| `kills` | INT | Total kills |
| `deaths` | INT | Total deaths |
| `assists` | INT | Total assists |
| `headshots` | INT | Total headshot kills |
| `longest_kill_streak` | INT | Longest recorded kill streak |
| `current_kill_streak` | INT | Current kill streak |
| `last_updated` | TIMESTAMP | Last update timestamp |

### `kill_logs` Table

Stores individual kill records:

| Column | Type | Description |
|--------|------|-------------|
| `killer_identifier` | VARCHAR(100) | Killer's identifier |
| `victim_identifier` | VARCHAR(100) | Victim's identifier |
| `weapon` | VARCHAR(100) | Weapon hash/name |
| `distance` | FLOAT | Kill distance |
| `headshot` | TINYINT(1) | Headshot flag (0/1) |
| `timestamp` | TIMESTAMP | Kill timestamp |

---

## 🛠️ Troubleshooting

### Discord Avatars Not Loading

- ✅ Verify bot token is correct (no extra spaces)
- ✅ Ensure bot has **SERVER MEMBERS INTENT** enabled
- ✅ Check that the bot is in your Discord server
- ✅ Verify Guild ID is correct
- ✅ Check server console for HTTP errors
- ✅ Wait up to 60 seconds for initial cache

### Database Connection Failed

- ✅ Ensure `oxmysql` is installed and started
- ✅ Check database credentials in `server.cfg`
- ✅ Verify tables were created with `install.sql`
- ✅ Check MySQL/MariaDB is running

### Framework Not Detected

- ✅ Ensure ESX or QBCore starts **before** `ranking_system`
- ✅ Check console for framework detection message
- ✅ Manually set framework in `config.lua` if needed

### UI Not Opening

- ✅ Clear FiveM cache (F8 > `quit` > delete cache folder)
- ✅ Check browser console for errors (F12 in NUI DevTools)
- ✅ Verify all files are in the `html/` folder
- ✅ Test with `/testranking` command (Debug Mode)

---

## 🔧 Performance Optimization

### Discord Cache Time

Adjust based on server size:

```
-- Small servers (< 32 players)
Config.Discord.CacheTime = 1800  -- 30 minutes

-- Medium servers (32-64 players)
Config.Discord.CacheTime = 3600  -- 1 hour (default)

-- Large servers (64+ players)
Config.Discord.CacheTime = 7200  -- 2 hours
```

### Database Limits

```
Config.Database.TopPlayersLimit = 50  -- Limit leaderboard entries for performance
```

---


## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/luckav-dev/Ranking-Fivem-ESX-QBcore/issues)
- **Discussions**: [GitHub Discussions](https://github.com/luckav-dev/Ranking-Fivem-ESX-QBcore/discussions)
- **Discord**: [Join our Discord server](https://discord.gg/ArUJYAB48f)

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Credits

Created with ❤️ by **[luckav-dev](https://github.com/luckav-dev)**

If you found this resource helpful, please consider giving it a ⭐ on GitHub!

---

<div align="center">

**[⬆ Back to Top](#-fivem-kill-ranking-system)**

</div>
