local module = {}


--[[
	Generates a new odd table with correct formatting by scale of 100 being the largest value
	@param data {table} Data with odds and name
]]

function module:createOdds(data)
	--[[
		Format: 
		{
			{
				["Name"] = "Example", ["Weight"] = 0
			}
		}
	]]
	
	local totalWeight = 0
	local vData = {}
	
	for i,v in pairs(data) do
		data[i]["Weight"] /= 100
		print(v["Weight"] + totalWeight > 1, 1 > 1)
		if totalWeight + v["Weight"] > 1 then
			warn("Weight cannot exceed 100%")
			return
		else
			totalWeight += v["Weight"]
		end
	end
	
	if totalWeight < 1 then
		local none = 1 - totalWeight
		table.insert(data, {["Name"] = "None", ["Weight"] = none})
		totalWeight += none
	end
	
	if totalWeight == 1 then
		return data
	else
		return nil
	end
end


local function getClosestInterval(intervals, intervalRandom)
	local last = nil
	local closestGap = {}
	local smallest = {}
	local largest = {}
	local vInterval = table.clone(intervals)
	
	for i,v in pairs(intervals) do
		if not smallest["Index"] and not largest["Index"] then
			if v[1] ~= 0 and v[1] ~= 1 then
				smallest["Index"] = i
				smallest["Value"] = v[1]
			end
			if v[2] ~= 1 and v[2] ~= 0 then
				largest["Index"] = i
				largest["Value"] = v[2]
			end
			continue
		end
		
		
		if smallest["Value"] > v[1] then
			smallest["Index"] = i
			smallest["Value"] = v[1]
			continue
		end
		
		if largest["Value"] < v[2] then
			smallest["Index"] = i
			smallest["Value"] = v[2]
			continue
		end
	end
	
	if smallest["Index"] and smallest["Value"] ~= 0 then
		table.insert(vInterval, {0, 0})
	end
	
	if largest["Index"] and largest["Value"] ~= 1 then
		table.insert(vInterval, {1, 1})
	end
	
	table.sort(vInterval, function(a, b) return a[1] < b[1] end)
	
	for i,v in pairs(vInterval) do
		if not last then
			last = v[2]
			continue
		end

		local currentStart = v[1]
		local currentLast = v[2]
		local closestDist = {["Dist"] = nil, ["Closest"] = nil}

		if currentStart > last then
			if closestGap[1] == nil then
				closestGap[1] = last
				closestGap[2] = currentStart
			else
				closestDist["Closest"] = "ClosestGap"
				closestDist["Dist"] = math.abs(closestGap[1] - intervalRandom)

				if closestDist["Dist"] > math.abs(closestGap[2] - intervalRandom) then
					closestDist["Dist"] = math.abs(closestGap[2] - intervalRandom)
				end

				if closestDist["Dist"] > math.abs(currentStart - intervalRandom) then
					closestDist["Closest"] = "New"
					closestDist["Dist"] = math.abs(currentStart - intervalRandom)
				end

				if closestDist["Dist"] > math.abs(last - intervalRandom) then
					closestDist["Closest"] = "New"
					closestDist["Dist"] = math.abs(last - intervalRandom)
				end

				if closestDist["Closest"] == "New" then
					closestGap[1] = last
					closestGap[2] = currentStart
				end
			end
		end

		last = v[2]
	end
	
	return closestGap
end


--[[
	Randomly generates a seed and then creates an interval of where the reward can be obtained using a different randomized seed
	@param data {table} Data from createOdds function
]]

function module:spin(data)
	local random = Random.new(math.random(10, 9999) + os.clock() - os.time() / math.random(3, math.random(9, 10)))
	local spinSeed = random.NextNumber(random)
	local intervalRandom = Random.new(spinSeed)
	
	-- Check for valid data if not run through odds
	for i,v in pairs(data) do
		if v["Weight"] > 1 then
			module:createNewOdds(data)
		end
	end
	
	-- Creating intervals and spinning
	local spin = random.NextNumber(random)
	local prize = nil
	
	local intervals = {}

	for i,v in pairs(data) do
		local intervalSize = v["Weight"]
		local intervalRandom = intervalRandom.NextNumber(intervalRandom)
		local interval = {}
		local weight = v["Weight"]
		
		if #intervals == 0 then
			if (intervalRandom - v["Weight"] / 2) < 0 then
				interval = {0, intervalRandom + math.abs(intervalRandom - v["Weight"]) +  v["Weight"] / 2}
				table.insert(intervals, interval)
			else
				interval = {intervalRandom - v["Weight"] / 2, intervalRandom + v["Weight"] / 2}
				table.insert(intervals, interval)
			end
			if spin >= interval[1] and spin <= interval[2] then
				prize = v["Name"]
			end
			continue
		end
		
		local first = true
		
		while weight > 0 do
			first = false
			local default = {true, true}
			for _, vInterval in pairs(intervals) do
				if not (vInterval[1] >= intervalRandom - v["Weight"] / 2) then 
					default = false
				end	
				if not (vInterval[2] <= intervalRandom + v["Weight"] / 2) then
					default = false
				end
			end
			
			if first == true then
				if default[1] == true then
					interval = {intervalRandom, intervalRandom - v["Weight"] / 2}
					weight -= math.abs(intervalRandom - intervalRandom - v["Weight"]/2)
					if spin >= interval[1] and spin <= interval[2] then
						prize = v["Name"]
						break
					end
					continue
				end
				if default[2] == true then
					interval = {intervalRandom, intervalRandom + v["Weight"] / 2}
					weight -= math.abs(intervalRandom - intervalRandom + v["Weight"]/2)
					if spin >= interval[1] and spin <= interval[2] then
						prize = v["Name"]
						break
					end
					continue
				end
			end
			
			local gap = getClosestInterval(intervals, intervalRandom)
			local gapSize = gap[2] - gap[1]
			interval = {gap[1], gap[2]}
			table.insert(intervals, interval)
			weight -= gapSize
			if spin >= interval[1] and spin <= interval[2] then
				prize = v["Name"]
			end
		end
		
		if prize then
			break
		end
	end
	
	return prize
end

return module