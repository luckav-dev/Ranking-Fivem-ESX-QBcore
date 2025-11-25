local discordCache = {}
local lastCacheClean = os.time()

function GetDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, v in pairs(identifiers) do
        if string.match(v, 'discord:') then
            return string.gsub(v, 'discord:', '')
        end
    end
    return nil
end

function GetDiscordAvatar(discordId)
    if not Config.Discord.Enabled or not discordId then
        return Config.DefaultAvatar
    end
    
    if discordCache[discordId] and (os.time() - discordCache[discordId].timestamp) < Config.Discord.CacheTime then
        return discordCache[discordId].avatar
    end
    
    local avatar = Config.DefaultAvatar
    
    PerformHttpRequest('https://discord.com/api/v10/users/' .. discordId, function(statusCode, response, headers)
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
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. Config.Discord.BotToken,
        ['Content-Type'] = 'application/json'
    })
    
    Wait(500)
    
    if discordCache[discordId] then
        return discordCache[discordId].avatar
    end
    
    return avatar
end

function InitializePlayerStats(identifier, playerName, discordId)
    MySQL.Async.fetchScalar('SELECT identifier FROM player_stats WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if not result then
            local avatar = GetDiscordAvatar(discordId)
            
            MySQL.Async.execute('INSERT INTO player_stats (identifier, player_name, discord_id, discord_avatar, kills, deaths, assists) VALUES (@identifier, @playerName, @discordId, @avatar, 0, 0, 0)', {
                ['@identifier'] = identifier,
                ['@playerName'] = playerName,
                ['@discordId'] = discordId,
                ['@avatar'] = avatar
            })
        else
            local avatar = GetDiscordAvatar(discordId)
            
            MySQL.Async.execute('UPDATE player_stats SET player_name = @playerName, discord_id = @discordId, discord_avatar = @avatar WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@playerName'] = playerName,
                ['@discordId'] = discordId,
                ['@avatar'] = avatar
            })
        end
    end)
end

RegisterNetEvent('ranking:server:registerDeath')
AddEventHandler('ranking:server:registerDeath', function(killerServerId, weapon, distance, headshot)
    local victimSource = source
    local victimIdentifier = Framework.GetPlayerIdentifier(victimSource)
    local victimName = Framework.GetPlayerName(victimSource)
    
    if not victimIdentifier then return end
    
    MySQL.Async.execute('UPDATE player_stats SET deaths = deaths + 1, current_kill_streak = 0 WHERE identifier = @identifier', {
        ['@identifier'] = victimIdentifier
    })
    
    if Config.DeathPenalty.Enabled then
        Framework.RemoveMoney(victimSource, Config.DeathPenalty.Money)
    end
    
    if killerServerId and killerServerId ~= victimSource then
        local killerIdentifier = Framework.GetPlayerIdentifier(killerServerId)
        local killerName = Framework.GetPlayerName(killerServerId)
        
        if killerIdentifier then
            MySQL.Async.execute('UPDATE player_stats SET kills = kills + 1, current_kill_streak = current_kill_streak + 1 WHERE identifier = @identifier', {
                ['@identifier'] = killerIdentifier
            }, function(affectedRows)
                MySQL.Async.fetchScalar('SELECT current_kill_streak FROM player_stats WHERE identifier = @identifier', {
                    ['@identifier'] = killerIdentifier
                }, function(streak)
                    if streak then
                        MySQL.Async.execute('UPDATE player_stats SET longest_kill_streak = GREATEST(longest_kill_streak, @streak) WHERE identifier = @identifier', {
                            ['@identifier'] = killerIdentifier,
                            ['@streak'] = streak
                        })
                    end
                end)
            end)
            
            if headshot then
                MySQL.Async.execute('UPDATE player_stats SET headshots = headshots + 1 WHERE identifier = @identifier', {
                    ['@identifier'] = killerIdentifier
                })
            end
            
            MySQL.Async.execute('INSERT INTO kill_logs (killer_identifier, victim_identifier, weapon, distance, headshot) VALUES (@killer, @victim, @weapon, @distance, @headshot)', {
                ['@killer'] = killerIdentifier,
                ['@victim'] = victimIdentifier,
                ['@weapon'] = weapon or 'unknown',
                ['@distance'] = distance,
                ['@headshot'] = headshot and 1 or 0
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
    
    MySQL.Async.fetchAll('SELECT * FROM player_stats ORDER BY kills DESC LIMIT @limit', {
        ['@limit'] = Config.Database.TopPlayersLimit
    }, function(results)
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
        Wait(1000)
        InitializePlayerStats(identifier, playerName, discordId)
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
    
    MySQL.Async.fetchAll('SELECT * FROM player_stats', {}, function(results)
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
        local avatar = GetDiscordAvatar(discordId)
        
        print('^3[Debug] Player Info:^7')
        print('  Source: ' .. source)
        print('  Identifier: ' .. (identifier or 'nil'))
        print('  Discord ID: ' .. (discordId or 'nil'))
        print('  Avatar URL: ' .. avatar)
        
        Framework.Notify(source, 'Debug info printed to console', 'success')
    end, true)
end
