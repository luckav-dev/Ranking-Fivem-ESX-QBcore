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

-- Recompensa por Kill
Config.KillReward = {
    Enabled = true,           -- Activar/desactivar recompensa por kill
    Money = 100,              -- Cantidad de dinero a dar
    AccountType = 'money'     -- Tipo de cuenta: 'money' (efectivo), 'bank' (banco), 'black_money' (dinero negro)
}

-- Penalización por Muerte
Config.DeathPenalty = {
    Enabled = false,          -- Activar/desactivar penalización por muerte
    Money = 50,               -- Cantidad de dinero a quitar
    AccountType = 'money'     -- Tipo de cuenta: 'money' (efectivo), 'bank' (banco), 'black_money' (dinero negro)
}

Config.VehicleKillsCount = true

Config.SuicideCountsAsDeath = true

Config.DefaultAvatar = 'https://cdn.discordapp.com/embed/avatars/0.png'

Config.DebugMode = false
