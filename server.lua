NDCore = exports["Ayse_Core"]:GetCoreObject()

RegisterNetEvent("Ayse_ShotSpotter:Trigger", function(street, pedCoords, postal, zoneName)
    if server_config.useDiscordLogging then
        local embed = {
            {
                title = "ShotSpotter Alert",
                description = "Gunshots detected on " .. zoneName .. ", " .. street .. "." ,
                fields = {
                    {
                        name = "Location:",
                        value = zoneName .. ", **" .. street .. "**"
                    }
                },
                footer = {
                    icon_url = "https://i.imgur.com/FJzMEKv.png",
                    text = "AyseFramework ShotSpotter"
                },
                thumbnail = {
                    url = "https://i.imgur.com/BTbxJZu.png"
                },
                color = 16722976
            }
        }
        if postal then
            embed[1].description = "Gunshots detected on " .. zoneName .. ", " .. street .. " (" .. postal .. ")."
            embed[1].fields[2] = {
                name = "Postal:",
                value = postal
            }
        end
        PerformHttpRequest(server_config.discordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "Ayse Shotspotter", embeds = embed}), {["Content-Type"] = "application/json"})
    end
    TriggerClientEvent("Ayse_ShotSpotter:Report", -1, street, pedCoords, postal)
end)