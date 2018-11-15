addhook("join","EXPjoin")
function EXPjoin(id)
	if loadplayer(id) then
		print('-- loaded!')
	else
		print('-- unable to load!')
	end
	PLAYERS[id].tmp = {hp = 100, atk = 1, def = 1, spd = 0, usgn = player(id, "usgn"), equip = {}, exhaust = {}}
	for k, v in ipairs(CONFIG.SLOTS) do
		PLAYERS[id].tmp.equip[k] = {}
	end
	PLAYERS[id].name = player(id, "name")
end

addhook("leave","EXPleave")
function EXPleave(id,reason)
	if PLAYERS[id] and PLAYERS[id].tmp then
		for k, v in ipairs(PLAYERS[id].tmp.equip) do
			if v.image then freeimage(v.image) end
		end
		PLAYERS[id].tmp = nil
		saveplayer(id)
	end
	PLAYERS[id] = nil
end

addhook("name","EXPname")
function EXPname(id, oldname, newname)
	local check = newname:lower()
	if (check:find'admin' or check:find'gm') and not isAdmin(id) then
		return 1
	end
	PLAYERS[id].name = newname
	hudtxt2(id,0,player(id, 'usgn') ~= 0 and newname or "NOT LOGGED IN","255100100", 565, 407-CONFIG.PIXELS, 1)
	return
end

addhook("walkover","EXPwalkover")
function EXPwalkover(id,iid,type,ain,a,mode)
	return 1
end

addhook("movetile","EXPmovetile")
function EXPmovetile(id,x,y)
	if entity(x, y, "typename") == "Info_T" or entity(x, y, "typename") == "Info_CT" then
		return
	end
	if inarray(CONFIG.WATERTILES, tile(x, y, 'frame')) or PLAYERS[id].tmp.paralyse then
		if not (PLAYERS[id].Equipment[7] and ITEMS[PLAYERS[id].Equipment[7]].water) then
			setpos(id,PLAYERS[id].x*32+16,PLAYERS[id].y*32+16)
			return
		end
	end
	local tile = gettile(x, y)
	if tile.HOUSE then
		if not PLAYERS[id].Tutorial.house then
			message(id, "This is a house. For more information about houses, type !house", "255128000")
			PLAYERS[id].Tutorial.house = true
		end
		house = HOUSES[tile.HOUSE]
		if not house.owner then
			setpos(id, PLAYERS[id].x*32+16, PLAYERS[id].y*32+16)
			message(id, "This house has no owner. Type \"!house\" for a list of house commands.", "255255255")
			return
		elseif not (player(id, "usgn") == house.owner or inarray(house.allow, player(id, "usgn"))) then
			setpos(id, house.ent[1]*32+16, house.ent[2]*32+16)
			message(id, "You are not invited into " .. PLAYERCACHE[house.owner].name .. "'s house. Type \"!house\" for a list of house commands.", "255255255")
			return
		end
	end
	if not PLAYERS[id].Tutorial.pick then
		if GROUNDITEMS[y][x][1] then
			message(id, "You have stumbled upon something. Press the drop weapon button (default G) to pick it up.", "255128000")
		end
	end
	hudtxt2(id, CONFIG.HUDTXT.SAFE, (tile.SAFE and "SAFE") or (tile.NOMONSTERSPVP and "NO MONSTERS") or (tile.NOPVP and "NO PVP") or (tile.PVP and "DEATHMATCH") or "","255064000", 320, 200, 1)
	if not PLAYERS[id].Tutorial.safe then
		if not tile.SAFE then
			message(id, "You have left a SAFE zone. From now, you will be able to both damage and be damaged.", "255128000")
			PLAYERS[id].Tutorial.safe = true
		end
	elseif not PLAYERS[id].Tutorial.nomonsters then
		if tile.NOMONSTERS and not tile.PVP then
			message(id, "You have entered a NO MONSTERS zone. No monsters will spawn here. However, PVP is still allowed!", "255128000")
			PLAYERS[id].Tutorial.nomonsters = true
		end
	elseif not PLAYERS[id].Tutorial.nopvp then
		if tile.NOPVP then
			message(id, "You have entered a NO PVP zone. PVP is disabled here, but monsters can still spawn.", "255128000")
			PLAYERS[id].Tutorial.nopvp = true
		end
	elseif not PLAYERS[id].Tutorial.pvp then
		if tile.PVP then
			message(id, "You have entered a DEATHMATCH zone. In this area, you may fight for money. If you die here, you will drop a maximum of $100.", "255128000")
			PLAYERS[id].Tutorial.pvp = true
		end
	end
	PLAYERS[id].x, PLAYERS[id].y = x, y
end

addhook("say","EXPsay",-10)
function EXPsay(id,words)
	if PLAYERS[id].tmp.exhaust.talk then return 1 end
	PLAYERS[id].tmp.exhaust.talk = true
	timer(CONFIG.EXHAUST.TALK, "rem.talkExhaust", tostring(id))
	if words:sub(1,1) == '!' then
		command = words:sub(2):split(' ')
		local func = COMMANDS[command[1]]
		if func then
			table.remove(command,1)
			func(id,command)
		end
		return 1
	end
	if not PLAYERS[id].Tutorial.say then
		message(id, "Talking! I don't think you need a tutorial on that, but just to let you know, whatever you say can only be heard by people around you. You can yell by ending your sentence with '!'. Similarly, ", "255128000")
		message(id, "you can whisper by starting your sentence with '::'. You can colour-code your sentence, too, by prefixing with ^[0-9A-Z] e.g. \"^0Hello!\" will make you yell out Hello! in white font.", "255128000")
		PLAYERS[id].Tutorial.say = true
	end
	local picture = 'gfx/weiwen/talk.png'
	words = words:gsub('%s+', ' ')
	local radiusx, radiusy, colour, action
	if words:sub(-1) == '!' then
		words = words:upper()
		action = "yells"
		radiusx, radiusy = 1280, 960
	elseif words:sub(-1) == '?' then
		action = "asks"
		picture = 'gfx/weiwen/ask.png'
	elseif words:sub(1,2) == '::' then
		words = words:sub(3)
		action = "whispers"
		radiusx, radiusy = 48, 48
	end
	if words:find':D' or words:find'=D' or words:find':)' or words:find'=)' or words:find'%(:' or words:find'%(=' or words:find'xD' or words:find'lol' then
		picture = 'gfx/weiwen/happy.png'
	elseif words:find'>:%(' or words:find':@' or words:find'fuck' then
		picture = 'gfx/weiwen/angry.png'
	elseif words:find':%(' or words:find'=%(' or words:find'):' or words:find'):' or words:find':\'%(' or words:find':<' then
		picture = 'gfx/weiwen/sad.png'
	end
	timer(1000, "freeimage", image(picture, 0, 0, 200+id))
	local code = words:sub(1,2):lower()
	if code:sub(1,1) == '^' then
		colour = CONFIG.COLOURS[tonumber(code:sub(2,2), 36)]
		words = words:sub(3)
	end
	if player(id,"team") == 0 then
		radiusx, radiusy = 0, 0
	end
	local text = string.format("%s %s %s : %s", os.date'%X', player(id, "name"), action or "says", words)
	--text = os.date'%X' .. " " .. player(id, "name") .. " " .. (action or "says") .. " : " .. words
	radiusmsg(text, player(id, 'x'), player(id, 'y'), radiusx, radiusy, colour or 255255100)
	return 1
end

addhook("say","_EXPsay",100)
function _EXPsay(id,words)
	return 1
end

addhook("spawn","EXPspawn")
function EXPspawn(id)
	if player(id, 'usgn') == 0 then
		message(id, 'Please register a U.S.G.N. account at "http://www.usgn.de/" and make sure that you are logged in!', "255000000")
	else
		message(id, string.format(CONFIG.WELCOMEMSG, PLAYERS[id].name), "128255128")
		if PLAYERS[id].Info[1] then
			for i, v in ipairs(PLAYERS[id].Info) do
				message(id, v, "255100100")
			end
			PLAYERS[id].Info = {}
		end
	end
	if PLAYERS[id].x then
		parse("setpos " .. id .. " " .. PLAYERS[id].x*32+16 .. " " .. PLAYERS[id].y*32+16)
	else
		parse("setpos " .. id .. " " .. PLAYERS[id].Spawn[1] .. " " .. PLAYERS[id].Spawn[2])
	end
	updateHUD(id)
	hudtxt2(id,0,player(id, 'usgn') ~= 0 and PLAYERS[id].name or "NOT LOGGED IN","255100100", 565, 407-CONFIG.PIXELS, 1)
	local newitems, previtems = {}, {}
	for i, v in ipairs(CONFIG.SLOTS) do
		newitems[i] = PLAYERS[id].Equipment[i]
		previtems[i] = 0
	end
	updateEQ(id, newitems, previtems)
	sethealth(id, PLAYERS[id].HP <= 0 and 250 or PLAYERS[id].HP)
	return 'x'
end

addhook("drop","EXPdrop")
function EXPdrop(id,iid,type,ain,a,mode,x,y)
	if PLAYERS[id].tmp.exhaust.pick then
		if not PLAYERS[id].Tutorial.pickexhaust then
			if GROUNDITEMS[y][x][1] then
				message(id, "Try not to spam picking up, as there is an exhaust of 1 second per try.", "255128000")
			end
			PLAYERS[id].Tutorial.pickexhaust = true
		end
		return 1
	end
	PLAYERS[id].tmp.exhaust.pick = true
	timer(CONFIG.EXHAUST.PICK, "rem.pickExhaust", tostring(id))
	if not PLAYERS[id].Tutorial.pick then
		if GROUNDITEMS[y][x][1] then
			message(id, "You have picked up something. Press F2 to access your inventory!", "255128000")
		end
		PLAYERS[id].Tutorial.pick = true
	end
	pickitem(id)
	return 1
end

addhook("second","EXPsecond")
function EXPsecond()
	updateTime()
	for _, id in ipairs(player(0, 'table')) do
		if player(id, 'health') > 0 and PLAYERS[id] then
			setscore(id, PLAYERS[id].Level)
			setdeaths(id, id)
		end
		if PLAYERS[id] and PLAYERS[id].x then
			local tile = gettile(PLAYERS[id].x, PLAYERS[id].y)
			if tile.HEAL and ((tile.HEAL > 0 and tile.HOUSE) or (tile.HEAL < 0 and not tile.SAFE)) and PLAYERS[id].tmp.hp > PLAYERS[id].HP then
				PLAYERS[id].HP = player(id, "health") + math.min(10, tile.HEAL)
				sethealth(id, PLAYERS[id].HP)
			end
		end
	end
end

addhook("minute","EXPminute")
function EXPminute()
	MINUTES = MINUTES+1
	for i, v in ipairs(HOUSES) do
		if v.owner then
			local difftime = os.difftime(v.endtime, os.time())
			if difftime <= 0 then
				local online
				for _, id in ipairs(player(0, 'table')) do
					if player(id, 'usgn') == v.owner then
						online = id
						break
					end
				end
				if not online then
					table.insert(PLAYERCACHE[v.owner].Info, "Your house has expired. All items will be sent to your inventory.")
				else
					message(online, "Your house has expired. All items will be sent to your inventory.")
					updateHUD(online)
				end
				houseexpire(i)
			elseif difftime < 300 then
				for _, id in ipairs(player(0, 'table')) do
					if player(id, 'usgn') == v.owner then
						message(id, "Your house will expire in " .. difftime .. " seconds.")
						break
					end
				end
			end
		end
	end
	if game'sv_password' == '' and MINUTES%5 == 0 then
		saveserver()
	end
end

addhook("serveraction","EXPserveraction")
function EXPserveraction(id,action)
	if player(id, 'health') < 0 then return end
	if action == 1 then
		if not PLAYERS[id].Tutorial.inventory then
			message(id, "This is your inventory. You can equip or use items by clicking on them. You can press F3 to access your equipment.", "255128000")
			PLAYERS[id].Tutorial.inventory = true
		end
		inventory(id)
	elseif action == 2 then
		if not PLAYERS[id].Tutorial.inventory then
			message(id, "This is your equipment. You can unequip or use items by clicking on them.", "255128000")
			PLAYERS[id].Tutorial.inventory = true
		end
		equipment(id)
	elseif action == 3 then
		if PLAYERS[id].tmp.exhaust.use then
			return
		end
		PLAYERS[id].tmp.exhaust.use = true
		timer(CONFIG.EXHAUST.USE, "rem.useExhaust", tostring(id))
		local itemid = PLAYERS[id].Equipment[9]
		if itemid then
			local amount, items = itemcount(id, itemid)
			message(id, "Using " .. (amount == 0 and ("the last " .. ITEMS[itemid].name) or ("one of " .. fullname(itemid, amount+1))) .. "...@C", "000255000")
			ITEMS[itemid].func[1](id, 9, itemid, true)
			if amount > 0 then
				table.remove(PLAYERS[id].Inventory, items[1])
				PLAYERS[id].Equipment[9] = itemid
			end
		else
			message(id, "You can hold a rune and use F4 to cast it easily.", "255255255")
		end
	end
end

addhook("menu","EXPmenu")
function EXPmenu(id, title, button)
	if player(id, 'health') < 0 then return end
	if player(id, 'team') == 0 then return end
	if button == 0 then return end
	if title:sub(1,9) == "Inventory" then
		local page = #title-9
		if button == 9 then
			inventory(id, (page+1)%(math.ceil(CONFIG.MAXITEMS/5)))
		elseif button == 8 then
			inventory(id, (page-1)%(math.ceil(CONFIG.MAXITEMS/5)))
		elseif PLAYERS[id][itemid] ~= 0 then
			local itemslot = button+page*5
			local itemid = PLAYERS[id].Inventory[itemslot]
			itemactions(id, itemslot)
			return
		end
	elseif title:find "Actions" then
		local itemslot, itemid
		local equip = title:sub(1,5) == 'Equip'
		if equip then
			itemslot = #title-12
			itemid = PLAYERS[id].Equipment[itemslot]
		else
			itemslot = #title-11
			itemid = PLAYERS[id].Inventory[itemslot]
		end
		if button == 8 then
			message(id, "You see " .. fullname(itemid) .. ". " .. (ITEMS[itemid].desc or "") .. (ITEMS[itemid].level and "You need to be level " .. ITEMS[itemid].level .. " or above to equip it." or ""))
		elseif button == 9 then
			dropitem(id,itemslot,equip)
		else
			ITEMS[itemid].func[button](id,itemslot,itemid,equip)
		end
	elseif title == "Equipment" then
		itemactions(id,button,true)
	end
	return 
end

addhook("hit","EXPhit")
function EXPhit(id,source,weapon,hpdmg,apdmg)
	local HP, dmg, wpnName, name = player(id, "health")
	if hpdmg <= 0 or source == 0 then
		PLAYERS[id].HP = HP-hpdmg
		return
	end
	if type(source) == "table" then
		if gettile(PLAYERS[id].x, PLAYERS[id].y).SAFE or gettile(PLAYERS[id].x, PLAYERS[id].y).NOMONSTERS then return 1 end
		dmg =  math.ceil(math.random(10,20)*hpdmg*source.atk/PLAYERS[id].tmp.def/15)
		source, wpnName = 0, source.name
		--print(wpnName .. " deals " .. dmg .. " damage to " .. player(id, "name") .. ".")
	elseif player(source, 'health') > 0 then
		if id == source then return 1 end
		if inarray({400, 401, 402, 403, 404}, PLAYERS[source].Equipment[7]) then message(source, "You may not attack on a horse.") return 1 end
		if gettile(PLAYERS[id].x, PLAYERS[id].y).SAFE or gettile(PLAYERS[source].x, PLAYERS[source].y).SAFE or gettile(PLAYERS[id].x, PLAYERS[id].y).NOPVP or gettile(PLAYERS[source].x, PLAYERS[source].y).NOPVP then message(source, "You may not attack someone in a SAFE or PVP disabled area.") return 1 end
		if not PLAYERS[id].Tutorial.hit then
			message(id, "A player is attacking you! You can fight back by swinging your weapon at him.", "255128000")
			PLAYERS[id].Tutorial.hit = true
		end
		local atk = PLAYERS[source].tmp.atk
		local def = PLAYERS[id].tmp.def
		if weapon == 251 then
			dmg = math.ceil(2500/math.random(80,120))
			wpnName = 'rune'
		elseif weapon == 46 then
			dmg = math.ceil(500/math.random(80,120))
			wpnName = 'firewave'
		else
			local dmgMul = ((PLAYERS[id].Level+50)*atk/def)/math.random(60,140)
			dmg = math.ceil(20*dmgMul)
			wpnName = PLAYERS[source].Equipment[3] and ITEMS[PLAYERS[source].Equipment[3]].name or 'dagger'
		end
		--print(player(source, "name") .. " deals " .. dmg .. " damage to " .. player(id, "name") .. ".")
	end
	local resultHP = HP-dmg
	if resultHP > 0 then
		sethealth(id,resultHP)
		parse('effect "colorsmoke" ' .. player(id, "x") .. ' ' .. player(id, "y") .. ' 0 0 192 0 0')
	else
		parse('customkill ' .. source .. ' "' .. wpnName .. '" ' .. id)
	end
	PLAYERS[id].HP = resultHP
	return 1
end

addhook("kill","EXPkill")
function EXPkill(killer,victim,weapon,x,y)
	if gettile(player(victim, "tilex"), player(victim, "tiley")).PVP then
		return
	end
	if not player(killer, 'exists') then return end
	if not PLAYERS[killer].Tutorial.kill then
		message(killer, "You have killed a player! This is allowed, but it may create conflict between players.", "255128000")
		PLAYERS[killer].Tutorial.kill = true
	end
	local exp = PLAYERS[victim].Level+10
	addexp(killer, math.floor(exp*math.random(50,150)/100*CONFIG.EXPRATE))
end

addhook("die","EXPdie")
function EXPdie(victim,killer,weapon,x,y)
	local PVP = gettile(PLAYERS[victim].x, PLAYERS[victim].y).PVP
	if not PVP then
		if not PLAYERS[victim].Tutorial.die then
			message(victim, "You are dead. Try your best not to die, you'll drop some of your equipment and money if you do.", "255128000")
			PLAYERS[victim].Tutorial.die = true
		end
		local money = math.min(getmoney(victim), math.floor(PLAYERS[victim].Level*math.random(50,150)/10*CONFIG.PLAYERMONEYRATE))
		if money ~= 0 then
			addmoney(victim, -money)
			spawnitem(1337, player(victim, "tilex"), player(victim, "tiley"), money)
		end
		if PLAYERS[victim].Level >= 5 then
			local previtems = {}
			for i, v in ipairs(CONFIG.SLOTS) do
				if PLAYERS[victim].Equipment[i] and math.random(10000) <= CONFIG.PLAYERDROPRATE then
					dropitem(victim, i, true)
				end
			end
		end
		PLAYERS[victim].HP, PLAYERS[victim].x, PLAYERS[victim].y = 85, nil, nil
	else
		PLAYERS[victim].HP, PLAYERS[victim].x, PLAYERS[victim].y = 5, PVPZONE[PVP][3][1], PVPZONE[PVP][3][2]
		local money = getmoney(victim)
		if money ~= 0 then
			money = money >= 100 and 100 or money
			if addmoney(victim, money) then
				spawnitem(1337, player(victim, "tilex"), player(victim, "tiley"), money)
			end
		end
	end
	local x = player(victim, 'x')
	local y = player(victim, 'y')
	parse('effect "colorsmoke" ' .. x .. ' ' .. y .. ' 64 64 192 0 0')
	radiussound("weapons/c4_explode.wav", x, y)
	local newitems, previtems = {}, {}
	for i, v in ipairs(CONFIG.SLOTS) do
		previtems[i] = PLAYERS[victim].Equipment[i]
		newitems[i] = 0
	end
	updateEQ(victim, newitems, previtems)
	
end

addhook("use","EXPuse")
function EXPuse(id,event,data,x,y)
	local dir = math.floor((player(id, 'rot')+45)/90)%4
	local x, y = PLAYERS[id].x, PLAYERS[id].y
	if dir == 0 then
		y = y - 1
	elseif dir == 1 then
		x = x + 1
	elseif dir == 2 then
		y = y + 1
	else
		x = x - 1
	end
	local tile = gettile(x, y)
	if entity(x, y, "exists") and tile.HOUSE then
		local house = HOUSES[tile.HOUSE]
		local name = entity(x, y, "name")
		local door = tonumber(name:sub(name:find('_')+1))
		if not PLAYERS[id].Tutorial.door1 then
			message(id, "This door belongs to a house. The house owner can specify who is allowed to open the door.", "255128000")
			PLAYERS[id].Tutorial.door1 = true
		end
		if door then
			if (player(id, "usgn") == house.owner or inarray(house.doors[door], player(id, "usgn"))) then
				if not PLAYERS[id].Tutorial.door2 and player(id, "usgn") == house.owner then
					message(id, "To choose who is allowed to open this door, use the command !house door", "255128000")
					PLAYERS[id].Tutorial.door2 = true
				end
				parse("trigger " .. name)
			else
				message(id, "It is locked.", "255255255")
			end
		end
	end
end