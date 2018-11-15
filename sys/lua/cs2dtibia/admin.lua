addhook('say','adminCommands',-1)
adminList = {13266} --13266
function isAdmin(id)
	for _, usgn in ipairs(adminList) do
		if player(id,'usgn') == usgn then
			return true
		end
	end
	return false
end
--[[
Admin Commands
!a - teleport forward
!b - broadcast to server with name
!c - teleport player to you
!d - broadcast to server without name
!e - explosion
!i - spawn item
!h - heal player
!l - run lua script (expensive)
!m - summon monster
!n - return npc position
!o - return tile position
!p - return position
!q - earthquake
!s - speedmod
!t - teleport you to player
!u - shutdown
!v - save server
]]
function adminCommands(id,words)
	if isAdmin(id) and words:sub(1,1) =='!' then
		local command = words:lower():sub(2,2)
		if words:sub(3,3) ~= ' ' and #words ~= 2 then return end
		print(player(id,'name')..' used a command:'..words)
		if command =='a' then
			local distance = tonumber(words:sub(4))
			if distance then
				local rot = math.rad(player(id,'rot')-180)
				local x, y = -math.sin(rot)*distance*32, math.cos(rot)*distance*32
				parse('setpos '..id..' '..player(id,'x')+x..' '..player(id,'y')+y)
			else
				msg2(id,'Teleport forward: "!a <distance>"')
			end
			return 1
		elseif command =='b' then
			msg('©255100100'..player(id,'name')..' : '..words:sub(4)..'@C')
			return 1
		elseif command =='c' then
			local target = tonumber(words:sub(4))
			if target then
				if player(target,'exists') then
					if target == id then
						msg2(id,'You may not teleport to yourself!')
					end
					parse('setpos '..target..' '..player(id,'x')..' '..player(id,'y'))
					return 1
				end
			end
			msg2(id,'Teleport player to you: "!c <targetid>"')
			return 1
		elseif command =='d' then
			msg('©255100100'..words:sub(4)..'@C')
			return 1
		elseif command =='e' then
			local dmg = tonumber(words:sub(4))
			if dmg then
				parse('explosion '..player(id,'x')..' '..player(id,'y')..' '..dmg..' '..dmg..' '..id)
				return 1
			end
			msg2(id,'Spawn explosion: "!e <dmg>"')
			return 1
		elseif command =='i' then
			local itemid = tonumber(words:sub(4))
			if itemid then
				additem(id,itemid)
				return 1
			end
			msg2(id,'Spawn item: "!i <itemid>"')
			return 1
		elseif command =='h' then
			local s = words:find(' ',4)
			local target = tonumber(words:sub(4,s))
			if target then
				if player(target,'exists') then
					local heal = s and tonumber(words:sub(s+1,words:find(' ',s+1))) or nil
					if heal then
						parse('explosion '..player(target,'x')..' '..player(target,'y')..' 1 '..(-heal))
						return 1
					end
				end
			end
			msg2(id,'Heal player: "!h <targetid> <amount>"')
			return 1
		elseif command =='l' then
			local script = words:sub(4)
			if script then
				msg2(id,tostring(assert(loadstring(script))() or 'done!'))
				return
			end
			msg2(id,'Run lua script: "!l <script>"')
			return 1
		elseif command =='m' then
			if gettile(player(id, 'tilex'), player(id, 'tiley')).SAFE then
				msg2(id,'You may not spawn a mosnter in a safe zone.')
				return 1
			end
			local name = words:sub(4)
			if name then
				for i, v in pairs(CONFIG.MONSTERS) do
					if v.name:lower() == name:lower() then
						local m = deepcopy(v)
						m.x, m.y = player(id, 'x'), player(id, 'y')
						Monster:new(m)
						msg2(id,'Monster ' .. name .. ' spawned.')
						return 1
					end
				end
			end
			msg2(id,'Monster ' .. name .. ' does not exist.')
			return 1
		elseif command =='n' then
			msg2(id,'{'..player(id,'tilex')*32+16 ..', '..player(id,'tiley')*32+16 ..'}')
			return 1
		elseif command =='o' then
			msg2(id,'{'..player(id,'tilex')..', '..player(id,'tiley')..'}')
			return 1
		elseif command =='p' then
			msg2(id,'{'..player(id,'x')..', '..player(id,'y')..'}')
			return 1
		elseif command =='q' then
			local length = tonumber(words:sub(3))
			if length then
				length = math.min(length*50,250)
				for _, id in ipairs(player(0,'table')) do
					parse('shake '..id..' '..length)
				end
				for i = 1, 6 do
					if math.random(0,1) == 1 then
						parse('sv_sound weapons/explode'..i..'.wav')
					end
				end
			else
				msg2(id,'Earthquake: "!q <length in seconds, max 5>"')
			end
			return 1
		elseif command =='s' then
			local s = words:find(' ',4)
			local target = tonumber(words:sub(4,s))
			if target then
				if player(target,'exists') then
					local speed = s and tonumber(words:sub(s+1,words:find(' ',s+1))) or nil
					if speed then
						parse('speedmod '..target..' '..speed)
						return 1
					end
				end
			end
			msg2(id,'Speed modifier: "!s <targetid> <speedmod, between -100 and 100>"')
			return 1
		elseif command =='t' then
			local target = tonumber(words:sub(3))
			if target then
				if player(target,'exists') then
					if target == id then
						msg2(id,'You may not teleport to yourself!')
					end
					parse('setpos '..id..' '..player(target,'x')..' '..player(target,'y'))
					return 1
				end
			end
			msg2(id,'Teleport to player: "!t <targetid>"')
			return 1
		elseif command =='u' then
			local delay = tonumber(words:sub(3)) or 0
			shutdown(delay*1000)
			return 1
		elseif command =='v' then
			saveserver()
			msg2(id,'Saved server!')
			return 1
		end
	end
end