local CDGBDL = ZO_Object:Subclass()

local CDGBDL_VARS = {
	addonName = [[CDGBossDropLogger]]
}

local LOOTCOLOR = {
	JUNK = [[C3C3C3]],
	NORMAL = [[FFFFFF]],
	FINE = [[2DC50E]],
	SUPERIOR = [[3A92FF]],
	EPIC = [[A02EF7]],
	LEGENDARY = [[EECA2]],
}

local BOSSDROPZONES = {}

local CDGBDL_SV = {}


--
-- Check if this is a known zone where bosses should be 
--
local function knownZone(zone)
	for _, v in pairs(BOSSDROPZONES) do		
		if v == zone then 
			return true 
		end
	end
	--
	-- Apparantly a zone which has bosses but we didnt know about, maybe allready in our saved vars
	--
	if CDGBDL_SV[zone] then
		return true
	end
	--
	-- Okay then we dont know ...
	--
	return false
end
--
-- This is a not perfect as we not allways have a loot target, especially if we are not looting ourselves
--
function CDGBDL:EVENT_LOOT_RECEIVED(eventCode, lootedBy, itemName, quantity, _, lootType, self)
	lootedBy = string.gsub(lootedBy,"%^%ax","")
	lootedBy = string.gsub(lootedBy,"%^%a","")
	local zone = ""
	for i = 1,4 do
		if GetUnitName("group"..i) == zo_strformat(lootedBy) then
			zone = GetUnitZone("group"..i)
			break
		end
	end
	if knownZone(zone) then
		local _, color, _ = ZO_LinkHandler_ParseLink (itemName)
		if 	color == LOOTCOLOR.SUPERIOR or
			color == LOOTCOLOR.EPIC or
			color == LOOTCOLOR.LEGENDARY then 

			local zone = GetMapName()

			local name, targetType, actionName = GetLootTargetInfo()
			if name == nil then
				name = ""
			end

			if not CDGBDL_SV[zone] then
				CDGBDL_SV[zone] = {}
			end
			if not CDGBDL_SV[zone]["drops"] then
				CDGBDL_SV[zone]["drops"] = {}
			end

			for _, v in pairs(CDGBDL_SV[zone]["drops"]) do		
				if v == itemName then 
					return 
				end
			end
			table.insert( CDGBDL_SV[zone]["drops"], {name, itemName} )
		end
	end
end
--
-- Check if we found this boss before and add it to the saved vars
--
local function findBoss(name, zone)
		--
		-- Check if we allready saved this boss
		--
		if not CDGBDL_SV[zone] then
			CDGBDL_SV[zone] = {}
		end
		if not CDGBDL_SV[zone]["boss"] then
			CDGBDL_SV[zone]["boss"] = {}
		end

		for _, v in pairs(CDGBDL_SV[zone]["boss"]) do		
			if v[1] == name then return end
		end

		SetMapToPlayerLocation()
		x,y, _ = GetMapPlayerPosition("player")

		table.insert( CDGBDL_SV[zone]["boss"], { name, x, y } )
end
--
-- Look for boss names
--
function CDGBDL:EVENT_BOSSES_CHANGED(...)
	for i = 1, 6 do
		if DoesUnitExist("boss"..i) then
			findBoss(GetUnitName("boss"..i),GetMapName())
		end
	end
end

function CDGBDL:EVENT_PLAYER_ACTIVATED(...)
	d("|cFF2222CrazyDutchGuy's|r Boss Drops Logger |c0066990.4|r Loaded, /cdgbdl for options")
	EVENT_MANAGER:UnregisterForEvent( CDGBDL_VARS.addonName, EVENT_PLAYER_ACTIVATED )	
end

local function processSlashCommands(option)
	local options = {}
    local searchResult = { string.match(option,"^(%S*)%s*(.-)$") }
    for i,v in pairs(searchResult) do
        if (v ~= nil and v ~= "") then
            options[i] = string.lower(v)
        end
    end
    if options[1] == "reset" then
    	CDGBDL_SV = {}
    else
    	d("/cdgbdl reset : For resetting saved data")
    end
end

function CDGBDL:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if addOnName == CDGBDL_VARS.addonName then
		CDGBDL_SV = ZO_SavedVars:New(CDGBDL_VARS.addonName.."_SavedVariables", 2, nil, {}) 

		SLASH_COMMANDS["/cdgbdl"] = processSlashCommands

		EVENT_MANAGER:RegisterForEvent(CDGBDL_VARS.addonName, EVENT_BOSSES_CHANGED, function(...) CDGBDL:EVENT_BOSSES_CHANGED(...) end )
		EVENT_MANAGER:RegisterForEvent(CDGBDL_VARS.addonName, EVENT_LOOT_RECEIVED, function(...) CDGBDL:EVENT_LOOT_RECEIVED(...) end)	

		EVENT_MANAGER:UnregisterForEvent( CDGBDL_VARS.addonName, EVENT_ADD_ON_LOADED )	
	end
end

function CDGBDL_OnInitialized()
	EVENT_MANAGER:RegisterForEvent(CDGBDL_VARS.addonName, EVENT_ADD_ON_LOADED, function(...) CDGBDL:EVENT_ADD_ON_LOADED(...) end )		
	EVENT_MANAGER:RegisterForEvent(CDGBDL_VARS.addonName, EVENT_PLAYER_ACTIVATED, function(...) CDGBDL:EVENT_PLAYER_ACTIVATED(...) end )		
end
