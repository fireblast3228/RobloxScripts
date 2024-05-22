local data = {}
local queue = {}
local dss = game:GetService("DataStoreService")
local defaults = require(script.Default)
local module = {}

--[[
	Retrieves player data
	@param player {Player} instance to retrieve data from
]]

function module:get(player: Player)
	-- Defining datastore and retrieving the key
	local ds = dss:GetDataStore(player.UserId)
	local ods = dss:GetOrderedDataStore(player.UserId)
	local pages = ods:GetSortedAsync(false, 2)
	local key = pages:GetCurrentPage()[1]
	local maxRetries = 3
	local delayTime = 3
	
	if data[player.UserId] then
		return data[player.UserId]
	end
	
	if not data[player.UserId] and queue[player.UserId] then
		print("Already in queue")
		repeat wait() until data[player.UserId]
		return data[player.UserId]
	end
	
	queue[player.UserId] = true
	
	-- Retrieving playerdata
	if not key then
		-- Identified new player
		data[player.UserId] = defaults
		data[player.UserId].Server = game.JobId
		ods:SetAsync(1, os.time())
		ds:SetAsync(1, data[player.UserId])
		print("Creating new data for ", player.Name)
	else
		key = key.key
		-- Recursively call to check for server locks
		local function get(retry: number)
			ds:UpdateAsync(key, function(playerData)
				print(playerData.Server)
				if playerData and playerData.Server then
					return nil
				end
				
				playerData.Server = game.JobId
				data[player.UserId] = playerData
				
				return playerData
			end)
			
			if data[player.UserId] == nil and retry < maxRetries then
				task.wait(3)
				get(retry + 1)
			else
				-- Disregarding serverlock after max attempts
				local playerData = ds:GetAsync(key)
				playerData.Server = game.JobId
				data[player.UserId] = playerData
			end
		end
		
		-- Async data call
		coroutine.wrap(get)(1)
	end
	
end

--[[
	Saves player data
	@param player {Player} Player instance to save data
]]

function module:save(player: Player)
	-- Defining datastores and key
	local ds = dss:GetDataStore(player.UserId)
	local ods = dss:GetOrderedDataStore(player.UserId)
	local pages = ods:GetSortedAsync(false, 1)
	local key = pages:GetCurrentPage()[1]
	
	
	-- Saving
	print(key, data[player.UserId])
	if key and data[player.UserId] then
		key = key.key
		if data[player.UserId].Server == game.JobId then
			data[player.UserId].Server = nil
			ds:SetAsync(key + 1, data[player.UserId])
			ods:SetAsync(key + 1, os.time())
		else
			warn("[Warning]: Failed to save due to the save file belonging to another server!")
		end
	end
end

return module