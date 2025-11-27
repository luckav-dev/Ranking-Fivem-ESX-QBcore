local discordCache = {}
local lastCacheClean = os.time()
local pendingAvatars = {}

function GetDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, v in pairs(identifiers) do
        if string.match(v, 'discord:') then
            return string.gsub(v, 'discord:', '')
        end
    end
    return nil
end

function GetDiscordAvatar(discordId, callback)
    if not Config.Discord.Enabled or not discordId then
        if callback then callback(Config.DefaultAvatar) end
        return Config.DefaultAvatar
    end
    
    if discordCache[discordId] and (os.time() - discordCache[discordId].timestamp) < Config.Discord.CacheTime then
        if callback then callback(discordCache[discordId].avatar) end
        return discordCache[discordId].avatar
    end
    
    if pendingAvatars[discordId] then
        if callback then
            table.insert(pendingAvatars[discordId], callback)
        end
        return Config.DefaultAvatar
    end
    
    pendingAvatars[discordId] = {}
    if callback then
        table.insert(pendingAvatars[discordId], callback)
    end
    
    PerformHttpRequest('https://discord.com/api/v10/users/' .. discordId, function(statusCode, response, headers)
        local avatar = Config.DefaultAvatar
        
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.avatar then
                if string.sub(data.avatar, 1, 2) == 'a_' then
                    avatar = string.format('https://cdn.discordapp.com/avatars/%s/%s.gif', discordId, data.avatar)
                else
                    avatar = string.format('https://cdn.discordapp.com/avatars/%s/%s.png', discordId, data.avatar)
                end
                
                discordCache[discordId] = {
                    avatar = avatar,
                    timestamp = os.time()
                }
            end
        end
        
        if pendingAvatars[discordId] then
            for _, cb in ipairs(pendingAvatars[discordId]) do
                cb(avatar)
            end
            pendingAvatars[discordId] = nil
        end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. Config.Discord.BotToken,
        ['Content-Type'] = 'application/json'
    })
    
    return Config.DefaultAvatar
end

function InitializePlayerStats(identifier, playerName, discordId)
    exports.oxmysql:scalar('SELECT identifier FROM player_stats WHERE identifier = ?', {identifier}, function(result)
        GetDiscordAvatar(discordId, function(avatar)
            if not result then
                exports.oxmysql:execute('INSERT INTO player_stats (identifier, player_name, discord_id, discord_avatar, kills, deaths, assists) VALUES (?, ?, ?, ?, 0, 0, 0)', {
                    identifier,
                    playerName,
                    discordId,
                    avatar
                })
            else
                exports.oxmysql:execute('UPDATE player_stats SET player_name = ?, discord_id = ?, discord_avatar = ? WHERE identifier = ?', {
                    playerName,
                    discordId,
                    avatar,
                    identifier
                })
            end
        end)
    end)
end

RegisterNetEvent('ranking:server:registerDeath')
AddEventHandler('ranking:server:registerDeath', function(killerServerId, weapon, distance, headshot)
    local victimSource = source
    local victimIdentifier = Framework.GetPlayerIdentifier(victimSource)
    local victimName = Framework.GetPlayerName(victimSource)
    
    if not victimIdentifier then return end
    
    exports.oxmysql:execute('UPDATE player_stats SET deaths = deaths + 1, current_kill_streak = 0 WHERE identifier = ?', {victimIdentifier})
    
    if Config.DeathPenalty.Enabled then
        Framework.RemoveMoney(victimSource, Config.DeathPenalty.Money)
    end
    
    if killerServerId and killerServerId ~= victimSource then
        local killerIdentifier = Framework.GetPlayerIdentifier(killerServerId)
        local killerName = Framework.GetPlayerName(killerServerId)
        
        if killerIdentifier then
            exports.oxmysql:execute('UPDATE player_stats SET kills = kills + 1, current_kill_streak = current_kill_streak + 1 WHERE identifier = ?', {killerIdentifier}, function(affectedRows)
                exports.oxmysql:scalar('SELECT current_kill_streak FROM player_stats WHERE identifier = ?', {killerIdentifier}, function(streak)
                    if streak then
                        exports.oxmysql:execute('UPDATE player_stats SET longest_kill_streak = GREATEST(longest_kill_streak, ?) WHERE identifier = ?', {
                            streak,
                            killerIdentifier
                        })
                    end
                end)
            end)
            
            if headshot then
                exports.oxmysql:execute('UPDATE player_stats SET headshots = headshots + 1 WHERE identifier = ?', {killerIdentifier})
            end
            
            exports.oxmysql:execute('INSERT INTO kill_logs (killer_identifier, victim_identifier, weapon, distance, headshot) VALUES (?, ?, ?, ?, ?)', {
                killerIdentifier,
                victimIdentifier,
                weapon or 'unknown',
                distance,
                headshot and 1 or 0
            })
            
            if Config.KillReward.Enabled then
                Framework.AddMoney(killerServerId, Config.KillReward.Money)
                TriggerClientEvent('ranking:client:killNotification', killerServerId, victimName, Config.KillReward.Money)
            else
                TriggerClientEvent('ranking:client:killNotification', killerServerId, victimName, 0)
            end
        end
    end
end)

RegisterNetEvent('ranking:server:requestData')
AddEventHandler('ranking:server:requestData', function()
    local source = source
    
    exports.oxmysql:query('SELECT * FROM player_stats ORDER BY kills DESC LIMIT ?', {Config.Database.TopPlayersLimit}, function(results)
        local players = {}
        
        for i, row in ipairs(results) do
            local kd = row.deaths > 0 and (row.kills / row.deaths) or row.kills
            
            table.insert(players, {
                rank = i,
                name = row.player_name,
                avatar = row.discord_avatar or Config.DefaultAvatar,
                k = tostring(row.kills),
                d = tostring(row.deaths),
                a = tostring(row.assists),
                kd = string.format('%.2f', kd)
            })
        end
        
        TriggerClientEvent('ranking:client:openUI', source, players)
    end)
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local source = source
    local identifier = Framework.GetPlayerIdentifier(source)
    local discordId = GetDiscordId(source)
    
    if identifier then
        SetTimeout(1000, function()
            InitializePlayerStats(identifier, playerName, discordId)
        end)
    end
end)

CreateThread(function()
    while true do
        Wait(Config.Discord.CacheTime * 1000)
        
        if (os.time() - lastCacheClean) > Config.Discord.CacheTime then
            discordCache = {}
            lastCacheClean = os.time()
            
            if Config.DebugMode then
                print('^3[Ranking System]^7 Discord cache cleaned')
            end
        end
    end
end)

CreateThread(function()
    Wait(5000)
    
    exports.oxmysql:query('SELECT * FROM player_stats', {}, function(results)
        if results then
            print('^2[Ranking System]^7 Database connected successfully')
            print('^2[Ranking System]^7 Loaded ' .. #results .. ' player records')
        else
            print('^1[Ranking System]^7 Database connection failed!')
        end
    end)
end)

if Config.DebugMode then
    RegisterCommand('rankingdebug', function(source, args)
        local identifier = Framework.GetPlayerIdentifier(source)
        local discordId = GetDiscordId(source)
        
        GetDiscordAvatar(discordId, function(avatar)
            print('^3[Debug] Player Info:^7')
            print('  Source: ' .. source)
            print('  Identifier: ' .. (identifier or 'nil'))
            print('  Discord ID: ' .. (discordId or 'nil'))
            print('  Avatar URL: ' .. avatar)
            
            Framework.Notify(source, 'Debug info printed to console', 'success')
        end)
    end, true)
end
