-- BASIC FUNCTIONS --

--[[local _TIMER = {}
local _time = 0

addhook('ms100','TIMERms100',100)
function TIMERms100()
	_time = _time + 100
	for k, v in pairs(_TIMER) do
		if v[2] <= _time then
			v[1](unpack(v, 3))
			_TIMER[k] = nil
		end
	end
end

function addtimer(delay, func, ...)
	if type(func) == 'function' and type(delay) == 'number' then
		for i = 1, #_TIMER+1 do
			if not _TIMER[i] then
				_TIMER[i] = {func, _time+delay, ...}
				return i
			end
		end
	else
		return false
	end
end

function remtimer(id)
	_TIMER[id] = nil
end]]

rem = {}
function rem.talkExhaust(id)
	PLAYERS[tonumber(id)].tmp.exhaust.talk = false
end

function rem.pickExhaust(id)
	PLAYERS[tonumber(id)].tmp.exhaust.pick = false
end

function rem.useExhaust(id)
	PLAYERS[tonumber(id)].tmp.exhaust.use = false
end

function rem.paralyse(id)
	PLAYERS[tonumber(id)].tmp.paralyse = false
end

_print = print
function print(...)
	local txt = table.concat({...}, '\t')
	return _print(type(txt) == "table" and table.tostring(txt) or tostring(txt))
end

function drawLine(x1, y1, x2, y2, tbl)
	if not (x1 and y1 and x2 and y2) then
		return false
	end
	tbl = tbl or {}
	local line = image('gfx/weiwen/1x1.png', 0, 0, tbl.mode or 1)
	local x3, y3, rot = (x1+x2)/2, (y1+y2)/2, math.deg(math.atan2(y1-y2, x1-x2))+90
	imagepos(line, x3, y3, rot)
	imagescale(line, tbl.width or 1, math.sqrt((x1-x2)^2+(y1-y2)^2))
	if tbl.color then
		imagecolor(line, tbl.color[1] or 0, tbl.color[2] or 0, tbl.color[3] or 0)
	end
	if tbl.alpha then
		imagealpha(line, tbl.alpha)
	end
	if tbl.blend then
		imageblend(line, tbl.blend)
	end
	return line
end

function laser(id)
	local x, y, rot = player(id, 'x'), player(id, 'y'), math.rad(player(id, 'rot'))
	addtimer(1000, freeimage, drawLine(x, y, x+math.sin(rot)*300, y-math.cos(rot)*300, {width = 10, color = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}, alpha = 0.5}))
	radiussound('weapons/laser.ogg', x, y)
end

function table.shuffle(tbl)
	local n = #tbl
	while n > 2 do
		local k = math.random(n)
		tbl[n], tbl[k] = tbl[k], tbl[n]
		n = n - 1
	end
	return tbl
end

function deepcopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

function table.val_to_str ( v )
	if "string" == type( v ) then
		v = string.gsub( v, "\n", "\\n" )
		if string.match( string.gsub(v, "[^'\"]", ""), '^"+$' ) then
			return "'" .. v .. "'"
		end
		return '"' .. string.gsub(v, '"', '\\"' ) .. '"'
	else
		return "table" == type( v ) and table.tostring( v ) or
			tostring( v )
	end
end

function table.key_to_str ( k )
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		return k
	else
		return "[" .. table.val_to_str( k ) .. "]"
	end
end

function table.tostring( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
		if k ~= 'tmp' then
			table.insert( result, table.val_to_str( v ) )
			done[ k ] = true
		end
	end
	for k, v in pairs( tbl ) do
		if not done[ k ] then
			table.insert( result, 
				table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
		end
	end
	return "{" .. table.concat( result, ", " ) .. "}"
end

function table.equal(tbl, tbl2)
	if type(tbl) ~= "table" and type(tbl2) ~= "table" then
		return tbl == tbl2
	end
	for k, v in pairs(tbl) do
		if v ~= tbl2[k] then
			return false
		end
	end
	return true
end

function string:split(delimiter)
	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( self, delimiter, from  )
	while delim_from do
		table.insert( result, string.sub( self, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find( self, delimiter, from  )
	end
	table.insert( result, string.sub( self, from  ) )
	return result
end

function inarea(p1, p2, p3, p4, p5, p6)
	if type(p1) == "table" then
		return p1[1] >= p2[1] and p1[1] <= p3[1] and p1[2] >= p2[2] and p1[2] <= p3[2]
	else
		return p1 >= p3 and p1 <= p5 and p2 >= p4 and p2 <= p6
	end
end

function inarray(tbl, var)
	for k, v in pairs(tbl) do
		if table.equal(v, var) then
			return true
		end
	end
	return false
end

--[[function walkable(x, y, safe, water)
	return tile(x, y, 'walkable') and (water or tile(x, y, 'frame') ~= 34) and not (safe and gettile(x, y).SAFE)
end

function dmg(dmg, id, sourcetype, victimtype, atktype)
	return _dmg(dmg, PLAYERS[id].tmp.atk, PLAYERS[id].tmp.def, PLAYERS[id].Level, sourcetype or 0, victimtype or 0, atktype)
end

function _dmg(dmg, atk, def, level, sourcetype, victimtype, atktype)
	local STAB, WR
	if atktype then
		STAB = 1
		WR = 1
	else
		STAB = (sourcetype == atktype) and 1.5 or 1
		WR = CONFIG.RESISTANCE[victimtype][atktype] or 1
	end
	return ((((level*2.5+2)*dmg*atk/def)/50)+2) * STAB * WR * math.random(85, 100)/100
end]]
-- END OF BASIC FUNCTIONS --



-- SERVER FUNCTIONS --

function saveserver()
	local file = io.open(dir .. "saves/" .. map'name' .. ".lua", 'w+') or io.tmpfile()
	
	local tmp = {}
	for y = 0, map'ysize' do
		if GROUNDITEMS[y] then
			for x = 0, map'xsize' do
				if GROUNDITEMS[y][x] and GROUNDITEMS[y][x][1] then
					tmp[y] = tmp[y] or {}
					tmp[y][x] = {}
					for j = 1, #GROUNDITEMS[y][x] do
						tmp[y][x][j] = GROUNDITEMS[y][x][j][3] and -GROUNDITEMS[y][x][j][3] or GROUNDITEMS[y][x][j][1]
					end
				end
			end
		end
	end
	file:write("-- GROUND ITEMS --\n\n")
	for k, v in pairs(tmp) do
		local text = "TMPGROUNDITEMS[" .. table.val_to_str(k) .. "] = " .. table.val_to_str(v) .. "\n"
		file:write(text)
	end
	
	local tmp = {}
	for i, v in pairs(HOUSES) do
		if v.owner then
			tmp[i] = {owner = v.owner, endtime = v.endtime, allow = v.allow, doors = v.doors}
		end
	end
	file:write("\n\n-- HOUSES --\n\n")
	for k, v in pairs(tmp) do
		local text = "TMPHOUSES[" .. table.val_to_str(k) .. "] = " .. table.val_to_str(v) .. "\n"
		file:write(text)
	end
	file:close()
	
	for _, id in ipairs(player(0, 'table')) do
		if PLAYERS[id] and PLAYERS[id].tmp then
			saveplayer(id)
		end
	end
	local file = io.open(dir .. "saves/players.lua", 'w+') or io.tmpfile()
	file:write("-- PLAYERCACHE --\n\n")
	for k, v in pairs(PLAYERCACHE) do
		local text = "PLAYERCACHE[" .. table.val_to_str(k) .. "] = " .. table.val_to_str(v) .. "\n"
		file:write(text)
	end
	
	file:write("\n\n-- GLOBAL STORAGES --\n\n")
	for k, v in pairs(GLOBAL) do
		local text = "GLOBAL[" .. table.val_to_str(k) .. "] = " .. table.val_to_str(v) .. "\n"
		file:write(text)
	end
	file:close()
end

function shutdown(delay)
	if type(delay) ~= 'string' then
		msg('©255100100Server is shutting down in ' .. math.floor(delay/1000,0.1) .. ' seconds.@C')
		timer(delay,'shutdown', '', 1)
		local pw = math.random(0,9) .. math.random(0,9) .. math.random(0,9) .. math.random(0,9)
		print("PASSWORD = " .. pw)
		parse("sv_password " .. pw)
		return true
	else
		for _, id in ipairs(player(0, 'table')) do
			parse("kick " .. id)
		end
		saveserver()
		timer(3000, "parse", "quit")
	end
end

function loadplayer(id)
	if player(id, "usgn") ~= 0 then
		if PLAYERCACHE[player(id, "usgn")] then
			PLAYERS[id] = PLAYERCACHE[player(id, "usgn")]
		else
			PLAYERS[id] = deepcopy(CONFIG.PLAYERINIT)
		end
		PLAYERCACHE[player(id, "usgn")] = PLAYERS[id]
	else
		PLAYERS[id] = deepcopy(CONFIG.PLAYERINIT)
	end
	return true
end

function saveplayer(id)
	if player(id, "usgn") and player(id, "usgn") ~= 0 then
		PLAYERCACHE[player(id, "usgn")] = PLAYERS[id]
	end
	return true
end

function updateTime(t)
	GLOBAL.TIME = t or (GLOBAL.TIME + 1)%1440
	if GLOBAL.RAIN == 0 then
		if math.random(480) == 1 then
			GLOBAL.RAIN = 1
			parse("trigger rain")
		end
	elseif GLOBAL.RAIN == 1 then
		if math.random(5) == 1 then
			GLOBAL.RAIN = 2
			parse("trigger storm")
		else
			GLOBAL.RAIN = 3
		end
	elseif GLOBAL.RAIN == 2 then
		if math.random(20) == 1 then
			GLOBAL.RAIN = 3
			parse("trigger storm")
		end
	elseif GLOBAL.RAIN == 3 then
		if math.random(20) == 1 then
			GLOBAL.RAIN = 0
			parse("trigger rain")
		end
	end
	local text = string.format("%02d:%02d", math.floor(GLOBAL.TIME/60),tostring(GLOBAL.TIME%60))
	ITEMS[3].desc = "The time is ".. text .."."
	imagealpha(SKY, math.max(
					math.abs(
					math.sin(GLOBAL.TIME/1440*math.pi+1.5)), 0.5)-0.5)
	return GLOBAL.TIME
end

function gettile(x,y)
	return TILEZONE[y][x]
end

function houseexpire(id)
	local house = HOUSES[id]
	if not house.owner then
		return false
	end
	local player = PLAYERCACHE[house.owner]
	for y = house.pos1[2], house.pos2[2] do
		for x = house.pos1[1], house.pos2[1] do
			local ground = GROUNDITEMS[y][x]
			local height = #ground
			while height > 0 do
				local item = ground[height]
				if item[1] == 1337 then
					freeimage(item[2])
					player.Money = player.Money + item[3]
					GROUNDITEMS[y][x][height] = nil
				else
					table.insert(player.Inventory, item[1])
					local tile = gettile(x, y)
					if tile.HEAL and ITEMS[item[1]].heal then
						tile.HEAL = tile.HEAL - ITEMS[item[1]].heal
						if tile.HEAL == 0 then
							tile.HEAL = nil
						end
					end
					freeimage(item[2])
					GROUNDITEMS[y][x][height] = nil
				end
				height = height - 1
			end
		end
	end
	house.owner, house.endtime, house.allow = nil, nil, {}
	for i, v in ipairs(house.doors) do
		house.doors[i] = {}
	end
end

-- END OF SERVER FUNCTIONS --



-- PLAYERS --

function radiusmsg(words, x, y, radiusx, radiusy, colour)
	print(CONFIG.PRINTCOLOURTOCONSOLE and "©" .. tostring(colour) .. words or words)
	if not (radiusx and radiusy) then radiusx, radiusy = 320, 240 end
	local x1, y1, x2, y2 = x-radiusx, y-radiusy, x+radiusx, y+radiusy
	for _, v in ipairs(player(0, 'table')) do
		if player(v, 'x') >= x1 and player(v, 'x') <= x2 and player(v, 'y') >= y1 and player(v, 'y') <= y2 then
			message(v,words, colour)
		end
	end
	return 1
end

function radiussound(sound, x, y, radiusx, radiusy)
	if not (radiusx and radiusy) then radiusx, radiusy = 320, 240 end
	local x1, y1, x2, y2 = x-radiusx, y-radiusy, x+radiusx, y+radiusy
	for _, v in ipairs(player(0, 'table')) do
		if player(v, 'x') >= x1 and player(v, 'x') <= x2 and player(v, 'y') >= y1 and player(v, 'y') <= y2 then
			parse("sv_sound2 " .. v .. " " .. sound)
		end
	end
	return 1
end

function message(id, text, colour)
	if text:sub(-2) == "@C" then
		msg2(id, (colour and "©" .. tostring(colour) or "") .. text)
	else
		text = text:gsub("\n", "¦")
		local tbl = {}
		repeat
			table.insert(tbl, text:sub(#tbl+1, math.min(#text, (#tbl+1)*90)))
			text = text:sub(#tbl*90)
		until #text == 0
		for k, v in ipairs(tbl) do
			msg2(id, (colour and "©" .. tostring(colour) or "") .. v)
		end
	end
end

function hudtxt2(id, txtid, text, colour, x, y, align)
	parse("hudtxt2 " .. id .. " " .. txtid .. " \"©" .. tostring(colour) .. text .. "\" " .. x .. " " .. y .. " " .. align)
end

function getmoney(id)
	return PLAYERS[id].Money
end

function setmoney(id, money)
	PLAYERS[id].Money = money
	updateHUD(id)
	return true
end

function addmoney(id, money)
	if money < 0 and getmoney(id)+money < 0 then
		return false
	end
	setmoney(id, getmoney(id)+money)
	return true
end

function addexp(id, exp)
	PLAYERS[id].Experience = PLAYERS[id].Experience + exp
	local prevlevel = PLAYERS[id].Level
	while PLAYERS[id].Experience >= EXPTABLE[PLAYERS[id].Level+1] do
		PLAYERS[id].Level = PLAYERS[id].Level + 1
	end
	if prevlevel ~= PLAYERS[id].Level then
		parse('effect "colorsmoke" ' .. player(id, 'x') .. ' ' .. player(id, 'y') .. ' 0 64 0 128 255')
		message(id, "You have leveled up to level " .. PLAYERS[id].Level .. "!")
		parse("sv_sound2 " .. id .. " fun/Victory_Fanfare.ogg")
	end
	updateHUD(id)
	return true
end

function updateHUD(id)
	for i, v in ipairs(CONFIG.STATS) do
		hudtxt2(id, #CONFIG.STATS+i, v, '255255255', 510, 407+(i-1)*CONFIG.PIXELS, 0)
		hudtxt2(id, i, PLAYERS[id][v], '255255000', 610, 407+(i-1)*CONFIG.PIXELS, 1)
	end
end

-- END OF PLAYERS --

-- ITEMS --

function clearinventory(id, slot)
	if slot then
		table.remove(PLAYERS[id].Inventory, slot)
	else
		PLAYERS[id].Inventory = {}
	end
	return true
end

function itemcount(id, itemid)
	local amount, items = 0, {}
	for k, v in ipairs(PLAYERS[id].Inventory) do
		if v == itemid then
			amount = amount + 1
			table.insert(items, k)
		end
	end
	return amount, items
end

function additem(id, itemid, amount, tell)
	if not ITEMS[itemid] or itemid == 0 then return false end
	amount = amount and math.floor(amount) or 1
	if amount == 1 then
		if #PLAYERS[id].Inventory < CONFIG.MAXITEMS then
			table.insert(PLAYERS[id].Inventory, itemid)
			if tell then
				message(id, "You have received " .. fullname(itemid) .. ".")
			end
			return true
		end
		return false
	else
		local added = 0
		while #PLAYERS[id].Inventory < CONFIG.MAXITEMS and added < amount do
			table.insert(PLAYERS[id].Inventory, itemid)
			added = added + 1
		end
		local remaining = amount - added
		local dropped = 0
		while dropped < remaining do
			spawnitem(itemid, PLAYERS[id].x, PLAYERS[id].y)
			dropped = dropped + 1
		end
		if tell then
			if remaining == 0 then
				message(id, "You have received " .. fullname(itemid, added) .. ".")
			else
				message(id, "You have received " .. fullname(itemid, added) .. ". " .. remaining .. " are dropped due to lack of space.")
			end
		end
		return true
	end
end

function removeitem(id, itemid, amount, tell)
	if not ITEMS[itemid] or itemid == 0 then return false end
	amount = amount and math.floor(amount) or 1
	local removed = 0
	local removed = 0
	local has, toremove = itemcount(id, itemid)
	if has >= amount then
		for k, v in ipairs(toremove) do
			if removed < amount then
				table.remove(PLAYERS[id].Inventory, v+1-k)
				removed = removed + 1
			end
			if removed == amount then
				if tell then
					message(id, "You have lost " .. fullname(itemid, amount) .. ".")
				end
				return true
			end
		end
	end
	return false
end

function destroyitem(id, itemslot, equip)
	if equip then
		PLAYERS[id].Equipment[itemslot] = nil
	else
		table.remove(PLAYERS[id].Inventory, itemslot)
	end
	return true
end

function spawnitem(itemid, x, y, amount)
	if not ITEMS[itemid] then return false end
	local ground = GROUNDITEMS[y][x]
	local tile = gettile(x, y)
	local item = {itemid}
	if itemid == 1337 then
		item[3] = amount
	else
		if ITEMS[itemid].heal then
			tile.HEAL = (tile.HEAL or 0) + ITEMS[itemid].heal
		end
	end
	ground[#ground+1] = item
	updateTileItems(x, y)
	return true
end

local MAXHEIGHT = CONFIG.MAXHEIGHT
function updateTileItems(x, y)
	local tile = GROUNDITEMS[y][x]
	if #tile ~= 0 then
		for i = 1, #tile do
			local item = tile[i]
			if item and item[2] then
				freeimage(item[2])
				item[2] = nil
			end
		end
	end
	local height = 0
	for i = #tile-MAXHEIGHT+1 > 0 and #tile-MAXHEIGHT+1 or 1, #tile do
		height = height + 1
		local item = tile[i]
		local itemid = item[1]
		local amount = item[3]
		local x = ITEMS[itemid].offsetx and x*32+16+ITEMS[itemid].offsetx or x*32+16
		local y = ITEMS[itemid].offsety and y*32+16+ITEMS[itemid].offsety or y*32+16
		local heightoffset = (height < MAXHEIGHT and height or MAXHEIGHT)*3
		if itemid == 1337 then
			--[[ alternate money
				item[2] = image("gfx/weiwen/money.png", 0, 0, i > 3 and 1 or 0)
				if amount > 9999 then
					imagecolor(item[2], 255, 255, 0)
				elseif amount > 999 then
					imagecolor(item[2], 255, 85, 0)
				elseif amount > 99 then
					imagecolor(item[2], 0, 128, 255)
				else
					imagecolor(item[2], 0, 150, 0)
				end
			]]
			item[2] = image("gfx/weiwen/rupee.png", 0, 0, height > 3 and 1 or 0)
			if amount < 5 then
				imagecolor(item[2], 64, 255, 0)
			elseif amount < 10 then
				imagecolor(item[2], 0, 64, 255)
			elseif amount < 20 then
				imagecolor(item[2], 255, 255, 0)
			elseif amount < 50 then
				imagecolor(item[2], 255, 64, 0)
			elseif amount < 100 then
				imagecolor(item[2], 200, 0, 200)
			elseif amount < 200 then
				imagecolor(item[2], 255, 128, 0)
			elseif amount < 500 then
				imagecolor(item[2], 128, 255, 128)
			elseif amount < 1000 then
				imagecolor(item[2], 128, 128, 255)
			elseif amount < 2000 then
				imagecolor(item[2], 255, 128, 128)
			elseif amount < 5000 then
				imagecolor(item[2], 64, 128, 64)
			elseif amount < 10000 then
				imagecolor(item[2], 64, 64, 128)
			elseif amount < 20000 then
				imagecolor(item[2], 128, 64, 64)
			else
				imagecolor(item[2], 192, 192, 192)
			end
			imagealpha(item[2], 0.8)
		else
			item[2] = image(ITEMS[itemid].fimage or "gfx/weiwen/circle.png", 0, 0, i > 3 and 1 or 0)
			if ITEMS[itemid].r then
				imagecolor(item[2], ITEMS[itemid].r, ITEMS[itemid].g, ITEMS[itemid].b)
			end
		end
		imagepos(item[2], x - heightoffset, y - heightoffset, ITEMS[itemid].rot or 0)
		local scalex, scaley = ITEMS[itemid].fscalex or 1, ITEMS[itemid].fscaley or 1
		local magnification = math.min(height, 10)/20+0.95
		imagescale(item[2], scalex*magnification, scaley*magnification)
	end
end

function pickitem(id)
	local ground = GROUNDITEMS[PLAYERS[id].y][PLAYERS[id].x]
	local height = #ground
	if height > 0 then
		local item = ground[height]
		if item[1] == 1337 then
			if item[2] then freeimage(item[2]) end
			addmoney(id, item[3])
			message(id, "You have picked up $" .. item[3] .. ".", "255255255")
			GROUNDITEMS[PLAYERS[id].y][PLAYERS[id].x][height] = nil
		elseif additem(id, item[1]) then
			local tile = gettile(PLAYERS[id].x, PLAYERS[id].y)
			if tile.HEAL and ITEMS[item[1]].heal then
				tile.HEAL = tile.HEAL - ITEMS[item[1]].heal
				if tile.HEAL == 0 then
					tile.HEAL = nil
				end
			end
			freeimage(item[2])
			message(id, "You have picked up " .. fullname(item[1]) .. ".", "255255255")
			GROUNDITEMS[PLAYERS[id].y][PLAYERS[id].x][height] = nil
		end
		updateTileItems(PLAYERS[id].x, PLAYERS[id].y)
	end
	return true
end

function dropitem(id, itemslot, equip)
	local removed = false
	local inv = (equip and PLAYERS[id].Equipment or PLAYERS[id].Inventory)
	if spawnitem(inv[itemslot], PLAYERS[id].x, PLAYERS[id].y) then
		message(id, "You have dropped " .. fullname(inv[itemslot]) .. ".", "255255255", "255255255")
		if equip then
			updateEQ(id, {[itemslot] = 0}, {[itemslot] = inv[itemslot]})
			inv[itemslot] = nil
		else
			table.remove(inv, itemslot)
		end
	else
		message(id, "You may not drop something here.", "255255255", "255255255")
	end
end

function fullname(itemid, amount)
	if not amount or amount == 1 then
		return ITEMS[itemid].article .. " " .. ITEMS[itemid].name
	else
		return amount .. " " .. ITEMS[itemid].plural
	end
end

function inventory(id, page)
	page = page or 0
	local text = "Inventory" .. string.rep(" ", page) .. ","
	for i = page*5+1, (page+1)*5 do
		local name
		if ITEMS[PLAYERS[id].Inventory[i]] then
			name = ITEMS[PLAYERS[id].Inventory[i]].name
		else
			name = PLAYERS[id].Inventory[i] or ""
		end
		text = text .. name .. "|" .. i .. ","
	end
	text = text .. ',,Prev Page,Next Page|Page ' .. page+1
	menu(id, text)
end

function equipment(id)
	local text = "Equipment"
	for i, v in ipairs(CONFIG.SLOTS) do
		text = text .. "," .. (ITEMS[PLAYERS[id].Equipment[i] or 0].name or ("ITEM ID " .. PLAYERS[id].Equipment[i])) .. "|" .. v
	end
	menu(id, text)
end

function itemactions(id, itemslot, equip)
	local itemid
	local text = (equip and "Equip" or "Item") .. " Actions" .. string.rep(" ", itemslot-1) .. ","
	if equip then
		itemid = PLAYERS[id].Equipment[itemslot] or 0
	else
		itemid = PLAYERS[id].Inventory[itemslot] or 0
	end
	for i, v in ipairs(ITEMS[itemid].action) do
		text = text .. v .. ","
	end
	text = text .. string.rep(",", 7-#ITEMS[itemid].action) .. "Examine,Drop"
	menu(id, text)
end

-- END OF ITEMS --



-- EQUIP --

function eat(id, itemslot, itemid, equip)
	radiusmsg(player(id,"name") .. " eats " .. ITEMS[itemid].article .. " " .. ITEMS[itemid].name .. ".", player(id,"x"), player(id,"y"), 384)
	local health = player(id, "health") + ITEMS[itemid].food()
	parse("sethealth " .. id .. " " .. health)
	PLAYERS[id].HP = health
	destroyitem(id, itemslot)
end

function explosion(x, y, size, damage, id)
	for _, m in ipairs(MONSTERS) do
		if math.sqrt((m.x-player(id,'x'))^2+(m.y-player(id,'y'))^2) <= size then
			m:damage(id, math.floor(damage*math.random(60,140)/100), 251)
		end
	end
	parse("explosion " .. x .. " " .. y .. " " .. size .. " " .. damage .. " " .. id)
end

function equip(id, itemslot, itemid, equip)
	local index = equip and "Equipment" or "Inventory"
	local previtems, newitems = {}, {}
	if equip then
		if not additem(id, itemid) then return end
		previtems[itemslot] = PLAYERS[id].Equipment[itemslot] or 0
		PLAYERS[id].Equipment[itemslot] = nil
		newitems[itemslot] = 0
	else
		if ITEMS[itemid].level and PLAYERS[id].Level < ITEMS[itemid].level then
			message(id, "You need to be level " .. ITEMS[itemid].level .. " or above to equip it.", "255255255")
			return
		end
		newitems[ITEMS[itemid].slot] = itemid
		if ITEMS[itemid].slot == 4 then
			if PLAYERS[id].Equipment[3] then
				if ITEMS[PLAYERS[id].Equipment[3]].twohand then
						if not additem(id, PLAYERS[id].Equipment[3]) then return end
						previtems[3] = PLAYERS[id].Equipment[3] or 0
						PLAYERS[id].Equipment[3] = nil
						newitems[3] = 0
				end
			end
		elseif ITEMS[itemid].slot == 3 then
			if ITEMS[itemid].twohand then
				if PLAYERS[id].Equipment[4] then
					if not additem(id, PLAYERS[id].Equipment[4]) then return end
					previtems[4] = PLAYERS[id].Equipment[4] or 0
					PLAYERS[id].Equipment[4] = nil
					newitems[4] = 0
				end
			end
		end
		destroyitem(id, itemslot)
		if PLAYERS[id].Equipment[ITEMS[itemid].slot] then
			previtems[ITEMS[itemid].slot] = PLAYERS[id].Equipment[ITEMS[itemid].slot]
			additem(id, PLAYERS[id].Equipment[ITEMS[itemid].slot])
		else
			previtems[ITEMS[itemid].slot] = 0
		end
		PLAYERS[id].Equipment[ITEMS[itemid].slot] = itemid
	end
	updateEQ(id, newitems, previtems)
end

function updateEQ(id, newitems, previtems)
	if not previtems then
		previtems = {}
	end
	if not newitems then return end
	parse("equip " .. id .. " 50;setweapon " .. id .. " 50")
	local hp, spd, atk, def = 0, 0, 0, 0
	local equip, strip = playerweapons(id), {50, 41}
	for i, v in pairs(newitems) do
		if previtems[i] then
			if PLAYERS[id].tmp.equip[i].image then
				freeimage(PLAYERS[id].tmp.equip[i].image)
				PLAYERS[id].tmp.equip[i].image = nil
			end
			if PLAYERS[id].tmp.equip[i].equip then
				parse("strip " .. id .. " " .. PLAYERS[id].tmp.equip[i].equip)
				table.insert(strip, PLAYERS[id].tmp.equip[i].equip)
				PLAYERS[id].tmp.equip[i].equip = nil
			end
			if ITEMS[previtems[i]].hp then
				hp=hp-ITEMS[previtems[i]].hp
			end
			if ITEMS[previtems[i]].speed then
				spd=spd-ITEMS[previtems[i]].speed
			end
			if ITEMS[previtems[i]].atk then
				atk=atk-ITEMS[previtems[i]].atk
			end
			if ITEMS[previtems[i]].def then
				def=def-ITEMS[previtems[i]].def
			end
		end
		if newitems[i] ~= 0 then
			if ITEMS[newitems[i]].hp then
				hp=hp+ITEMS[newitems[i]].hp
			end
			if ITEMS[newitems[i]].speed then
				spd=spd+ITEMS[newitems[i]].speed
			end
			if ITEMS[newitems[i]].atk then
				atk=atk+ITEMS[newitems[i]].atk
			end
			if ITEMS[newitems[i]].def then
				def=def+ITEMS[newitems[i]].def
			end
			if ITEMS[newitems[i]].equip then
				PLAYERS[id].tmp.equip[i].equip = ITEMS[newitems[i]].equip
				parse("equip " .. id .. " " .. ITEMS[newitems[i]].equip)
				table.insert(equip, ITEMS[newitems[i]].equip)
			end
			if ITEMS[newitems[i]].eimage then 
				if not PLAYERS[id].tmp.equip[i].image then
					PLAYERS[id].tmp.equip[i].image = image(ITEMS[newitems[i]].eimage, ITEMS[newitems[i]].static and 0 or 1, 0, (ITEMS[newitems[i]].ground and 100 or 200)+id)
					if ITEMS[newitems[i]].r then
						imagecolor(PLAYERS[id].tmp.equip[i].image, ITEMS[newitems[i]].r, ITEMS[newitems[i]].g, ITEMS[newitems[i]].b)
					end
					local scalex, scaley = ITEMS[newitems[i]].escalex or 1, ITEMS[newitems[i]].escaley or 1
					scalex = scalex * -1
					imagescale(PLAYERS[id].tmp.equip[i].image, scalex, scaley)
					if ITEMS[newitems[i]].blend then
						imageblend(PLAYERS[id].tmp.equip[i].image, ITEMS[newitems[i]].blend)
					end
				end
			end
		end
	end
	for i, v in ipairs(equip) do
		if not inarray(strip, v) then
			parse("setweapon " .. id .. " " .. v .. ";strip " .. id .. " 50")
		end
	end
	PLAYERS[id].tmp.atk = PLAYERS[id].tmp.atk+atk
	PLAYERS[id].tmp.def = PLAYERS[id].tmp.def+def
	PLAYERS[id].tmp.spd = PLAYERS[id].tmp.spd+spd
	PLAYERS[id].tmp.hp = PLAYERS[id].tmp.hp+hp
	parse("setmaxhealth " .. id .. " " .. PLAYERS[id].tmp.hp .. "; speedmod " .. id .. " " .. PLAYERS[id].tmp.spd .. "; sethealth " .. id .. " " .. player(id, "health"))
end

-- END OF EQUIP --