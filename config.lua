Config = {}

Config.Framework = 'auto'

Config.Discord = {
    Enabled = true,
    BotToken = 'YOUR_DISCORD_BOT_TOKEN_HERE',
    GuildId = 'YOUR_DISCORD_GUILD_ID_HERE',
    CacheTime = 3600
}

Config.Database = {
    UpdateInterval = 60000,
    TopPlayersLimit = 50
}

Config.RankingCommand = 'ranking'
Config.KillReward = {
    Enabled = true,           -- Enable/disable kill reward
    Money = 100,              -- Amount of money to give
    AccountType = 'money'     -- Account type: 'money' (cash), 'bank', 'black_money'
}

Config.DeathPenalty = {
    Enabled = false,          -- Enable/disable death penalty
    Money = 50,               -- Amount of money to take
    AccountType = 'money'     -- Account type: 'money' (cash), 'bank', 'black_money'
}

Config.VehicleKillsCount = true

Config.SuicideCountsAsDeath = true

Config.DefaultAvatar = 'https://cdn.discordapp.com/embed/avatars/0.png'

Config.DebugMode = false
