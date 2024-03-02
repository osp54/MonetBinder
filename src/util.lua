local util = {}

function util.isEmpty(str)
	return str == nil or str == ""
end

function util.merge(...)
	local mergedTable = {}
	local args = { ... }
	for _, tbl in ipairs(args) do
		for k, v in pairs(tbl) do
			if type(v) == "table" and type(mergedTable[k]) == "table" then
				mergedTable[k] = util.merge(mergedTable[k], v)
			else
				mergedTable[k] = v
			end
		end
	end
	return mergedTable
end

function util.deepcopy(o, seen)
	seen = seen or {}
	if o == nil then
		return nil
	end
	if seen[o] then
		return seen[o]
	end

	local no
	if type(o) == "table" then
		no = {}
		seen[o] = no

		for k, v in next, o, nil do
			no[util.deepcopy(k, seen)] = util.deepcopy(v, seen)
		end
		setmetatable(no, util.deepcopy(getmetatable(o), seen))
	else -- number, string, boolean, etc
		no = o
	end
	return no
end

if MONET_VERSION then
	local ffi = require('ffi')
	local gta = ffi.load('GTASA')
	ffi.cdef[[
		void _Z12AND_OpenLinkPKc(const char* link);
	]]
end

function util.openLink(link)
	if MONET_VERSION then
    	gta._Z12AND_OpenLinkPKc(link)
	else
		os.execute("explorer " .. link)
	end
end

function util.find_in_tables(key, ...)
	for _, tbl in ipairs({ ... }) do
		if tbl[key] ~= nil then
			return tbl[key]
		end
	end
	return nil
end

function util.invertTbl(tbl)
	local inverted = {}
	for k, v in pairs(tbl) do
		inverted[v] = k
	end
	return inverted
end

function util.getNearestPedByPed(hndlPed, radius)
	minDist, closestHandle = nil, nil
	if doesCharExist(hndlPed) then -- проверяем, существует ли Handle
		local tX, tY, tZ = getCharCoordinates(hndlPed)
		for k, v in ipairs(getAllChars()) do
			if v ~= hndlPed then
				local x, y, z = getCharCoordinates(v)
				local dist = getDistanceBetweenCoords3d(x, y, z, tX, tY, tZ)
				if (not radius or dist < radius) and (not minDist or dist < minDist) then
					minDist, closestHandle = dist, v
				end
			end
		end
		return closestHandle
	end
end

function util.GetNearestCarByPed(HndlPed, radius, minPlayerNear)
    if doesCharExist(HndlPed) then -- проверяем, существует ли Handle
        local tableArr = {}
        local countPlayers = 0
        local posXpl, posYpl = getCharCoordinates(HndlPed)
        for _,car in pairs(getAllVehicles()) do -- перебираем все Handle машин в зоне стрима
            if getDriverOfCar(car) ~= HndlPed then -- проверяем не является ли водителем этой машины HndlPed
                local posX, posY, posZ = getCarCoordinates(car) -- получаем координаты машины
                for _,player in pairs(getAllChars()) do
                    if player ~= HndlPed then
                        local playerid = select(2, sampGetPlayerIdByCharHandle(player)) -- получаем ID игрока
                        if playerid and not sampIsPlayerNpc(playerid) and playerid ~= -1 then -- проверяем не NPC ли этот игрок
                            local x,y,z = getCharCoordinates(player)
                            if getDistanceBetweenCoords2d(x, y, posX, posY) < 3 then countPlayers = countPlayers + 1 end
                        end
                    end
                end
                local distBetween2d = getDistanceBetweenCoords2d(posXpl, posYpl, posX, posY)
                if minPlayerNear ~= false then
                    if tonumber(minPlayerNear) >= countPlayers then
                        table.insert(tableArr, {distBetween2d, car, posX, posY, posZ, countPlayers})
                    end
                else table.insert(tableArr, {distBetween2d, car, posX, posY, posZ, countPlayers}) end
                countPlayers = 0
            end
        end
        if #tableArr > 0 then -- если в таблице есть данные, то...
            table.sort(tableArr, function(a, b) return (a[1] < b[1]) end) -- сортируем 1-ое значение в каждом массиве от меньшего к большому.
            if radius ~= false then -- если функция проверки на радиус включена, то..
                if tableArr[1][1] <= tonumber(radius) then  -- если дистанция меньше или равна заданному радиусу, то ..
                    return true, tableArr[1][2], tableArr[1][1], tableArr[1][3], tableArr[1][4], tableArr[1][5], tableArr[1][6] -- возвращаем значения
                end
            else return true, tableArr[1][2], tableArr[1][1], tableArr[1][3], tableArr[1][4], tableArr[1][5], tableArr[1][6] end -- иначе, возвращаем данные
        end
    end
    return false
end

function util.TranslateNick(name)
	if name:match("%a+") then
		for k, v in pairs({
			["ph"] = "ф",
			["Ph"] = "Ф",
			["Ch"] = "Ч",
			["ch"] = "ч",
			["Th"] = "Т",
			["th"] = "т",
			["Sh"] = "Ш",
			["sh"] = "ш",
			["ea"] = "и",
			["Ae"] = "Э",
			["ae"] = "э",
			["size"] = "сайз",
			["Jj"] = "Джейджей",
			["Whi"] = "Вай",
			["lack"] = "лэк",
			["whi"] = "вай",
			["Ck"] = "К",
			["ck"] = "к",
			["Kh"] = "Х",
			["kh"] = "х",
			["hn"] = "н",
			["Hen"] = "Ген",
			["Zh"] = "Ж",
			["zh"] = "ж",
			["Yu"] = "Ю",
			["yu"] = "ю",
			["Yo"] = "Ё",
			["yo"] = "ё",
			["Cz"] = "Ц",
			["cz"] = "ц",
			["ia"] = "я",
			["ea"] = "и",
			["Ya"] = "Я",
			["ya"] = "я",
			["ove"] = "ав",
			["ay"] = "эй",
			["rise"] = "райз",
			["oo"] = "у",
			["Oo"] = "У",
			["Ee"] = "И",
			["ee"] = "и",
			["Un"] = "Ан",
			["un"] = "ан",
			["Ci"] = "Ци",
			["ci"] = "ци",
			["yse"] = "уз",
			["cate"] = "кейт",
			["eow"] = "яу",
			["rown"] = "раун",
			["yev"] = "уев",
			["Babe"] = "Бэйби",
			["Jason"] = "Джейсон",
			["liy"] = "лий",
			["ane"] = "ейн",
			["ame"] = "ейм",
		}) do
			name = name:gsub(k, v)
		end
		for k, v in pairs({
			["B"] = "Б",
			["Z"] = "З",
			["T"] = "Т",
			["Y"] = "Й",
			["P"] = "П",
			["J"] = "Дж",
			["X"] = "Кс",
			["G"] = "Г",
			["V"] = "В",
			["H"] = "Х",
			["N"] = "Н",
			["E"] = "Е",
			["I"] = "И",
			["D"] = "Д",
			["O"] = "О",
			["K"] = "К",
			["F"] = "Ф",
			["y`"] = "ы",
			["e`"] = "э",
			["A"] = "А",
			["C"] = "К",
			["L"] = "Л",
			["M"] = "М",
			["W"] = "В",
			["Q"] = "К",
			["U"] = "А",
			["R"] = "Р",
			["S"] = "С",
			["zm"] = "зьм",
			["h"] = "х",
			["q"] = "к",
			["y"] = "и",
			["a"] = "а",
			["w"] = "в",
			["b"] = "б",
			["v"] = "в",
			["g"] = "г",
			["d"] = "д",
			["e"] = "е",
			["z"] = "з",
			["i"] = "и",
			["j"] = "ж",
			["k"] = "к",
			["l"] = "л",
			["m"] = "м",
			["n"] = "н",
			["o"] = "о",
			["p"] = "п",
			["r"] = "р",
			["s"] = "с",
			["t"] = "т",
			["u"] = "у",
			["f"] = "ф",
			["x"] = "x",
			["c"] = "к",
			["``"] = "ъ",
			["`"] = "ь",
			["_"] = " ",
		}) do
			name = name:gsub(k, v)
		end
		return name
	end
	return name
end

function util.tblContainsFieldValue(tbl, field, value)
	for k, v in pairs(tbl) do
		if v[field] == value then
			return true
		end
	end
	return false
end


util.arzcars = {
	--[ID CAR] = 'NAME CAR'
	--STANDART CAR
	[400] = "Landstalker",
	[401] = "Bravura",
	[402] = "Buffalo",
	[403] = "Linerunner",
	[404] = "Perenniel",
	[405] = "Sentinel",
	[406] = "Dumper",
	[407] = "Firetruck",
	[408] = "Trashmaster",
	[409] = "Stretch",
	[410] = "Manana",
	[411] = "Infernus",
	[412] = "Voodoo",
	[413] = "Pony",
	[414] = "Mule",
	[415] = "Cheetah",
	[416] = "Ambulance",
	[417] = "Leviathan",
	[418] = "Moonbeam",
	[419] = "Esperanto",
	[420] = "Taxi",
	[421] = "Washington",
	[422] = "Bobcat",
	[423] = "Mr Whoopee",
	[424] = "BF Injection",
	[425] = "Hunter",
	[426] = "Premier",
	[427] = "Enforcer",
	[428] = "Securicar",
	[429] = "Banshee",
	[430] = "Predator",
	[431] = "Bus",
	[432] = "Rhino",
	[433] = "Barracks",
	[434] = "Hotknife",
	[435] = "Article Trailer",
	[436] = "Previon",
	[437] = "Coach",
	[438] = "Cabbie",
	[439] = "Stallion",
	[440] = "Rumpo",
	[441] = "RC Bandit",
	[442] = "Romero",
	[443] = "Packer",
	[444] = "Monster",
	[445] = "Admiral",
	[446] = "Squallo",
	[447] = "Seasparrow",
	[448] = "Pizzaboy",
	[449] = "Tram",
	[450] = "Article Trailer 2",
	[451] = "Turismo",
	[452] = "Speeder",
	[453] = "Reefer",
	[454] = "Tropic",
	[455] = "Flatbed",
	[456] = "Yankee",
	[457] = "Caddy",
	[458] = "Solair",
	[459] = "Berkley's RC",
	[460] = "Skimmer",
	[461] = "PCJ-600",
	[462] = "Faggio",
	[463] = "Freeway",
	[464] = "RC Baron",
	[465] = "RC Raider",
	[466] = "Glendale",
	[467] = "Oceanic",
	[468] = "Sanchez",
	[469] = "Sparrow",
	[470] = "Patriot",
	[471] = "Quad",
	[472] = "Coastguard",
	[473] = "Dinghy",
	[474] = "Hermes",
	[475] = "Sabre",
	[476] = "Rustler",
	[477] = "ZR-350",
	[478] = "Walton",
	[479] = "Regina",
	[480] = "Comet",
	[481] = "BMX",
	[482] = "Burrito",
	[483] = "Camper",
	[484] = "Marquis",
	[485] = "Baggage",
	[486] = "Dozer",
	[487] = "Maverick",
	[488] = "SAN News Maverick",
	[489] = "Rancher",
	[490] = "FBI Rancher",
	[491] = "Virgo",
	[492] = "Greenwood",
	[493] = "Jetmax",
	[494] = "Hotring Racer",
	[495] = "Sandking",
	[496] = "Blista Compact",
	[497] = "Police Maverick",
	[498] = "Boxville",
	[499] = "Benson",
	[500] = "Mesa",
	[501] = "RC Goblin",
	[502] = "Hotring Racer A",
	[503] = "Hotring Racer B",
	[504] = "Bloodring Banger",
	[505] = "Rancher",
	[506] = "Super GT",
	[507] = "Elegant",
	[508] = "Journey",
	[509] = "Bike",
	[510] = "Mountain Bike",
	[511] = "Beagle",
	[512] = "Cropduster",
	[513] = "Stuntplane",
	[514] = "Tanker",
	[515] = "Roadtrain",
	[516] = "Nebula",
	[517] = "Majestic",
	[518] = "Buccaneer",
	[519] = "Shamal",
	[520] = "Hydra",
	[521] = "FCR-900",
	[522] = "NRG-500",
	[523] = "HPV1000",
	[524] = "Cement Truck",
	[525] = "Towtruck",
	[526] = "Fortune",
	[527] = "Cadrona",
	[528] = "FBI Truck",
	[529] = "Willard",
	[530] = "Forklift",
	[531] = "Tractor",
	[532] = "Combine Harvester",
	[533] = "Feltzer",
	[534] = "Remington",
	[535] = "Slamvan",
	[536] = "Blade",
	[537] = "Freight (Train)",
	[538] = "Brownstreak (Train)",
	[539] = "Vortex",
	[540] = "Vincent",
	[541] = "Bullet",
	[542] = "Clover",
	[543] = "Sadler",
	[544] = "Firetruck LA",
	[545] = "Hustler",
	[546] = "Intruder",
	[547] = "Primo",
	[548] = "Cargobob",
	[549] = "Tampa",
	[550] = "Sunrise",
	[551] = "Merit",
	[552] = "Utility Van",
	[553] = "Nevada",
	[554] = "Yosemite",
	[555] = "Windsor",
	[556] = "Monster A",
	[557] = "Monster B",
	[558] = "Uranus",
	[559] = "Jester",
	[560] = "Sultan",
	[561] = "Stratum",
	[562] = "Elegy",
	[563] = "Raindance",
	[564] = "RC Tiger",
	[565] = "Flash",
	[566] = "Tahoma",
	[567] = "Savanna",
	[568] = "Bandito",
	[569] = "Freight Flat Trailer",
	[570] = "Streak Trailer",
	[571] = "Kart",
	[572] = "Mower",
	[573] = "Dune",
	[574] = "Sweeper",
	[575] = "Broadway",
	[576] = "Tornado",
	[577] = "AT400",
	[578] = "DFT-30",
	[579] = "Huntley",
	[580] = "Stafford",
	[581] = "BF-400",
	[582] = "Newsvan",
	[583] = "Tug",
	[584] = "Petrol Trailer",
	[585] = "Emperor",
	[586] = "Wayfarer",
	[587] = "Euros",
	[588] = "Hotdog",
	[589] = "Club",
	[590] = "Freight Box Trailer",
	[591] = "Article Trailer 3",
	[592] = "Andromada",
	[593] = "Dodo",
	[594] = "RC Cam",
	[595] = "Launch",
	[596] = "Police Car (LSPD)",
	[597] = "Police Car (SFPD)",
	[598] = "Police Car (LVPD)",
	[599] = "Police Ranger",
	[600] = "Picador",
	[601] = "S.W.A.T.",
	[602] = "Alpha",
	[603] = "Phoenix",
	[604] = "Glendale Shit",
	[605] = "Sadler Shit",
	[606] = "Baggage Trailer A",
	[607] = "Baggage Trailer B",
	[608] = "Tug Stairs Trailer",
	[609] = "Boxville",
	[610] = "Farm Trailer",
	[611] = "Utility Trailer",
	--CUSTOM CARS (ARIZONA)
	[612] = "Ferrari 612 Scaglietti GTS",
	[613] = "Mercedes-Benz G63 AMG",
	[614] = "Audi RS6",
	[662] = "BMW X5",
	[663] = "Chevrolet Corvette",
	[665] = "Chevrolet Cruze",
	[666] = "Lexus LX",
	[667] = "Porsche 911",
	[668] = "Porsche Cayenne",
	[699] = "Bentley Continental GT",
	[793] = "BMW M8",
	[794] = "Mercedes-Benz E63 AMG",
	[909] = "Mercedes-Benz S63 AMG",
	[965] = "Volkswagen Touareg",
	[1194] = "Lamborghini Urus",
	[1195] = "Audi R8",
	[1196] = "Dodge Challenger",
	[1197] = "Acura NSX",
	[1198] = "Volvo V60",
	[1199] = "Range Rover",
	[1200] = "Honda Civic Type R",
	[1201] = "Lexus IS",
	[1202] = "Ford Mustang",
	[1203] = "Volvo XC90",
	[1204] = "Jaguar F-PACE",
	[1205] = "Kia Optima",
	[3155] = "BMW Z4",
	[3156] = "Lamborghini Aventador SVJ",
	[3157] = "BMW X5 M",
	[3158] = "Nissan GT-R R34",
	[3194] = "Ducati Diavel",
	[3195] = "Ducati Monster",
	[3196] = "Ducati Monster Naked",
	[3197] = "Kawasaki Ninja ZX-10RR",
	[3198] = "Kawasaki W800",
	[3199] = "BMW S1000RR",
	[3200] = "Volkswagen Beetle",
	[3201] = "Bugatti Divo",
	[3202] = "Bugatti Chiron",
	[3203] = "Fiat 500",
	[3204] = "Mercedes-Benz GLS 2020",
	[3205] = "Huntley S",
	[3206] = "Lamborghini Sesto Elemento",
	[3207] = "Land Rover Range Rover Sport",
	[3208] = "BMW 530i",
	[3209] = "Mercedes-Benz S-Class (W221)",
	[3210] = "Tesla Model X",
	[3211] = "Nissan Leaf",
	[3212] = "Nissan Silvia",
	[3213] = "Bravado Banshee 900R",
	[3215] = "Benefactor Schafter V12 (Armored)",
	[3216] = "Hyundai Sonata",
	[3217] = "BMW 7 Series (E38)",
	[3218] = "Mercedes-Benz E55 AMG",
	[3219] = "Mercedes-Benz 500E",
	[3220] = "Dewbauchee Rapid GT",
	[3222] = "Pegassi Tempesta",
	[3223] = "Lexus RX",
	[3224] = "Truffade Nero Custom",
	[3232] = "Infiniti Q50",
	[3233] = "Lexus RX 350",
	[3234] = "Kia Sportage",
	[3235] = "Volkswagen Golf GTI",
	[3236] = "Audi R8 Coupe V10 plus",
	[3237] = "Toyota Camry",
	[3238] = "Toyota Camry",
	[3239] = "BMW M5 E60",
	[3240] = "BMW M5 F90",
	[3245] = "Maybach",
	[3247] = "Mercedes-Benz AMG GT",
	[3248] = "Porsche Panamera",
	[3251] = "Volkswagen Passat",
	[3254] = "Chevrolet Corvette 1980",
	[3266] = "Dodge SRT",
	[3348] = "Ford Mustang Shelby GT500",
	[3974] = "Aston Martin DB5",
	[4542] = "BMW M3 GTR",
	[4543] = "Chevrolet Camaro SS",
	[4544] = "Mazda RX-7",
	[4545] = "Mazda RX-8",
	[4546] = "Mitsubishi Eclipse",
	[4547] = "Ford Mustang old",
	[4548] = "Nissan 350Z",
	[4774] = "BMW 760Li",
	[4775] = "Aston Martin One-77",
	[4776] = "Bentley Bacalar",
	[4777] = "Bentley Bentayga",
	[4778] = "BMW M4 Competition",
	[4779] = "BMW i8",
	[4780] = "Koenigsegg CCXR Trevita",
	[4781] = "Integrity IH 35",
	[4782] = "BMW M3 G20",
	[4783] = "Mercedes-Benz S500 W223",
	[4784] = "Rimac C_Two",
	[4785] = "Ferrari J50",
	[4786] = "Mercedes-Benz SLR McLaren",
	[4787] = "Subaru BRZ",
	[4788] = "Subaru Crosstrek",
	[4789] = "Porsche Taycan",
	[4790] = "Tesla Roadster",
	[4791] = "UAZ Patriot",
	[4792] = "GAZ Volga",
	[4793] = "Mercedes-Benz X-Class",
	[4794] = "Jaguar XFR-R 2012",
	[4795] = "Rolls-Royce Shuttle",
	[4796] = "Dodge Viper",
	[4797] = "Chrysler Crossfire SRT6",
	[4798] = "Ford Expedition",
	[4799] = "Ford F-150",
	[4800] = "DeLorean DMC-12",
	[4801] = "Speedophile Seashark",
	[4802] = "Grotti Cheetah Classic",
	[4803] = "Ferrari FXX K",
	[6604] = "Audi A6",
	[6605] = "Audi Q7",
	[6606] = "BMW M6",
	[6607] = "BMW M6",
	[6608] = "Mercedes-Benz CLA 45 AMG",
	[6609] = "Mercedes-Benz CLS",
	[6610] = "Haval H2",
	[6611] = "Toyota Land Cruiser 200",
	[6612] = "Lincoln Continental",
	[6613] = "Porsche Macan",
	[6614] = "Daewoo Matiz",
	[6615] = "Mercedes-Benz G63 AMG 6x6",
	[6616] = "Mercedes-Benz E63 AMG",
	[6617] = "Monster Truck 1",
	[6618] = "Monster Truck 2",
	[6619] = "Monster Truck 3",
	[6620] = "Monster Truck 4",
	[6621] = "Toyota Land Cruiser Prado",
	[6622] = "Toyota RAV4",
	[6623] = "Toyota Supra MK4",
	[6624] = "UAZ 469",
	[6625] = "Volvo XC90",
	[12713] = "Mercedes-Benz SLS AMG GT3",
	[12714] = "Renault Laguna",
	[12715] = "Mercedes-Benz CLS 63 AMG",
	[12716] = "Audi RS5",
	[12717] = "Cadillac Escalade ESV",
	[12718] = "Tesla Cybertruck",
	[12719] = "Tesla Model C",
	[12720] = "Ford GT",
	[12721] = "Dodge Viper",
	[12722] = "Volkswagen Polo",
	[12723] = "Mitsubishi Lancer Evolution X",
	[12724] = "Audi TT RS",
	[12725] = "Mercedes-Benz Actros",
	[12726] = "Holden Commodore (VF) SSV Redline",
	[12727] = "BMW 435i",
	[12728] = "Cadillac Escalade GMT900",
	[12729] = "Toyota Chaser Tourer V",
	[12730] = "Dacia Duster",
	[12731] = "Mitsubishi Lancer Evolution X",
	[12732] = "Chevrolet Impala 1964",
	[12733] = "Chevrolet Impala 1967",
	[12734] = "Kenworth T680",
	[12735] = "Kenworth W900L",
	[12736] = "McLaren MP4-12C",
	[12737] = "Ford Mustang Mach 1",
	[12738] = "Rolls-Royce Phantom",
	[12739] = "Chevrolet Silverado Pickup",
	[12740] = "Volvo VNL 780",
	[12741] = "Subaru Impreza WRX STI",
	[12742] = "Sherp ATV",
	[12743] = "ZIL-130",
	[14119] = "Audi A6 Avant",
	[14120] = "Dodge Challenger SRT Demon",
	[14121] = "Kia Stinger GT",
	[14122] = "Lada Priora",
	[14123] = "Toyota RAV4 2016",
	[14124] = "Nissan GT-R Nismo",
	[14767] = "Aston Martin One-77",
	[14768] = "Aston Martin Valkyrie",
	[14769] = "Chevrolet Aveo",
	[14857] = "Volkswagen Buggy",
	[14884] = "Volkswagen Buggy",
	[14899] = "Dacia Duster",
	[14904] = "Chevrolet Monza",
	[14905] = "Mercedes-Benz G63 AMG 6x6",
	[14906] = "Hot Wheels Twin Mill",
	[14907] = "Hummer HX Concept",
	[14908] = "Ferrari LaFerrari",
	[14909] = "BMW M5 Competition",
	[14910] = "Lada Priora",
	[14911] = "QuaDra Q2",
	[14912] = "Mercedes-Benz GLE 450 AMG Coupe",
	[14913] = "Vision GT",
	[14914] = "Mountain Bike",
	[14915] = "Mountain Bike 2",
	[14916] = "MTB",
	[14917] = "Scorcher",
	[14918] = "Bus",
	[14919] = "Bus 2",
	[15085] = "Dodge Charger SRT Hellcat",
	[15098] = "BMW M1",
	[15099] = "Lamborghini Countach",
	[15100] = "Nagasaki Carbon RS",
	[15101] = "Koenigsegg Gemera",
	[15102] = "Kia K7",
	[15103] = "Grotti Toro",
	[15104] = "Lexus LX 600",
	[15105] = "Nissan Qashqai",
	[15106] = "Grotti Itali RSX",
	[15107] = "Volkswagen Scirocco",
	[15108] = "Benefactor Schlagen GT",
	[15109] = "Toyota GR Yaris",
	[15110] = "Wellcraft Scarab",
	[15111] = "Pegassi Yacht",
	[15112] = "Speedophile Seashark",
	[15113] = "Mercedes-AMG A 45",
	[15114] = "Toyota AE86",
	[15115] = "Land Rover Defender",
	[15116] = "Dewbauchee Vagner",
	[15117] = "Mazda 6",
	[15118] = "Audi R8 Spyder",
	[15119] = "Hyundai Santa Fe",
	[15295] = "Range Rover Velar",
	[15326] = "Mercedes-Benz Actros 1620",
	[15327] = "Topfun Van",
	[15328] = "Mule",
	[15329] = "Luxor Deluxe",
	[15330] = "Nimbus",
	[15331] = "Vestra",
	[15332] = "Mercedes-Benz Arocs",
	[15333] = "Iveco Stralis",
	[15334] = "MAN TGS",
	[15335] = "Volvo FH16",
	[15416] = "Ambulance",
	[15417] = "Banshee",
	[15418] = "Benson",
	[15419] = "Bloodring Banger",
	[15420] = "Coach",
	[15421] = "Cabbie",
	[15422] = "Police Car (VCPD)",
	[15423] = "Deluxo",
	[15424] = "FBI Rancher",
	[15425] = "Flatbed",
	[15426] = "Idaho",
	[15427] = "Infernus",
	[15428] = "Love Fist",
	[15429] = "Patriot",
	[15430] = "Pizza Boy",
	[15431] = "Securicar",
	[15432] = "Sentinel",
	[15433] = "Stinger",
	[15434] = "Stretch",
	[15435] = "Taxi",
	[15436] = "Trashmaster",
	[15485] = "Angel",
	[15486] = "BF Injection",
	[15487] = "Blista Compact",
	[15488] = "Burrito",
	[15489] = "Police Car(VCPD)",
	[15490] = "Hotring Racer",
	[15491] = "Sabre",
	[15492] = "Sanchez",
	[15493] = "Ambulance",
	[15494] = "Tesla Model S",
	[15495] = "BMW iX",
	[15496] = "Mercedes-Benz EQC",
	[15497] = "Audi e-tron",
	[15498] = "Jaguar I-PACE",
	[15499] = "Polestar 2",
	[15500] = "Polestar 2",
	[15501] = "Renault Twizy",
	[15502] = "Polestar 1",
	[15720] = "Artega GTs",
	[15721] = "Mercedes-Benz GLE",
	[15722] = "Tesla Model 3",
	[15723] = "Lamborghini Murci?lago",
	[15724] = "Hummer H2",
	[15725] = "JMC Boarding",
	[15626] = "Mercedes-Benz G-Class G 63 AMG",
	[15627] = "BMW 7 Series",
	[15628] = "Mercedes-Benz V-Class",
	[15629] = "Mercedes-Benz C-Class",
	[15630] = "Mercedes-Benz C-Class C 63 AMG",
	[15631] = "Audi RS7 Sportback",
	[15746] = "Mazda RX-7",
	[15747] = "BMW X6",
	[15748] = "Jeep Gladiator",
	[15749] = "BMW M8",
	[15750] = "Volkswagen Touareg",
	[15751] = "Land Rover Defender",
	[15752] = "Mercedes-Benz S-Class S 63 AMG",
	[15858] = "Mercedes-Benz C-Class C 63 AMG",
	[15859] = "BMW M5 F10",
	[15860] = "BMW 3 Series E30",
	[15861] = "Volkswagen Transporter",
	[15862] = "Mercedes-Benz Vito",
	[15863] = "Opel Vivaro",
	[15882] = "Boosted Board Skateboard",
	[15883] = "Surfboard",
	[15902] = "Audi 80",
	[15903] = "Mercedes-Benz C-Class C 63 AMG Coupe",
	[15904] = "BMW 5 Series E34",
	[15905] = "Mercedes-Benz E-Class E 63 AMG Wagon",
	[15906] = "BMW X5 M F85",
	[15907] = "Lamborghini Gallardo",
	[15908] = "Mercedes-Benz GLE",
	[15909] = "BMW M8 (Old Model)",
	[15910] = "Renault Sport Formula One Team R.S.18",
}

util.VehicleColoursRussianTable = {
	[0] = "Черный",
	[1] = "Серебристый",
	[2] = "Синий",
	[3] = "Красный",
	[4] = "Темно-зеленый",
	[5] = "Фиолетовый",
	[6] = "Оранжевый",
	[7] = "Светло-синий",
	[8] = "Светло-зеленый",
	[9] = "Серый",
	[10] = "Темно-синий",
	[11] = "Серый",
	[12] = "Синий",
	[13] = "Серый",
	[14] = "Светло-серый",
	[15] = "Светло-бежевый",
	[16] = "Темно-зеленый",
	[17] = "Бордовый",
	[18] = "Темно-бордовый",
	[19] = "Коричневый",
	[20] = "Темно-синий",
	[21] = "Темно-серый",
	[22] = "Темно-бордовый",
	[23] = "Коричневый",
	[24] = "Серый",
	[25] = "Темно-серый",
	[26] = "Светло-серый",
	[27] = "Серый",
	[28] = "Темно-синий",
	[29] = "Коричневый",
	[30] = "Темно-бордовый",
	[31] = "Темно-коричневый",
	[32] = "Синий",
	[33] = "Серый",
	[34] = "Темно-серый",
	[35] = "Серый",
	[36] = "Темно-серый",
	[37] = "Серый",
	[38] = "Светло-коричневый",
	[39] = "Серый",
	[40] = "Темно-бордовый",
	[41] = "Серый",
	[42] = "Темно-бордовый",
	[43] = "Темно-коричневый",
	[44] = "Темно-зеленый",
	[45] = "Темно-бордовый",
	[46] = "Бежевый",
	[47] = "Серый",
	[48] = "Коричневый",
	[49] = "Светло-серый",
	[50] = "Серый",
	[51] = "Темно-зеленый",
	[52] = "Серый",
	[53] = "Темно-синий",
	[54] = "Темно-фиолетовый",
	[55] = "Серый",
	[56] = "Светло-коричневый",
	[57] = "Бежевый",
	[58] = "Темно-бордовый",
	[59] = "Темно-синий",
	[60] = "Светло-серый",
	[61] = "Коричневый",
	[62] = "Темно-бордовый",
	[63] = "Светло-серый",
	[64] = "Светло-бежевый",
	[65] = "Оранжевый",
	[66] = "Темно-бордовый",
	[67] = "Серый",
	[68] = "Светло-фиолетовый",
	[69] = "Бежевый",
	[70] = "Темно-бордовый",
	[71] = "Серый",
	[72] = "Темно-серый",
	[73] = "Светло-коричневый",
	[74] = "Темно-бордовый",
	[75] = "Темно-серый",
	[76] = "Светло-бежевый",
	[77] = "Бежевый",
	[78] = "Темно-бордовый",
	[79] = "Темно-фиолетовый",
	[80] = "Серый",
	[81] = "Серый",
	[82] = "Темно-бордовый",
	[83] = "Темно-серый",
	[84] = "Темно-коричневый",
	[85] = "Темно-бордовый",
	[86] = "Темно-зеленый",
	[87] = "Темно-синий",
	[88] = "Серый",
	[89] = "Светло-бежевый",
	[90] = "Светло-серый",
	[91] = "Темно-синий",
	[92] = "Серый",
	[93] = "Темно-фиолетовый",
	[94] = "Темно-синий",
	[95] = "Темно-фиолетовый",
	[96] = "Светло-серый",
	[97] = "Серый",
	[98] = "Темно-синий",
	[99] = "Светло-коричневый",
	[100] = "Темно-синий",
	[101] = "Темно-фиолетовый",
	[102] = "Бежевый",
	[103] = "Темно-синий",
	[104] = "Коричневый",
	[105] = "Серый",
	[106] = "Темно-синий",
	[107] = "Светло-бежевый",
	[108] = "Темно-синий",
	[109] = "Серый",
	[110] = "Серый",
	[111] = "Светло-серый",
	[112] = "Серый",
	[113] = "Темно-коричневый",
	[114] = "Темно-серый",
	[115] = "Темно-бордовый",
	[116] = "Темно-фиолетовый",
	[117] = "Темно-бордовый",
	[118] = "Светло-синий",
	[119] = "Серый",
	[120] = "Светло-серый",
	[121] = "Темно-бордовый",
	[122] = "Серый",
	[123] = "Темно-коричневый",
	[124] = "Темно-бордовый",
	[125] = "Темно-фиолетовый",
	[126] = "Розовый",
	[127] = "Черный",
	[128] = "Темно-зеленый",
	[129] = "Темно-бордовый",
	[130] = "Темно-синий",
	[131] = "Темно-коричневый",
	[132] = "Темно-бордовый",
	[133] = "Темно-зеленый",
	[134] = "Темно-фиолетовый",
	[135] = "Синий",
	[136] = "Фиолетовый",
	[137] = "Темно-зеленый",
	[138] = "Светло-серый",
	[139] = "Темно-синий",
	[140] = "Серый",
	[141] = "Серый",
	[142] = "Коричневый",
	[143] = "Серый",
	[144] = "Темно-синий",
	[145] = "Светло-зеленый",
	[146] = "Розовый",
	[147] = "Темно-бордовый",
	[148] = "Темно-серый",
	[149] = "Темно-коричневый",
	[150] = "Темно-бордовый",
	[151] = "Темно-зеленый",
	[152] = "Темно-синий",
	[153] = "Темно-зеленый",
	[154] = "Темно-синий",
	[155] = "Светло-серый",
	[156] = "Бежевый",
	[157] = "Серый",
	[158] = "Темно-бордовый",
	[159] = "Темно-коричневый",
	[160] = "Темно-зеленый",
	[161] = "Темно-синий",
	[162] = "Темно-синий",
	[163] = "Светло-серый",
	[164] = "Темно-фиолетовый",
	[165] = "Серый",
	[166] = "Серый",
	[167] = "Темно-синий",
	[168] = "Темно-синий",
	[169] = "Серый",
	[170] = "Серый",
	[171] = "Темно-синий",
	[172] = "Темно-зеленый",
	[173] = "Темно-коричневый",
	[174] = "Темно-синий",
	[175] = "Темно-бордовый",
	[176] = "Синий",
	[177] = "Серый",
	[178] = "Темно-синий",
	[179] = "Темно-бордовый",
	[180] = "Темно-коричневый",
	[181] = "Темно-серый",
	[182] = "Темно-бордовый",
	[183] = "Темно-коричневый",
	[184] = "Серый",
	[185] = "Серый",
	[186] = "Темно-зеленый",
	[187] = "Темно-зеленый",
	[188] = "Темно-коричневый",
	[189] = "Темно-фиолетовый",
	[190] = "Темно-синий",
	[191] = "Темно-зеленый",
	[192] = "Светло-серый",
	[193] = "Серый",
	[194] = "Темно-бордовый",
	[195] = "Темно-зеленый",
	[196] = "Серый",
	[197] = "Коричневый",
	[198] = "Темно-синий",
	[199] = "Темно-серый",
	[200] = "Серый",
	[201] = "Темно-фиолетовый",
	[202] = "Темно-коричневый",
	[203] = "Темно-фиолетовый",
	[204] = "Серый",
	[205] = "Темно-синий",
	[206] = "Темно-фиолетовый",
	[207] = "Темно-синий",
	[208] = "Темно-фиолетовый",
	[209] = "Темно-синий",
	[210] = "Темно-фиолетовый",
	[211] = "Темно-синий",
	[212] = "Темно-коричневый",
	[213] = "Серый",
	[214] = "Темно-коричневый",
	[215] = "Темно-зеленый",
	[216] = "Темно-коричневый",
	[217] = "Синий",
	[218] = "Бежевый",
	[219] = "Темно-бордовый",
	[220] = "Розовый",
	[221] = "Желтый",
	[222] = "Оранжевый",
	[223] = "Темно-синий",
	[224] = "Темно-бордовый",
	[225] = "Темно-желтый",
	[226] = "Зеленый",
	[227] = "Темно-зеленый",
	[228] = "Светло-оранжевый",
	[229] = "Зеленый",
	[230] = "Коричневый",
	[231] = "Оранжевый",
	[232] = "Розовый",
	[233] = "Светло-розовый",
	[234] = "Темно-зеленый",
	[235] = "Темно-зеленый",
	[236] = "Темно-серый",
	[237] = "Розовый",
	[238] = "Оранжевый",
	[239] = "Оранжевый",
	[240] = "Светло-голубой",
	[241] = "Светло-зеленый",
	[242] = "Бордовый",
	[243] = "Зеленый",
	[244] = "Коричневый",
	[245] = "Темно-зеленый",
	[246] = "Голубой",
	[247] = "Серый",
	[248] = "Бордовый",
	[249] = "Бордовый",
	[250] = "Белый",
	[251] = "Серый",
	[252] = "Серый",
	[253] = "Белый",
	[254] = "Светло-коричневый",
	[255] = "Темно-синий",
}

function util.inflectColorName(color)
	local endings = {
		["ый"] = "ого",
		["ий"] = "его",
		["ой"] = "ого",
		["ый"] = "ого",
		["ая"] = "ой",
		["ое"] = "ого",
		["ие"] = "их",
	}

	local lastTwoLetters = string.sub(color, -2)

	local newEnding = endings[lastTwoLetters]

	if newEnding then
		return string.sub(color, 1, -3) .. newEnding
	else
		local lastLetter = string.sub(color, -1)
		local newEnding = endings[lastLetter]

		if newEnding then
			return string.sub(color, 1, -2) .. newEnding
		else
			return color
		end
	end
end

---@class Thread
---@field runner fun(...): any
---@field thread table
---@field run fun(self, ...)
---@field listen fun(self, res: fun(any), rej: fun(err: string, stacktrace: string?))

---@param func fun(...): boolean, any
---@return Thread
function util.newThread(func)
	local effil = require("effil")
	if type(func) ~= "function" then
		error("Expected function, got " .. type(func))
	end

	local h = {
		runner = effil.thread(func),
	}

	function h:run(...)
		self.thread = self.runner(...)
	end

	---@param res? fun(any)
	---@param rej? fun(err:string, stacktrace:string?)
	---@return table
	function h:listen(res, rej)
		res = res or function() end
		rej = rej or function(err)
			print(err)
		end

		if not self.thread then
			error("Run thread first.")
		end
		lua_thread.create(function()
			while self.thread:status() == "running" do
				wait(0)
			end
			local status, err, stack = self.thread:status()
			if status == "failed" then
				rej(err, stack)
				return
			end

			local success, result = self.thread:get()
			if success then
				res(result)
			else
				rej(result)
			end
		end)
	end

	return h
end

---Скачивает асинхронно файл из URL в указанный путь
---@param url string @URL
---@param path string @Путь к файлу, в который будет сохранен скачанный файл
---@param callback? fun(type: "downloading"|"finished"|"error", pos: number, total_size?: number) @Функция, которая будет вызвана при изменении прогресса скачивания или завершении
---@param progressInterval? number @Интервал в секундах между вызовами callback, по умолчанию 0.1
function util.downloadToFile(url, path, callback, progressInterval)
	callback = callback or function() end
	progressInterval = progressInterval or 0.1

	if not MONET_VERSION then
		local dlstatus = require('moonloader').download_status
		return downloadUrlToFile(url, path, function(id, status, p1, p2)
			if status == dlstatus.STATUS_DOWNLOADINGDATA then
				callback("downloading", p1, p2)
			elseif status == dlstatus.STATUS_ENDDOWNLOADDATA then
				callback("finished", p1)
			end
		end)
	end

	local effil = require("effil")
	local progressChannel = effil.channel(0)

	local runner = effil.thread(function(url, path)
		local http = require("socket.http")
		local ltn = require("ltn12")

		local r, c, h = http.request({
			method = "HEAD",
			url = url,
		})

		if c ~= 200 then
			return false, c
		end
		local total_size = h["content-length"]

		local f = io.open(path, "wb")
		if not f then
			return false, "failed to open file"
		end
		local success, res, status_code = pcall(http.request, {
			method = "GET",
			url = url,
			sink = function(chunk, err)
				local clock = os.clock()
				if chunk and not lastProgress or (clock - lastProgress) >= progressInterval then
					progressChannel:push("downloading", f:seek("end"), total_size)
					lastProgress = os.clock()
				elseif err then
					progressChannel:push("error", err)
				end

				return ltn.sink.file(f)(chunk, err)
			end,
		})

		if not success then
			return false, res
		end

		if not res then
			return false, status_code
		end

		return true, total_size
	end)
	local thread = runner(url, path)

	local function checkStatus()
		local tstatus = thread:status()
		if tstatus == "failed" or tstatus == "completed" then
			local result, value = thread:get()

			if result then
				callback("finished", value)
			else
				callback("error", value)
			end

			return true
		end
	end

	lua_thread.create(function()
		if checkStatus() then
			return
		end

		while thread:status() == "running" do
			if progressChannel:size() > 0 then
				local type, pos, total_size = progressChannel:pop()
				callback(type, pos, total_size)
			end
			wait(0)
		end

		checkStatus()
	end)
end

return util
