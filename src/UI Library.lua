--[[
	Kryptic by Exunys (Modifiye) – Tüm hakları saklı değildir.
	https://github.com/Exunys
]]

-- /////////////////////////////////
-- ///// UI KÜTÜPHANESİ (BAŞLANGIÇ)
-- /////////////////////////////////

local rgbasupported = getrawmetatable and setrawmetatable and newcclosure

local firsttabsignal

local drawing = {} do
	local services = setmetatable({}, {
		__index = function(self, key)
			if key == "InputService" then
				key = "UserInputService"
			end
			
			if not rawget(self, key) then
				local service = game:GetService(key)
				rawset(self, service, service)
	
				return service
			end
		
			return rawget(self, key)
		end
	})

	local HttpService = game:GetService("HttpService")

	local ENABLE_TRACEBACK = false

	local Signal = {}
	Signal.__index = Signal
	Signal.ClassName = "Signal"

	function Signal.isSignal(value)
		return type(value) == "table"
			and getmetatable(value) == Signal
	end

	function Signal.new()
		local self = setmetatable({}, Signal)

		self._bindableEvent = Instance.new("BindableEvent")
		self._argMap = {}
		self._source = ENABLE_TRACEBACK and debug.traceback() or ""

		self._bindableEvent.Event:Connect(function(key)
			self._argMap[key] = nil
			if (not self._bindableEvent) and (not next(self._argMap)) then
				self._argMap = nil
			end
		end)

		return self
	end

	function Signal:Fire(...)
		if not self._bindableEvent then
			warn(("Signal is already destroyed. %s"):format(self._source))
			return
		end

		local args = table.pack(...)
		local key = HttpService:GenerateGUID(false)
		self._argMap[key] = args
		self._bindableEvent:Fire(key)
	end

	function Signal:Connect(handler)
		if not (type(handler) == "function") then
			error(("connect(%s)"):format(typeof(handler)), 2)
		end

		return self._bindableEvent.Event:Connect(function(key)
			local args = self._argMap[key]
			if args then
				handler(table.unpack(args, 1, args.n))
			else
				error("Missing arg data, probably due to reentrance.")
			end
		end)
	end

	function Signal:Wait()
		local key = self._bindableEvent.Event:Wait()
		local args = self._argMap[key]
		if args then
			return table.unpack(args, 1, args.n)
		else
			error("Missing arg data, probably due to reentrance.")
			return nil
		end
	end

	function Signal:Destroy()
		if self._bindableEvent then
			self._bindableEvent:Destroy()
			self._bindableEvent = nil
		end
		setmetatable(self, nil)
	end

	local signal = Signal

	local function ismouseover(obj)
		local posX, posY = obj.Position.X, obj.Position.Y
		local sizeX, sizeY = posX + obj.Size.X, posY + obj.Size.Y
		local mousepos = services.InputService:GetMouseLocation()

		if mousepos.X >= posX and mousepos.Y >= posY and mousepos.X <= sizeX and mousepos.Y <= sizeY then
			return true
		end

		return false
	end

	local function udim2tovector2(udim2, vec2)
		local xscalevector2 = vec2.X * udim2.X.Scale
		local yscalevector2 = vec2.Y * udim2.Y.Scale
		local newvec2 = Vector2.new(xscalevector2 + udim2.X.Offset, yscalevector2 + udim2.Y.Offset)
		return newvec2
	end

	local function istouching(pos1, size1, pos2, size2)
		local top = pos2.Y - pos1.Y
		local bottom = pos2.Y + size2.Y - (pos1.Y + size1.Y)
		local left = pos2.X - pos1.X
		local right = pos2.X + size2.X - (pos1.X + size1.X)

		local touching = true
		
		if top > 0 then
			touching = false
		elseif bottom < 0 then
			touching = false
		elseif left > 0 then
			touching = false
		elseif right < 0 then
			touching = false
		end
		
		return touching
	end

	local objchildren = {}
	local objmts = {}
	local objvisibles = {}
	local mtobjs = {}
	local udim2posobjs = {}
	local udim2sizeobjs = {}
	local objpositions = {}
	local listobjs = {}
	local listcontents = {}
	local listchildren = {}
	local listadds = {}
	local objpaddings = {}
	local scrollobjs = {}
	local listindexes = {}
	local custompropertysets = {}
	local custompropertygets = {}
	local objconnections = {}
	local objmtchildren = {}
	local scrollpositions = {}
	local currentcanvasposobjs = {}
	local childrenposupdates = {}
	local childrenvisupdates = {}
	local squares = {}
	local objsignals = {}
	local objexists = {}

	local function mouseoverhighersquare(obj)
		for _, square in next, squares do
			if square.Visible == true and square.ZIndex > obj.ZIndex then
				if ismouseover(square) then
					return true
				end
			end
		end
	end

	services.InputService.InputEnded:Connect(function(input, gpe)
		for obj, signals in next, objsignals do
			if objexists[obj] then
				if signals.inputbegan[input] then
					signals.inputbegan[input] = false

					if signals.InputEnded then
						signals.InputEnded:Fire(input, gpe)
					end
				end

				if obj.Visible then
					if ismouseover(obj) then
						if input.UserInputType == Enum.UserInputType.MouseButton1 and not mouseoverhighersquare(obj) then
							if signals.MouseButton1Up then
								signals.MouseButton1Up:Fire()
							end

							if signals.mouse1down and signals.MouseButton1Click then
								signals.mouse1down = false
								signals.MouseButton1Click:Fire()
							end
						end

						if input.UserInputType == Enum.UserInputType.MouseButton2 and not mouseoverhighersquare(obj) then
							if signals.MouseButton2Clicked then
								signals.MouseButton2Clicked:Fire()
							end

							if signals.MouseButton2Up then
								signals.MouseButton2Up:Fire()
							end
						end
					end
				end
			end
		end
	end)

	services.InputService.InputChanged:Connect(function(input, gpe)
		for obj, signals in next, objsignals do
			if objexists[obj] and obj.Visible and (signals.MouseEnter or signals.MouseMove or signals.InputChanged or signals.MouseLeave) then
				if ismouseover(obj) then
					if not signals.mouseentered then
						signals.mouseentered = true

						if signals.MouseEnter then
							signals.MouseEnter:Fire(input.Position)
						end

						if signals.MouseMoved then
							signals.MouseMoved:Fire(input.Position)
						end
					end

					if signals.InputChanged then
						signals.InputChanged:Fire(input, gpe)
					end
				elseif signals.mouseentered then
					signals.mouseentered = false

					if signals.MouseLeave then
						signals.MouseLeave:Fire(input.Position)
					end
				end
			end
		end
	end)

	services.InputService.InputBegan:Connect(function(input, gpe)
		for obj, signals in next, objsignals do
			if objexists[obj] then
				if obj.Visible then
					if ismouseover(obj) and not mouseoverhighersquare(obj) then 
						signals.inputbegan[input] = true

						if signals.InputBegan then
							signals.InputBegan:Fire(input, gpe)
						end

						if input.UserInputType == Enum.UserInputType.MouseButton1 and (not mouseoverhighersquare(obj) or obj.Transparency == 0) then
							signals.mouse1down = true

							if signals.MouseButton1Down then
								signals.MouseButton1Down:Fire()
							end
						end

						if input.UserInputType == Enum.UserInputType.MouseButton2 and (not mouseoverhighersquare(obj) or obj.Transparency == 0) then
							if signals.MouseButton2Down then
								signals.MouseButton2Down:Fire()
							end
						end
					end
				end
			end
		end
	end)

	function drawing:new(shape)
		local obj = Drawing.new(shape)
		objexists[obj] = true
		obj.Visible = false
		local signalnames = {}

		local listfunc
		local scrollfunc
		local refreshscrolling

		objconnections[obj] = {}

		if shape == "Square" then
			table.insert(squares, obj)

			signalnames = {
				MouseButton1Click = signal.new(),
				MouseButton1Up = signal.new(),
				MouseButton1Down = signal.new(),
				MouseButton2Click = signal.new(),
				MouseButton2Up = signal.new(),
				MouseButton2Down = signal.new(),
				InputBegan = signal.new(),
				InputEnded = signal.new(),
				InputChanged = signal.new(),
				MouseEnter = signal.new(),
				MouseLeave = signal.new(),
				MouseMoved = signal.new()
			}

			local attemptedscrollable = false

			scrollfunc = function(self)
				if listobjs[self] then
					scrollpositions[self] = 0
					scrollobjs[self] = true

					self.ClipsDescendants = true

					local function scroll(amount)
						local totalclippedobjs, currentclippedobj, docontinue = 0, nil, false

						for i, object in next, listchildren[self] do
							if amount == 1 then
								if object.Position.Y > mtobjs[self].Position.Y then
									if not istouching(object.Position, object.Size, mtobjs[self].Position, mtobjs[self].Size) then
										if not currentclippedobj then
											currentclippedobj = object
										end

										totalclippedobjs = totalclippedobjs + 1
										docontinue = true
									end
								end
							end

							if amount == -1 then
								if object.Position.Y <= mtobjs[self].Position.Y then
									if not istouching(object.Position, object.Size, mtobjs[self].Position, mtobjs[self].Size) then
										currentclippedobj = object
										totalclippedobjs = totalclippedobjs + 1
										docontinue = true
									end
								end
							end
						end

						if docontinue then
							if amount > 0 then
								local poschange = -(currentclippedobj.Size.Y + objpaddings[self])
								local closestobj

								for i, object in next, objchildren[self] do
									if istouching(object.Position + Vector2.new(0, poschange), object.Size, mtobjs[self].Position, mtobjs[self].Size) then
										closestobj = object
										break
									end
								end

								local diff = (Vector2.new(0, mtobjs[self].Position.Y) - Vector2.new(0, (closestobj.Position.Y + poschange + objpaddings[self]))).magnitude

								if custompropertygets[mtobjs[self]]("ClipsDescendants") then
									for i, object in next, objchildren[self] do
										if not istouching(object.Position + Vector2.new(0, poschange - diff + objpaddings[self]), object.Size, mtobjs[self].Position, mtobjs[self].Size) then
											object.Visible = false
											childrenvisupdates[objmts[object]](objmts[object], false)
										else
											object.Visible = true
											childrenvisupdates[objmts[object]](objmts[object], true)
										end
									end
								end

								scrollpositions[self] = scrollpositions[self] + (poschange - diff + objpaddings[self])

								for i, object in next, objchildren[self] do
									childrenposupdates[objmts[object]](objmts[object], object.Position + Vector2.new(0, poschange - diff + objpaddings[self]))
									object.Position = object.Position + Vector2.new(0, poschange - diff + objpaddings[self])
								end
							else
								local poschange = currentclippedobj.Size.Y + objpaddings[self]

								if custompropertygets[mtobjs[self]]("ClipsDescendants") then
									for i, object in next, objchildren[self] do
										if not istouching(object.Position + Vector2.new(0, poschange), object.Size, mtobjs[self].Position, mtobjs[self].Size) then
											object.Visible = false
											childrenvisupdates[objmts[object]](objmts[object], false)
										else
											object.Visible = true
											childrenvisupdates[objmts[object]](objmts[object], true)
										end
									end
								end

								scrollpositions[self] = scrollpositions[self] + poschange

								for i, object in next, objchildren[self] do
									childrenposupdates[objmts[object]](objmts[object], object.Position + Vector2.new(0, poschange))
									object.Position = object.Position + Vector2.new(0, poschange)
								end
							end
						end

						return docontinue
					end

					refreshscrolling = function()
						repeat
						until
							not scroll(-1)
					end

					self.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseWheel then
							if input.Position.Z > 0 then
								scroll(-1)
							else
								scroll(1)
							end
						end
					end)
				else
					attemptedscrollable = true
				end
			end

			listfunc = function(self, padding)
				objpaddings[self] = padding
				listcontents[self] = 0
				listchildren[self] = {}
				listindexes[self] = {}
				listadds[self] = {}

				listobjs[self] = true

				for i, object in next, objchildren[self] do
					table.insert(listchildren[self], object)
					table.insert(listindexes[self], listcontents[self] + (#listchildren[self] == 1 and 0 or padding))

					local newpos = mtobjs[self].Position + Vector2.new(0, listcontents[self] + (#listchildren[self] == 1 and 0 or padding))
					object.Position = newpos
					
					childrenposupdates[object](objmts[object], newpos)

					custompropertysets[object]("AbsolutePosition", newpos)
					
					listadds[self][object] = object.Size.Y + (#listchildren[self] == 1 and 0 or padding)
					listcontents[self] = listcontents[self] + object.Size.Y + (#listchildren[self] == 1 and 0 or padding)
				end

				if attemptedscrollable then
					scrollfunc(self)
				end
			end
		end

		local customproperties = {
			Parent = nil,
			AbsolutePosition = nil,
			AbsoluteSize = nil,
			ClipsDescendants = false
		}

		custompropertysets[obj] = function(k, v)
			customproperties[k] = v
		end

		custompropertygets[obj] = function(k)
			return customproperties[k]
		end

		local mt = setmetatable({exists = true}, {
			__index = function(self, k)
				if k == "Parent" then
					return customproperties.Parent
				end

				if k == "Visible" then
					return objvisibles[obj]
				end

				if k == "Position" then
					return udim2posobjs[obj] or objpositions[obj] or obj[k]
				end

				if k == "Size" then
					return udim2sizeobjs[obj] or obj[k]
				end

				if k == "AddListLayout" and listfunc then
					return listfunc
				end

				if k == "MakeScrollable" and scrollfunc then
					return scrollfunc
				end

				if k == "RefreshScrolling" and refreshscrolling then
					return refreshscrolling
				end

				if k == "AbsoluteContentSize" then
					return listcontents[self]
				end

				if k == "GetChildren" then
					return function(self)
						return objmtchildren[self]
					end
				end

				if k == "Remove" then
					return function(self)
						rawset(self, "exists", false)
						objexists[obj] = false

						if customproperties.Parent and listobjs[customproperties.Parent] then
							local objindex = table.find(objchildren[customproperties.Parent], obj)

							listcontents[customproperties.Parent] = listcontents[customproperties.Parent] - listadds[customproperties.Parent][obj]
			
							for i, object in next, objchildren[customproperties.Parent] do
								if i > objindex then
									object.Position = object.Position - Vector2.new(0, listadds[customproperties.Parent][obj])
								end
							end

							if table.find(listchildren[customproperties.Parent], obj) then
								table.remove(listchildren[customproperties.Parent], table.find(listchildren[customproperties.Parent], obj))
							end

							if table.find(objchildren[customproperties.Parent], obj) then
								table.remove(objchildren[customproperties.Parent], table.find(objchildren[customproperties.Parent], obj))
								table.remove(listindexes[customproperties.Parent], table.find(objchildren[customproperties.Parent], obj))
							end
						end

						if table.find(squares, mtobjs[self]) then
							table.remove(squares, table.find(squares, mtobjs[self]))
						end
						
						for _, object in next, objchildren[self] do
							if objexists[object] then
								table.remove(objsignals, table.find(objsignals, object))
								objmts[object]:Remove()
							end
						end

						table.remove(objsignals, table.find(objsignals, obj))
						obj:Remove()
					end
				end

				if signalnames and signalnames[k] then
					objsignals[obj] = objsignals[obj] or {}
					
					if not objsignals[obj][k] then
						objsignals[obj][k] = signalnames[k]
					end

					objsignals[obj].inputbegan = objsignals[obj].inputbegan or {}
					objsignals[obj].mouseentered = objsignals[obj].mouseentered or {}
					objsignals[obj].mouse1down = objsignals[obj].mouse1down or {}

					return signalnames[k]
				end

				return customproperties[k] or obj[k]
			end,

			__newindex = function(self, k, v)
				local changechildrenvis
				changechildrenvis = function(parent, vis)
					if objchildren[parent] then
						for _, object in next, objchildren[parent] do
							if (custompropertygets[mtobjs[parent]]("ClipsDescendants") and not istouching(object.Position, object.Size, mtobjs[parent].Position, mtobjs[parent].Size)) then
								object.Visible = false
								changechildrenvis(objmts[object], false)
							else
								object.Visible = vis and objvisibles[object] or false
								changechildrenvis(objmts[object], vis and objvisibles[object] or false)
							end
						end
					end
				end

				childrenvisupdates[self] = changechildrenvis

				if k == "Visible" then
					objvisibles[obj] = v

					if customproperties.Parent and (not mtobjs[customproperties.Parent].Visible or (custompropertygets[mtobjs[customproperties.Parent]]("ClipsDescendants") and not istouching(obj.Position, obj.Size, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size))) then
						v = false
						changechildrenvis(self, v)
					else
						changechildrenvis(self, v)
					end
				end

				if k == "ClipsDescendants" then
					customproperties.ClipsDescendants = v

					for _, object in next, objchildren[self] do
						object.Visible = v and (istouching(object.Position, object.Size, obj.Position, obj.Size) and objvisibles[object] or false) or objvisibles[object]
					end

					return
				end

				local changechildrenpos
				changechildrenpos = function(parent, val)
					if objchildren[parent] then
						if listobjs[parent] then
							for i, object in next, objchildren[parent] do
								local newpos = val + Vector2.new(0, listindexes[parent][i])
		
								if scrollobjs[parent] then
									newpos = val + Vector2.new(0, listindexes[parent][i] + scrollpositions[parent])
								end

								newpos = Vector2.new(math.floor(newpos.X), math.floor(newpos.Y))

								object.Position = newpos
								custompropertysets[object]("AbsolutePosition", newpos)

								changechildrenpos(objmts[object], newpos)
							end
						else
							for _, object in next, objchildren[parent] do
								local newpos = val + objpositions[object]
								newpos = Vector2.new(math.floor(newpos.X), math.floor(newpos.Y))

								object.Position = newpos

								custompropertysets[object]("AbsolutePosition", newpos)
								
								changechildrenpos(objmts[object], newpos)
							end
						end
					end
				end

				childrenposupdates[self] = changechildrenpos

				if k == "Position" then
					if typeof(v) == "UDim2" then
						udim2posobjs[obj] = v
						
						if customproperties.Parent then
							objpositions[obj] = udim2tovector2(v, mtobjs[customproperties.Parent].Size)

							if listobjs[customproperties.Parent] then
								return
							else
								v = mtobjs[customproperties.Parent].Position + udim2tovector2(v, mtobjs[customproperties.Parent].Size)
							end
						else
							local newpos = udim2tovector2(v, workspace.CurrentCamera.ViewportSize)
							objpositions[obj] = newpos
							v = udim2tovector2(v, workspace.CurrentCamera.ViewportSize)
						end

						customproperties.AbsolutePosition = v

						if customproperties.Parent and custompropertygets[mtobjs[customproperties.Parent]]("ClipsDescendants") then
							obj.Visible = istouching(v, obj.Size, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false
							changechildrenvis(self, istouching(v, obj.Size, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false)
						end

						changechildrenpos(self, v)
					else
						objpositions[obj] = v

						if customproperties.Parent then
							if listobjs[customproperties.Parent] then
								return
							else
								v = mtobjs[customproperties.Parent].Position + v
							end
						end

						customproperties.AbsolutePosition = v

						if customproperties.Parent and custompropertygets[mtobjs[customproperties.Parent]]("ClipsDescendants") then
							obj.Visible = istouching(v, obj.Size, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false
							changechildrenvis(self, istouching(v, obj.Size, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false)
						end

						changechildrenpos(self, v)
					end

					v = v
				end

				local changechildrenudim2pos
				changechildrenudim2pos = function(parent, val)
					if objchildren[parent] and not listobjs[parent] then
						for _, object in next, objchildren[parent] do
							if udim2posobjs[object] then
								local newpos = mtobjs[parent].Position + udim2tovector2(udim2posobjs[object], val)
								newpos = Vector2.new(math.floor(newpos.X), math.floor(newpos.Y))
								
								if not listobjs[parent] then
									object.Position = newpos
								end

								custompropertysets[object]("AbsolutePosition", newpos)
								objpositions[object] = udim2tovector2(udim2posobjs[object], val)
								changechildrenpos(objmts[object], newpos)
							end
						end
					end
				end

				local changechildrenudim2size
				changechildrenudim2size = function(parent, val)
					if objchildren[parent] then
						for _, object in next, objchildren[parent] do
							if udim2sizeobjs[object] then
								local newsize = udim2tovector2(udim2sizeobjs[object], val)
								object.Size = newsize

								if custompropertygets[mtobjs[parent]]("ClipsDescendants") then
									object.Visible = istouching(object.Position, object.Size, mtobjs[parent].Position, mtobjs[parent].Size) and objvisibles[object] or false
								end

								custompropertysets[object]("AbsoluteSize", newsize)

								changechildrenudim2size(objmts[object], newsize)
								changechildrenudim2pos(objmts[object], newsize)
							end
						end
					end
				end

				if k == "Size" then
					if typeof(v) == "UDim2" then
						udim2sizeobjs[obj] = v 

						if customproperties.Parent then
							v = udim2tovector2(v, mtobjs[customproperties.Parent].Size)
						else
							v = udim2tovector2(v, workspace.CurrentCamera.ViewportSize)
						end

						if customproperties.Parent and listobjs[customproperties.Parent] then
							local oldsize = obj.Size.Y
							local sizediff = v.Y - oldsize

							local objindex = table.find(objchildren[customproperties.Parent], obj)

							listcontents[customproperties.Parent] = listcontents[customproperties.Parent] + sizediff
							listadds[customproperties.Parent][obj] = listadds[customproperties.Parent][obj] + sizediff

							for i, object in next, objchildren[customproperties.Parent] do
								if i > objindex then
									object.Position = object.Position + Vector2.new(0, sizediff)
									listindexes[customproperties.Parent][i] = listindexes[customproperties.Parent][i] + sizediff
								end
							end
						end

						customproperties.AbsoluteSize = v

						changechildrenudim2size(self, v)
						changechildrenudim2pos(self, v)

						if customproperties.ClipsDescendants then
							for _, object in next, objchildren[self] do
								object.Visible = istouching(object.Position, object.Size, obj.Position, v) and objvisibles[object] or false
							end
						end

						if customproperties.Parent and custompropertygets[mtobjs[customproperties.Parent]]("ClipsDescendants") then
							obj.Visible = istouching(obj.Position, v, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false
							changechildrenvis(self, istouching(obj.Position, v, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false)
						end
					else
						if customproperties.Parent and listobjs[customproperties.Parent] then
							local oldsize = obj.Size.Y
							local sizediff = v.Y - oldsize

							local objindex = table.find(objchildren[customproperties.Parent], obj)

							listcontents[customproperties.Parent] = listcontents[customproperties.Parent] + sizediff
							listadds[customproperties.Parent][obj] = listadds[customproperties.Parent][obj] + sizediff

							for i, object in next, objchildren[customproperties.Parent] do
								if i > objindex then
									object.Position = object.Position + Vector2.new(0, sizediff)
									listcontents[customproperties.Parent] = listcontents[customproperties.Parent] + sizediff
									listindexes[customproperties.Parent][i] = listindexes[customproperties.Parent][i] + sizediff
								end
							end
						end

						customproperties.AbsoluteSize = v

						changechildrenudim2size(self, v)
						changechildrenudim2pos(self, v)

						if customproperties.ClipsDescendants then
							for _, object in next, objchildren[self] do
								object.Visible = istouching(object.Position, object.Size, obj.Position, v) and objvisibles[object] or false
							end
						end

						if customproperties.Parent and custompropertygets[mtobjs[customproperties.Parent]]("ClipsDescendants") then
							obj.Visible = istouching(obj.Position, v, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false
							changechildrenvis(self, istouching(obj.Position, v, mtobjs[customproperties.Parent].Position, mtobjs[customproperties.Parent].Size) and objvisibles[obj] or false)
						end
					end

					if typeof(v) == "Vector2" then
						v = Vector2.new(math.floor(v.X), math.floor(v.Y))
					end
				end

				if k == "Parent" then
					assert(type(v) == "table", "Invalid type " .. type(v) .. " for parent")

					table.insert(objchildren[v], obj)
					table.insert(objmtchildren[v], self)

					changechildrenvis(v, mtobjs[v].Visible)

					if udim2sizeobjs[obj] then
						local newsize = udim2tovector2(udim2sizeobjs[obj], mtobjs[v].Size)
						obj.Size = newsize

						if custompropertygets[mtobjs[v]]("ClipsDescendants") then
							obj.Visible = istouching(obj.Position, newsize, mtobjs[v].Position, mtobjs[v].Size) and objvisibles[obj] or false
						end

						changechildrenudim2pos(self, newsize)
					end

					if listobjs[v] then
						table.insert(listchildren[v], obj)
						table.insert(listindexes[v], listcontents[v] + (#listchildren[v] == 1 and 0 or objpaddings[v]))

						local newpos = Vector2.new(0, listcontents[v] + (#listchildren[v] == 1 and 0 or objpaddings[v]))

						if scrollobjs[v] then
							newpos = Vector2.new(0, listcontents[v] + (#listchildren[v] == 1 and 0 or objpaddings[v]) + scrollpositions[v])
						end

						listadds[v][obj] = obj.Size.Y + (#listchildren[v] == 1 and 0 or objpaddings[v])

						listcontents[v] = listcontents[v] + obj.Size.Y + (#listchildren[v] == 1 and 0 or objpaddings[v])

						obj.Position = newpos

						customproperties.AbsolutePosition = newpos

						changechildrenpos(self, newpos)
					end

					if udim2posobjs[obj] then
						local newpos = mtobjs[v].Position + udim2tovector2(udim2posobjs[obj], mtobjs[v].Size)
						objpositions[obj] = udim2tovector2(udim2posobjs[obj], mtobjs[v].Size)
						obj.Position = newpos
						customproperties.AbsolutePosition = newpos

						if custompropertygets[mtobjs[v]]("ClipsDescendants") then
							obj.Visible = istouching(newpos, obj.Size, mtobjs[v].Position, mtobjs[v].Size) and objvisibles[obj] or false
						end

						changechildrenpos(self, newpos)
					elseif shape ~= "Line" and shape ~= "Quad" and shape ~= "Triangle" then
						local newpos = mtobjs[v].Position + obj.Position
						obj.Position = newpos
						customproperties.AbsolutePosition = newpos

						if custompropertygets[mtobjs[v]]("ClipsDescendants") then
							obj.Visible = istouching(newpos, obj.Size, mtobjs[v].Position, mtobjs[v].Size) and objvisibles[obj] or false
						end

						changechildrenpos(self, newpos)
					end

					if custompropertygets[mtobjs[v]]("ClipsDescendants") then
						obj.Visible = istouching(obj.Position, obj.Size, mtobjs[v].Position, mtobjs[v].Size) and objvisibles[obj] or false
					end
					
					customproperties.Parent = v
					return
				end

				obj[k] = v
			end
		})

		objmts[obj] = mt
		mtobjs[mt] = obj
		objchildren[mt] = {}
		objmtchildren[mt] = {}

		if shape ~= "Line" and shape ~= "Quad" and shape ~= "Triangle" then
			mt.Position = Vector2.new(0, 0)
		end

		mt.Visible = true

		return mt
	end
end

-- /////////////////////////////////
-- ///// UI KÜTÜPHANESİ (SON)
-- /////////////////////////////////

-- /////////////////////////////////
-- ///// ANA SCRIPT (BAŞLANGIÇ)
-- /////////////////////////////////

--[[
	Kryptic by Exunys (Modifiye) – Tüm hakları saklı değildir.
	https://github.com/Exunys
]]

--// Loaded Check

if AirHubV2Loaded or AirHubV2Loading or AirHub then
	return
end

getgenv().AirHubV2Loading = true

--// Cache

local game = game
local loadstring, typeof, select, next, pcall = loadstring, typeof, select, next, pcall
local tablefind, tablesort = table.find, table.sort
local mathfloor = math.floor
local stringgsub = string.gsub
local wait, delay, spawn = task.wait, task.delay, task.spawn
local osdate = os.date

--// Launching

loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Roblox-Functions-Library/main/Library.lua"))()

local GUI = drawing -- UI kütüphanesi global drawing değişkenini kullanıyor, main.lua'daki GUI değişkeni buna bağlanmalı.
-- Ancak yukarıda drawing tanımlandı, GUI'yi drawing'e eşitleyelim.
-- Yukarıdaki UI kütüphanesi drawing'i doldurdu, şimdi GUI = drawing yapıyoruz.
GUI = drawing

-- ESP ve Aimbot modüllerini yükle (orijinal URL'ler)
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Exunys-ESP/main/src/ESP.lua"))()
local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()

--// Variables

local MainFrame = GUI:Load({
	name = "Kryptic",   -- Menü adı değiştirildi
	sizex = 450,
	sizey = 500,
	theme = "AirHub",
	folder = "Kryptic"
})

local ESP_DeveloperSettings = ESP.DeveloperSettings
local ESP_Settings = ESP.Settings
local ESP_Properties = ESP.Properties
local Crosshair = ESP_Properties.Crosshair
local CenterDot = Crosshair.CenterDot

local Aimbot_DeveloperSettings = Aimbot.DeveloperSettings
local Aimbot_Settings = Aimbot.Settings
local Aimbot_FOV = Aimbot.FOVSettings

ESP_Settings.LoadConfigOnLaunch = false
ESP_Settings.Enabled = false
Crosshair.Enabled = false
Aimbot_Settings.Enabled = false

local Fonts = {"UI", "System", "Plex", "Monospace"}
local TracerPositions = {"Bottom", "Center", "Mouse"}
local HealthBarPositions = {"Top", "Bottom", "Left", "Right"}

--// Kar Taneleri Efekti
local snowflakes = {}
local snowflakesEnabled = false
local snowflakesConnection

local function createSnowflake()
	local flake = GUI:new("Circle")
	flake.Filled = true
	flake.Color = Color3.fromRGB(255, 255, 255)
	flake.Transparency = 0.5 + math.random() * 0.5
	flake.Radius = math.random(2, 6)
	flake.Position = Vector2.new(math.random(0, workspace.CurrentCamera.ViewportSize.X), math.random(-50, 0))
	flake.Visible = true
	flake.ZIndex = 1000
	table.insert(snowflakes, flake)
end

local function toggleSnowflakes(state)
	snowflakesEnabled = state
	if state then
		if snowflakesConnection then return end
		snowflakesConnection = game:GetService("RunService").RenderStepped:Connect(function()
			if not snowflakesEnabled then return end
			for i = #snowflakes, 1, -1 do
				local flake = snowflakes[i]
				flake.Position = flake.Position + Vector2.new(0, 2)
				if flake.Position.Y > workspace.CurrentCamera.ViewportSize.Y then
					flake:Remove()
					table.remove(snowflakes, i)
				end
			end
			if math.random(1, 20) == 1 then
				createSnowflake()
			end
		end)
	else
		if snowflakesConnection then
			snowflakesConnection:Disconnect()
			snowflakesConnection = nil
		end
		for _, flake in ipairs(snowflakes) do
			flake:Remove()
		end
		table.clear(snowflakes)
	end
end

--// Tabs

local General, GeneralSignal = MainFrame:Tab("General")
local _Aimbot = MainFrame:Tab("Aimbot")
local _ESP = MainFrame:Tab("ESP")
local _Crosshair = MainFrame:Tab("Crosshair")
local Settings = MainFrame:Tab("Settings")

--// Functions

local AddValues = function(Section, Object, Exceptions, Prefix)
	local Keys, Copy = {}, {}

	for Index, _ in next, Object do
		Keys[#Keys + 1] = Index
	end

	tablesort(Keys, function(A, B)
		return A < B
	end)

	for _, Value in next, Keys do
		Copy[Value] = Object[Value]
	end

	for Index, Value in next, Copy do
		if typeof(Value) ~= "boolean" or (Exceptions and tablefind(Exceptions, Index)) then
			continue
		end

		Section:Toggle({
			Name = stringgsub(Index, "(%l)(%u)", function(...)
				return select(1, ...).." "..select(2, ...)
			end),
			Flag = Prefix..Index,
			Default = Value,
			Callback = function(_Value)
				Object[Index] = _Value
			end
		})
	end

	for Index, Value in next, Copy do
		if typeof(Value) ~= "Color3" or (Exceptions and tablefind(Exceptions, Index)) then
			continue
		end

		Section:Colorpicker({
			Name = stringgsub(Index, "(%l)(%u)", function(...)
				return select(1, ...).." "..select(2, ...)
			end),
			Flag = Index,
			Default = Value,
			Callback = function(_Value)
				Object[Index] = _Value
			end
		})
	end
end

--// General Tab

local AimbotSection = General:Section({
	Name = "Aimbot Settings",
	Side = "Left"
})

local ESPSection = General:Section({
	Name = "ESP Settings",
	Side = "Right"
})

local ESPDeveloperSection = General:Section({
	Name = "ESP Developer Settings",
	Side = "Right"
})

AddValues(ESPDeveloperSection, ESP_DeveloperSettings, {}, "ESP_DeveloperSettings_")

ESPDeveloperSection:Dropdown({
	Name = "Update Mode",
	Flag = "ESP_UpdateMode",
	Content = {"RenderStepped", "Stepped", "Heartbeat"},
	Default = ESP_DeveloperSettings.UpdateMode,
	Callback = function(Value)
		ESP_DeveloperSettings.UpdateMode = Value
	end
})

ESPDeveloperSection:Dropdown({
	Name = "Team Check Option",
	Flag = "ESP_TeamCheckOption",
	Content = {"TeamColor", "Team"},
	Default = ESP_DeveloperSettings.TeamCheckOption,
	Callback = function(Value)
		ESP_DeveloperSettings.TeamCheckOption = Value
	end
})

ESPDeveloperSection:Slider({
	Name = "Rainbow Speed",
	Flag = "ESP_RainbowSpeed",
	Default = ESP_DeveloperSettings.RainbowSpeed * 10,
	Min = 5,
	Max = 30,
	Callback = function(Value)
		ESP_DeveloperSettings.RainbowSpeed = Value / 10
	end
})

ESPDeveloperSection:Slider({
	Name = "Width Boundary",
	Flag = "ESP_WidthBoundary",
	Default = ESP_DeveloperSettings.WidthBoundary * 10,
	Min = 5,
	Max = 30,
	Callback = function(Value)
		ESP_DeveloperSettings.WidthBoundary = Value / 10
	end
})

ESPDeveloperSection:Button({
	Name = "Refresh",
	Callback = function()
		ESP:Restart()
	end
})

AddValues(ESPSection, ESP_Settings, {"LoadConfigOnLaunch", "PartsOnly"}, "ESPSettings_")

AimbotSection:Toggle({
	Name = "Enabled",
	Flag = "Aimbot_Enabled",
	Default = Aimbot_Settings.Enabled,
	Callback = function(Value)
		Aimbot_Settings.Enabled = Value
	end
})

AddValues(AimbotSection, Aimbot_Settings, {"Enabled", "Toggle", "OffsetToMoveDirection"}, "Aimbot_")

local AimbotDeveloperSection = General:Section({
	Name = "Aimbot Developer Settings",
	Side = "Left"
})

AimbotDeveloperSection:Dropdown({
	Name = "Update Mode",
	Flag = "Aimbot_UpdateMode",
	Content = {"RenderStepped", "Stepped", "Heartbeat"},
	Default = Aimbot_DeveloperSettings.UpdateMode,
	Callback = function(Value)
		Aimbot_DeveloperSettings.UpdateMode = Value
	end
})

AimbotDeveloperSection:Dropdown({
	Name = "Team Check Option",
	Flag = "Aimbot_TeamCheckOption",
	Content = {"TeamColor", "Team"},
	Default = Aimbot_DeveloperSettings.TeamCheckOption,
	Callback = function(Value)
		Aimbot_DeveloperSettings.TeamCheckOption = Value
	end
})

AimbotDeveloperSection:Slider({
	Name = "Rainbow Speed",
	Flag = "Aimbot_RainbowSpeed",
	Default = Aimbot_DeveloperSettings.RainbowSpeed * 10,
	Min = 5,
	Max = 30,
	Callback = function(Value)
		Aimbot_DeveloperSettings.RainbowSpeed = Value / 10
	end
})

AimbotDeveloperSection:Button({
	Name = "Refresh",
	Callback = function()
		Aimbot.Restart()
	end
})

--// Aimbot Tab

local AimbotPropertiesSection = _Aimbot:Section({
	Name = "Properties",
	Side = "Left"
})

AimbotPropertiesSection:Toggle({
	Name = "Toggle",
	Flag = "Aimbot_Toggle",
	Default = Aimbot_Settings.Toggle,
	Callback = function(Value)
		Aimbot_Settings.Toggle = Value
	end
})

AimbotPropertiesSection:Toggle({
	Name = "Offset To Move Direction",
	Flag = "Aimbot_OffsetToMoveDirection",
	Default = Aimbot_Settings.OffsetToMoveDirection,
	Callback = function(Value)
		Aimbot_Settings.OffsetToMoveDirection = Value
	end
})

AimbotPropertiesSection:Slider({
	Name = "Offset Increment",
	Flag = "Aimbot_OffsetIncrementy",
	Default = Aimbot_Settings.OffsetIncrement,
	Min = 1,
	Max = 30,
	Callback = function(Value)
		Aimbot_Settings.OffsetIncrement = Value
	end
})

AimbotPropertiesSection:Slider({
	Name = "Animation Sensitivity (ms)",
	Flag = "Aimbot_Sensitivity",
	Default = Aimbot_Settings.Sensitivity * 100,
	Min = 0,
	Max = 100,
	Callback = function(Value)
		Aimbot_Settings.Sensitivity = Value / 100
	end
})

AimbotPropertiesSection:Slider({
	Name = "mousemoverel Sensitivity",
	Flag = "Aimbot_Sensitivity2",
	Default = Aimbot_Settings.Sensitivity2 * 100,
	Min = 0,
	Max = 500,
	Callback = function(Value)
		Aimbot_Settings.Sensitivity2 = Value / 100
	end
})

AimbotPropertiesSection:Dropdown({
	Name = "Lock Mode",
	Flag = "Aimbot_Settings_LockMode",
	Content = {"CFrame", "mousemoverel"},
	Default = Aimbot_Settings.LockMode == 1 and "CFrame" or "mousemoverel",
	Callback = function(Value)
		Aimbot_Settings.LockMode = Value == "CFrame" and 1 or 2
	end
})

AimbotPropertiesSection:Dropdown({
	Name = "Lock Part",
	Flag = "Aimbot_LockPart",
	Content = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", "LeftLowerLeg", "UpperTorso", "LeftUpperLeg", "RightFoot", "RightLowerLeg", "LowerTorso", "RightUpperLeg"},
	Default = Aimbot_Settings.LockPart,
	Callback = function(Value)
		Aimbot_Settings.LockPart = Value
	end
})

AimbotPropertiesSection:Keybind({
	Name = "Trigger Key",
	Flag = "Aimbot_TriggerKey",
	Default = Aimbot_Settings.TriggerKey,
	Callback = function(Keybind)
		Aimbot_Settings.TriggerKey = Keybind
	end
})

local UserBox = AimbotPropertiesSection:Box({
	Name = "Player Name (shortened allowed)",
	Flag = "Aimbot_PlayerName",
	Placeholder = "Username"
})

AimbotPropertiesSection:Button({
	Name = "Blacklist (Ignore) Player",
	Callback = function()
		pcall(Aimbot.Blacklist, Aimbot, GUI.flags["Aimbot_PlayerName"])
		UserBox:Set("")
	end
})

AimbotPropertiesSection:Button({
	Name = "Whitelist Player",
	Callback = function()
		pcall(Aimbot.Whitelist, Aimbot, GUI.flags["Aimbot_PlayerName"])
		UserBox:Set("")
	end
})

local AimbotFOVSection = _Aimbot:Section({
	Name = "Field Of View Settings",
	Side = "Right"
})

AddValues(AimbotFOVSection, Aimbot_FOV, {}, "Aimbot_FOV_")

AimbotFOVSection:Slider({
	Name = "Field Of View",
	Flag = "Aimbot_FOV_Radius",
	Default = Aimbot_FOV.Radius,
	Min = 0,
	Max = 720,
	Callback = function(Value)
		Aimbot_FOV.Radius = Value
	end
})

AimbotFOVSection:Slider({
	Name = "Sides",
	Flag = "Aimbot_FOV_NumSides",
	Default = Aimbot_FOV.NumSides,
	Min = 3,
	Max = 60,
	Callback = function(Value)
		Aimbot_FOV.NumSides = Value
	end
})

AimbotFOVSection:Slider({
	Name = "Transparency",
	Flag = "Aimbot_FOV_Transparency",
	Default = Aimbot_FOV.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		Aimbot_FOV.Transparency = Value / 10
	end
})

AimbotFOVSection:Slider({
	Name = "Thickness",
	Flag = "Aimbot_FOV_Thickness",
	Default = Aimbot_FOV.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		Aimbot_FOV.Thickness = Value
	end
})

--// ESP Tab

local ESP_Properties_Section = _ESP:Section({
	Name = "ESP Properties",
	Side = "Left"
})

AddValues(ESP_Properties_Section, ESP_Properties.ESP, {}, "ESP_Propreties_")

ESP_Properties_Section:Dropdown({
	Name = "Text Font",
	Flag = "ESP_TextFont",
	Content = Fonts,
	Default = Fonts[ESP_Properties.ESP.Font + 1],
	Callback = function(Value)
		ESP_Properties.ESP.Font = Drawing.Fonts[Value]
	end
})

ESP_Properties_Section:Slider({
	Name = "Transparency",
	Flag = "ESP_TextTransparency",
	Default = ESP_Properties.ESP.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		ESP_Properties.ESP.Transparency = Value / 10
	end
})

ESP_Properties_Section:Slider({
	Name = "Font Size",
	Flag = "ESP_FontSize",
	Default = ESP_Properties.ESP.Size,
	Min = 1,
	Max = 20,
	Callback = function(Value)
		ESP_Properties.ESP.Size = Value
	end
})

ESP_Properties_Section:Slider({
	Name = "Offset",
	Flag = "ESP_Offset",
	Default = ESP_Properties.ESP.Offset,
	Min = 10,
	Max = 30,
	Callback = function(Value)
		ESP_Properties.ESP.Offset = Value
	end
})

local Tracer_Properties_Section = _ESP:Section({
	Name = "Tracer Properties",
	Side = "Right"
})

AddValues(Tracer_Properties_Section, ESP_Properties.Tracer, {}, "Tracer_Properties_")

Tracer_Properties_Section:Dropdown({
	Name = "Position",
	Flag = "Tracer_Position",
	Content = TracerPositions,
	Default = TracerPositions[ESP_Properties.Tracer.Position],
	Callback = function(Value)
		ESP_Properties.Tracer.Position = tablefind(TracerPositions, Value)
	end
})

Tracer_Properties_Section:Slider({
	Name = "Transparency",
	Flag = "Tracer_Transparency",
	Default = ESP_Properties.Tracer.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		ESP_Properties.Tracer.Transparency = Value / 10
	end
})

Tracer_Properties_Section:Slider({
	Name = "Thickness",
	Flag = "Tracer_Thickness",
	Default = ESP_Properties.Tracer.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		ESP_Properties.Tracer.Thickness = Value
	end
})

local HeadDot_Properties_Section = _ESP:Section({
	Name = "Head Dot Properties",
	Side = "Left"
})

AddValues(HeadDot_Properties_Section, ESP_Properties.HeadDot, {}, "HeadDot_Properties_")

HeadDot_Properties_Section:Slider({
	Name = "Transparency",
	Flag = "HeadDot_Transparency",
	Default = ESP_Properties.HeadDot.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		ESP_Properties.HeadDot.Transparency = Value / 10
	end
})

HeadDot_Properties_Section:Slider({
	Name = "Thickness",
	Flag = "HeadDot_Thickness",
	Default = ESP_Properties.HeadDot.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		ESP_Properties.HeadDot.Thickness = Value
	end
})

HeadDot_Properties_Section:Slider({
	Name = "Sides",
	Flag = "HeadDot_Sides",
	Default = ESP_Properties.HeadDot.NumSides,
	Min = 3,
	Max = 30,
	Callback = function(Value)
		ESP_Properties.HeadDot.NumSides = Value
	end
})

local Box_Properties_Section = _ESP:Section({
	Name = "Box Properties",
	Side = "Left"
})

AddValues(Box_Properties_Section, ESP_Properties.Box, {}, "Box_Properties_")

Box_Properties_Section:Slider({
	Name = "Transparency",
	Flag = "Box_Transparency",
	Default = ESP_Properties.Box.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		ESP_Properties.Box.Transparency = Value / 10
	end
})

Box_Properties_Section:Slider({
	Name = "Thickness",
	Flag = "Box_Thickness",
	Default = ESP_Properties.Box.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		ESP_Properties.Box.Thickness = Value
	end
})

local HealthBar_Properties_Section = _ESP:Section({
	Name = "Health Bar Properties",
	Side = "Right"
})

AddValues(HealthBar_Properties_Section, ESP_Properties.HealthBar, {}, "HealthBar_Properties_")

HealthBar_Properties_Section:Dropdown({
	Name = "Position",
	Flag = "HealthBar_Position",
	Content = HealthBarPositions,
	Default = HealthBarPositions[ESP_Properties.HealthBar.Position],
	Callback = function(Value)
		ESP_Properties.HealthBar.Position = tablefind(HealthBarPositions, Value)
	end
})

HealthBar_Properties_Section:Slider({
	Name = "Transparency",
	Flag = "HealthBar_Transparency",
	Default = ESP_Properties.HealthBar.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		ESP_Properties.HealthBar.Transparency = Value / 10
	end
})

HealthBar_Properties_Section:Slider({
	Name = "Thickness",
	Flag = "HealthBar_Thickness",
	Default = ESP_Properties.HealthBar.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		ESP_Properties.HealthBar.Thickness = Value
	end
})

HealthBar_Properties_Section:Slider({
	Name = "Offset",
	Flag = "HealthBar_Offset",
	Default = ESP_Properties.HealthBar.Offset,
	Min = 4,
	Max = 12,
	Callback = function(Value)
		ESP_Properties.HealthBar.Offset = Value
	end
})

HealthBar_Properties_Section:Slider({
	Name = "Blue",
	Flag = "HealthBar_Blue",
	Default = ESP_Properties.HealthBar.Blue,
	Min = 0,
	Max = 255,
	Callback = function(Value)
		ESP_Properties.HealthBar.Blue = Value
	end
})

local Chams_Properties_Section = _ESP:Section({
	Name = "Chams Properties",
	Side = "Right"
})

AddValues(Chams_Properties_Section, ESP_Properties.Chams, {}, "Chams_Properties_")

Chams_Properties_Section:Slider({
	Name = "Transparency",
	Flag = "Chams_Transparency",
	Default = ESP_Properties.Chams.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		ESP_Properties.Chams.Transparency = Value / 10
	end
})

Chams_Properties_Section:Slider({
	Name = "Thickness",
	Flag = "Chams_Thickness",
	Default = ESP_Properties.Chams.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		ESP_Properties.Chams.Thickness = Value
	end
})

--// Crosshair Tab

local Crosshair_Settings = _Crosshair:Section({
	Name = "Crosshair Settings (1 / 2)",
	Side = "Left"
})

Crosshair_Settings:Toggle({
	Name = "Enabled",
	Flag = "Crosshair_Enabled",
	Default = Crosshair.Enabled,
	Callback = function(Value)
		Crosshair.Enabled = Value
	end
})

Crosshair_Settings:Toggle({
	Name = "Enable ROBLOX Cursor",
	Flag = "Cursor_Enabled",
	Default = UserInputService.MouseIconEnabled,
	Callback = SetMouseIconVisibility
})

AddValues(Crosshair_Settings, Crosshair, {"Enabled"}, "Crosshair_")

Crosshair_Settings:Dropdown({
	Name = "Position",
	Flag = "Crosshair_Position",
	Content = {"Mouse", "Center"},
	Default = ({"Mouse", "Center"})[Crosshair.Position],
	Callback = function(Value)
		Crosshair.Position = Value == "Mouse" and 1 or 2
	end
})

Crosshair_Settings:Slider({
	Name = "Size",
	Flag = "Crosshair_Size",
	Default = Crosshair.Size,
	Min = 1,
	Max = 24,
	Callback = function(Value)
		Crosshair.Size = Value
	end
})

Crosshair_Settings:Slider({
	Name = "Gap Size",
	Flag = "Crosshair_GapSize",
	Default = Crosshair.GapSize,
	Min = 0,
	Max = 24,
	Callback = function(Value)
		Crosshair.GapSize = Value
	end
})

Crosshair_Settings:Slider({
	Name = "Rotation (Degrees)",
	Flag = "Crosshair_Rotation",
	Default = Crosshair.Rotation,
	Min = -180,
	Max = 180,
	Callback = function(Value)
		Crosshair.Rotation = Value
	end
})

Crosshair_Settings:Slider({
	Name = "Rotation Speed",
	Flag = "Crosshair_RotationSpeed",
	Default = Crosshair.RotationSpeed,
	Min = 1,
	Max = 20,
	Callback = function(Value)
		Crosshair.RotationSpeed = Value
	end
})

Crosshair_Settings:Slider({
	Name = "Pulsing Step",
	Flag = "Crosshair_PulsingStep",
	Default = Crosshair.PulsingStep,
	Min = 0,
	Max = 24,
	Callback = function(Value)
		Crosshair.PulsingStep = Value
	end
})

local _Crosshair_Settings = _Crosshair:Section({
	Name = "Crosshair Settings (2 / 2)",
	Side = "Left"
})

_Crosshair_Settings:Slider({
	Name = "Pulsing Speed",
	Flag = "Crosshair_PulsingSpeed",
	Default = Crosshair.PulsingSpeed,
	Min = 1,
	Max = 20,
	Callback = function(Value)
		Crosshair.PulsingSpeed = Value
	end
})

_Crosshair_Settings:Slider({
	Name = "Pulsing Boundary (Min)",
	Flag = "Crosshair_Pulse_Min",
	Default = Crosshair.PulsingBounds[1],
	Min = 0,
	Max = 24,
	Callback = function(Value)
		Crosshair.PulsingBounds[1] = Value
	end
})

_Crosshair_Settings:Slider({
	Name = "Pulsing Boundary (Max)",
	Flag = "Crosshair_Pulse_Max",
	Default = Crosshair.PulsingBounds[2],
	Min = 0,
	Max = 24,
	Callback = function(Value)
		Crosshair.PulsingBounds[2] = Value
	end
})

_Crosshair_Settings:Slider({
	Name = "Transparency",
	Flag = "Crosshair_Transparency",
	Default = Crosshair.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		Crosshair.Transparency = Value / 10
	end
})

_Crosshair_Settings:Slider({
	Name = "Thickness",
	Flag = "Crosshair_Thickness",
	Default = Crosshair.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		Crosshair.Thickness = Value
	end
})

local Crosshair_CenterDot = _Crosshair:Section({
	Name = "Center Dot Settings",
	Side = "Right"
})

Crosshair_CenterDot:Toggle({
	Name = "Enabled",
	Flag = "Crosshair_CenterDot_Enabled",
	Default = CenterDot.Enabled,
	Callback = function(Value)
		CenterDot.Enabled = Value
	end
})

AddValues(Crosshair_CenterDot, CenterDot, {"Enabled"}, "Crosshair_CenterDot_")

Crosshair_CenterDot:Slider({
	Name = "Size / Radius",
	Flag = "Crosshair_CenterDot_Radius",
	Default = CenterDot.Radius,
	Min = 2,
	Max = 8,
	Callback = function(Value)
		CenterDot.Radius = Value
	end
})

Crosshair_CenterDot:Slider({
	Name = "Sides",
	Flag = "Crosshair_CenterDot_Sides",
	Default = CenterDot.NumSides,
	Min = 3,
	Max = 30,
	Callback = function(Value)
		CenterDot.NumSides = Value
	end
})

Crosshair_CenterDot:Slider({
	Name = "Transparency",
	Flag = "Crosshair_CenterDot_Transparency",
	Default = CenterDot.Transparency * 10,
	Min = 1,
	Max = 10,
	Callback = function(Value)
		CenterDot.Transparency = Value / 10
	end
})

Crosshair_CenterDot:Slider({
	Name = "Thickness",
	Flag = "Crosshair_CenterDot_Thickness",
	Default = CenterDot.Thickness,
	Min = 1,
	Max = 5,
	Callback = function(Value)
		CenterDot.Thickness = Value
	end
})

--// Settings Tab

local SettingsSection = Settings:Section({
	Name = "Settings",
	Side = "Left"
})

local ProfilesSection = Settings:Section({
	Name = "Profiles",
	Side = "Left"
})

local InformationSection = Settings:Section({
	Name = "Information",
	Side = "Right"
})

local MiscellaneousSection = Settings:Section({
	Name = "Miscellaneous",
	Side = "Right"
})

SettingsSection:Keybind({
	Name = "Show / Hide GUI",
	Flag = "UI Toggle",
	Default = Enum.KeyCode.RightShift,
	Blacklist = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3},
	Callback = function(_, NewKeybind)
		if not NewKeybind then
			GUI:Close()
		end
	end
})

SettingsSection:Button({
	Name = "Unload Script",
	Callback = function()
		GUI:Unload()
		ESP:Exit()
		Aimbot:Exit()
		toggleSnowflakes(false)
		getgenv().AirHubV2Loaded = nil
	end
})

-- Kar Taneleri Toggle
MiscellaneousSection:Toggle({
	Name = "Snowflakes",
	Flag = "Snowflakes",
	Default = false,
	Callback = function(state)
		toggleSnowflakes(state)
	end
})

-- Yeni ESP Geliştirmeleri (placeholder)
local ESPImprovements = Settings:Section({
	Name = "ESP Improvements",
	Side = "Left"
})

ESPImprovements:Toggle({
	Name = "Visibility Check (experimental)",
	Flag = "ESP_VisibilityCheck",
	Default = false,
	Callback = function(state)
		-- Burada ESP modülüne visibility check eklemek için bir hook yapılabilir.
		-- Örnek: ESP.Properties.ESP.VisibilityCheck = state
	end
})

ESPImprovements:Slider({
	Name = "Distance Limit",
	Flag = "ESP_DistanceLimit",
	Default = 500,
	Min = 50,
	Max = 2000,
	Callback = function(value)
		-- ESP'ye mesafe sınırı eklemek için
	end
})

-- Yeni Aimbot Geliştirmeleri (placeholder)
local AimbotImprovements = Settings:Section({
	Name = "Aimbot Improvements",
	Side = "Right"
})

AimbotImprovements:Slider({
	Name = "Smoothness",
	Flag = "Aimbot_Smoothness",
	Default = 1,
	Min = 1,
	Max = 20,
	Callback = function(value)
		-- Aimbot smoothness ayarı
		-- Örnek: Aimbot.Settings.Smoothness = value
	end
})

AimbotImprovements:Toggle({
	Name = "Prediction",
	Flag = "Aimbot_Prediction",
	Default = false,
	Callback = function(state)
		-- Hedef tahmini
	end
})

--// Configurations

local ConfigList = ProfilesSection:Dropdown({
	Name = "Configurations",
	Flag = "Config Dropdown",
	Content = GUI:GetConfigs()
})

ProfilesSection:Box({
	Name = "Configuration Name",
	Flag = "Config Name",
	Placeholder = "Config Name"
})

ProfilesSection:Button({
	Name = "Load Configuration",
	Callback = function()
		GUI:LoadConfig(GUI.flags["Config Dropdown"])
	end
})

ProfilesSection:Button({
	Name = "Delete Configuration",
	Callback = function()
		GUI:DeleteConfig(GUI.flags["Config Dropdown"])
		ConfigList:Refresh(GUI:GetConfigs())
	end
})

ProfilesSection:Button({
	Name = "Save Configuration",
	Callback = function()
		GUI:SaveConfig(GUI.flags["Config Dropdown"] or GUI.flags["Config Name"])
		ConfigList:Refresh(GUI:GetConfigs())
	end
})

InformationSection:Label("Made by Exunys")

InformationSection:Button({
	Name = "Copy GitHub",
	Callback = function()
		setclipboard("https://github.com/Exunys")
	end
})

InformationSection:Label("AirTeam © 2022 - "..osdate("%Y"))

InformationSection:Button({
	Name = "Copy Discord Invite",
	Callback = function()
		setclipboard("https://discord.gg/Ncz3H3quUZ")
	end
})

--// Load

ESP.Load()
Aimbot.Load()
getgenv().AirHubV2Loaded = true
getgenv().AirHubV2Loading = nil

GeneralSignal:Fire()
-- GUI:Close() satırı kaldırıldı, menü başlangıçta açık.
