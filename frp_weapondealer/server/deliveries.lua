RegisterServerEvent('frp_weapondealer:server:updateDealerItems')
AddEventHandler('frp_weapondealer:server:updateDealerItems', function(itemData, amount, dealer)
    Config.Dealers[dealer]["products"][itemData.slot].amount = Config.Dealers[dealer]["products"][itemData.slot].amount - amount

    TriggerClientEvent('frp_weapondealer:client:setDealerItems', -1, itemData, amount, dealer)
end)

RegisterServerEvent('frp_weapondealer:server:giveDeliveryItems')
AddEventHandler('frp_weapondealer:server:giveDeliveryItems', function()
    RSCore.Functions.BanInjection(source, 'frp_weapondealer (giveDeliveryItems)')
end)

RSCore.Functions.CreateCallback('frp_weapondealer:giveDeliveryItems', function(source, cb, amount)
    local src = source
    local Player = RSCore.Functions.GetPlayer(src)

    Player.Functions.AddItem('explosive', amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSCore.Shared.Items["explosive"], "add")
end)

RSCore.Functions.CreateCallback('frp_weapondealer:server:RequestConfig', function(source, cb)
    cb(Config.Dealers)
end)

RegisterServerEvent('frp_weapondealer:server:succesDelivery')
AddEventHandler('frp_weapondealer:server:succesDelivery', function(deliveryData, inTime)
    local src = source
    local Player = RSCore.Functions.GetPlayer(src)
    local curRep = Player.PlayerData.metadata["wepdealerrep"]

    if inTime then
        if Player.Functions.GetItemByName('explosive') ~= nil and Player.Functions.GetItemByName('explosive').amount >= deliveryData["amount"] then
            Player.Functions.RemoveItem('explosive', deliveryData["amount"])
            local cops = GetCurrentCops()
            local price = 3000
            if cops == 1 then
                price = 4000
            elseif cops == 2 then
                price = 5000
            elseif cops >= 3 then
                price = 6000
            end
            if curRep < 10 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 8), "dilvery-guns")
            elseif curRep >= 10 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 10), "dilvery-guns")
            elseif curRep >= 20 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 12), "dilvery-guns")
            elseif curRep >= 30 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 15), "dilvery-guns")
            elseif curRep >= 40 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 18), "dilvery-guns")
            end

            TriggerClientEvent('inventory:client:ItemBox', src, RSCore.Shared.Items["explosive"], "remove")
            TriggerClientEvent('RSCore:Notify', src, 'The order has been delivered complete', 'success')

            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('frp_weapondealer:client:sendDeliveryMail', src, 'perfect', deliveryData)

                Player.Functions.SetMetaData('wepdealerrep', (curRep + 1))
            end)
        else
            TriggerClientEvent('RSCore:Notify', src, 'This does not match the order...', 'error')

            if Player.Functions.GetItemByName('explosive').amount >= 0 then
                Player.Functions.RemoveItem('explosive', Player.Functions.GetItemByName('explosive').amount)
                Player.Functions.AddMoney('cash', (Player.Functions.GetItemByName('explosive').amount * 6000 / 100 * 5))
            end

            TriggerClientEvent('inventory:client:ItemBox', src, RSCore.Shared.Items["explosive"], "remove")

            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('frp_weapondealer:client:sendDeliveryMail', src, 'bad', deliveryData)

                if curRep - 1 > 0 then
                    Player.Functions.SetMetaData('wepdealerrep', (curRep - 1))
                else
                    Player.Functions.SetMetaData('wepdealerrep', 0)
                end
            end)
        end
    else
        TriggerClientEvent('RSCore:Notify', src, 'Youre too late...', 'error')

        Player.Functions.RemoveItem('explosive', deliveryData["amount"])
        Player.Functions.AddMoney('cash', (deliveryData["amount"] * 6000 / 100 * 4), "dilvery-guns-too-late")

        TriggerClientEvent('inventory:client:ItemBox', src, RSCore.Shared.Items["explosive"], "remove")

        SetTimeout(math.random(5000, 10000), function()
            TriggerClientEvent('frp_weapondealer:client:sendDeliveryMail', src, 'late', deliveryData)

            if curRep - 1 > 0 then
                Player.Functions.SetMetaData('wepdealerrep', (curRep - 1))
            else
                Player.Functions.SetMetaData('wepdealerrep', 0)
            end
        end)
    end
end)

RegisterServerEvent('frp_weapondealer:server:callCops')
AddEventHandler('frp_weapondealer:server:callCops', function(streetLabel, coords)
    local msg = "There is a suspicious situation on "..streetLabel..", possibly arms trade."
    local alertData = {
        title = "Arms trade",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = msg
    }
    for k, v in pairs(RSCore.Functions.GetPlayers()) do
        local Player = RSCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty) then
                TriggerClientEvent("frp_weapondealer:client:robberyCall", Player.PlayerData.source, msg, streetLabel, coords)
                TriggerClientEvent("rs-phone:client:addPoliceAlert", Player.PlayerData.source, alertData)
            end
        end
	end
end)

function GetCurrentCops()
    local amount = 0
    for k, v in pairs(RSCore.Functions.GetPlayers()) do
        local Player = RSCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty) then
                amount = amount + 1
            end
        end
    end
    return amount
end