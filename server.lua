--[[                                                                                                                                                                            
-----------------------------------------------------------------------------------------
---------------Anti-VPN script created by Overlord and tweaked by thealex-br--------------
-----------------------------------------------------------------------------------------
Commands available: /checkVPN (case insensitive)
--]]

local WHITELISTED_IPS = {
	["127.0.0.1"] = true,
}

local CACHED_IPS = {}

function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if name then
		local players = getElementsByType("player")
        for i, player in ipairs(players) do
            local name_ = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if name_:find(name, 1, true) then
                return player
            end
        end
    end
	return false
end

local function checkIfPlayerIsUsingVPN(player, requester)
	assert(isElement(player) and getElementType(player) == "player", "Expected player at argument 1, got "..(isElement(player) and getElementType(player) or type(player)))
	
	local IP = getPlayerIP(player)
	if WHITELISTED_IPS[IP] then
		if isElement(requester) then 
			outputChatBox(getPlayerName(player).."'s IP is whitelisted", requester, 255, 0, 0)
		end	
		return false
	end
	
	fetchRemote("https://proxy.mind-media.com/block/proxycheck.php?ip="..IP, function(data, err)
		if err ~= 0 then
			if isElement(requester) then 
				outputChatBox("Error while connecting to the server", requester, 255, 0, 0)
			end	
			return
		end

		if data == "Y" then
			kickPlayer(player, "VPN Detected.")
			if not CACHED_IPS[IP] then
				CACHED_IPS[IP] = true
			end
			if isElement(requester) then
				outputChatBox(getPlayerName(player).." appears to be using a VPN.", requester, 255, 0, 0)
			end
		end
		if data == "N" and isElement(requester) then
			outputChatBox(getPlayerName(player).." appears NOT to be using a VPN.", requester, 0, 255, 0)
		end
		if data == "X" and isElement(requester) then 
			outputChatBox("Something is wrong with "..getPlayerName(player).."'s IP.", requester, 255, 0, 0)
		end
	end)
	return true
end

addEventHandler("onPlayerConnect", root, function(_, IP)
	if CACHED_IPS[IP] then
		cancelEvent(true, "VPN Detected.")
	end
end)

addEventHandler("onPlayerJoin", root, function()
	checkIfPlayerIsUsingVPN(source, false)
end)

addEventHandler("onResourceStart", resourceRoot, function()
	local players = getElementsByType("player")
	for i, player in ipairs(players) do
		setTimer(checkIfPlayerIsUsingVPN, i * 100, 1, player)
	end
end)

addCommandHandler("checkVPN", function(cmder, cmd, target)
	local cmderAcc = getPlayerAccount(cmder)
	if not isGuestAccount(cmderAcc) and isObjectInACLGroup("user."..getAccountName(cmderAcc), aclGetGroup("Admin")) then
		if type(target) ~= "string" then
			return outputChatBox("/checkVPN <player's name>", cmder, 255, 0, 0)
		end
		
		local player = getPlayerFromPartialName(target)
		if not player then
			return outputChatBox("Couldn't find such player.", cmder, 255, 0, 0)
		end
		checkIfPlayerIsUsingVPN(player, cmder)
	else
		outputDebugString("WARNING: "..getPlayerName(cmder).." has tried to use /checkVPN", 4, 255, 0, 0)
	end
end, false, false)