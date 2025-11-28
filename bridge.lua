Framework = {}

local frameworkName = nil
local frameworkObject = nil

function DetectFramework()
    if Config.Framework ~= 'auto' then
        frameworkName = Config.Framework
    else
        if GetResourceState('es_extended') == 'started' then
            frameworkName = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            frameworkName = 'qbcore'
        else
            frameworkName = 'standalone'
        end
    end
    
    if frameworkName == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        frameworkObject = ESX
    elseif frameworkName == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
        frameworkObject = QBCore
    end
    
    print('^2[Ranking System]^7 Framework detected: ^3' .. frameworkName .. '^7')
    return frameworkName
end

if IsDuplicityVersion() then
    
    function Framework.GetPlayer(source)
        if frameworkName == 'esx' then
            return frameworkObject.GetPlayerFromId(source)
        elseif frameworkName == 'qbcore' then
            return frameworkObject.Functions.GetPlayer(source)
        end
        return nil
    end
    
    function Framework.GetPlayerIdentifier(source)
        if frameworkName == 'esx' then
            local xPlayer = Framework.GetPlayer(source)
            return xPlayer and xPlayer.identifier or nil
        elseif frameworkName == 'qbcore' then
            local Player = Framework.GetPlayer(source)
            return Player and Player.PlayerData.citizenid or nil
        else
            return GetPlayerIdentifierByType(source, 'license')
        end
    end
    
    function Framework.GetPlayerName(source)
        if frameworkName == 'esx' then
            local xPlayer = Framework.GetPlayer(source)
            return xPlayer and xPlayer.getName() or GetPlayerName(source)
        elseif frameworkName == 'qbcore' then
            local Player = Framework.GetPlayer(source)
            return Player and Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname or GetPlayerName(source)
        else
            return GetPlayerName(source)
        end
    end
    
    function Framework.AddMoney(source, amount)
        if not Config.KillReward.Enabled then return end
        
        if frameworkName == 'esx' then
            local xPlayer = Framework.GetPlayer(source)
            if xPlayer then
                if Config.KillReward.AccountType == 'money' then
                    xPlayer.addMoney(amount)
                else
                    xPlayer.addAccountMoney(Config.KillReward.AccountType, amount)
                end
            end
        elseif frameworkName == 'qbcore' then
            local Player = Framework.GetPlayer(source)
            if Player then
                Player.Functions.AddMoney(Config.KillReward.AccountType, amount)
            end
        end
    end
    
    function Framework.RemoveMoney(source, amount)
        if not Config.DeathPenalty.Enabled then return end
        
        if frameworkName == 'esx' then
            local xPlayer = Framework.GetPlayer(source)
            if xPlayer then
                if Config.DeathPenalty.AccountType == 'money' then
                    xPlayer.removeMoney(amount)
                else
                    xPlayer.removeAccountMoney(Config.DeathPenalty.AccountType, amount)
                end
            end
        elseif frameworkName == 'qbcore' then
            local Player = Framework.GetPlayer(source)
            if Player then
                Player.Functions.RemoveMoney(Config.DeathPenalty.AccountType, amount)
            end
        end
    end
    
    function Framework.Notify(source, message, type)
        if frameworkName == 'esx' then
            local xPlayer = Framework.GetPlayer(source)
            if xPlayer then
                xPlayer.showNotification(message)
            end
        elseif frameworkName == 'qbcore' then
            TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = {message}
            })
        end
    end
else
    
    function Framework.ShowNotification(message)
        if frameworkName == 'esx' then
            frameworkObject.ShowNotification(message)
        elseif frameworkName == 'qbcore' then
            frameworkObject.Functions.Notify(message, 'primary')
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentString(message)
            DrawNotification(false, false)
        end
    end
end

CreateThread(function()
    DetectFramework()
end)
