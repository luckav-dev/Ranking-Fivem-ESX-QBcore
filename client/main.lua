local isDead = false
local currentKillStreak = 0

RegisterNetEvent('ranking:client:openUI')
AddEventHandler('ranking:client:openUI', function(data)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        players = data
    })
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(100)
        
        local playerPed = PlayerPedId()
        
        if IsEntityDead(playerPed) and not isDead then
            isDead = true
            local killer = GetPedSourceOfDeath(playerPed)
            local killerServerId = nil
            local causeHash = GetPedCauseOfDeath(playerPed)
            local weapon = nil
            local distance = 0
            local headshot = false
            
            if killer ~= playerPed then
                if IsEntityAPed(killer) and IsPedAPlayer(killer) then
                    killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killer))
                    local killerCoords = GetEntityCoords(killer)
                    local victimCoords = GetEntityCoords(playerPed)
                    distance = #(killerCoords - victimCoords)
                    headshot = (GetPedLastDamageBone(playerPed) == 31086)
                end
            end
            
            if causeHash ~= 0 then
                weapon = causeHash
            end
            
            TriggerServerEvent('ranking:server:registerDeath', killerServerId, weapon, distance, headshot)
            currentKillStreak = 0
        elseif not IsEntityDead(playerPed) and isDead then
            isDead = false
        end
    end
end)

RegisterNetEvent('ranking:client:killNotification')
AddEventHandler('ranking:client:killNotification', function(victimName, reward)
    currentKillStreak = currentKillStreak + 1
    
    local message = 'You killed ' .. victimName
    if currentKillStreak > 1 then
        message = message .. ' | Kill Streak: ' .. currentKillStreak
    end
    if reward > 0 then
        message = message .. ' | +$' .. reward
    end
    
    Framework.ShowNotification(message)
end)

RegisterCommand(Config.RankingCommand, function()
    TriggerServerEvent('ranking:server:requestData')
end, false)

if Config.DebugMode then
    RegisterCommand('testranking', function()
        local mockData = {}
        for i = 1, 10 do
            table.insert(mockData, {
                rank = i,
                name = 'Player ' .. i,
                avatar = Config.DefaultAvatar,
                k = tostring(math.random(100, 3000)),
                d = tostring(math.random(50, 500)),
                a = tostring(math.random(50, 1500))
            })
        end
        
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'open',
            players = mockData
        })
    end, false)
end
