local HttpService = game:GetService("HttpService")
local ConfigManager = {}

function ConfigManager.new(options)
	local self = setmetatable({}, { __index = ConfigManager })
	self._options = options or {}
	self._folder = "7yd7Hub/configs"
	self._autoload = "Autoload"
	self._exclude = {}
	return self
end

function ConfigManager:SetFolder(f)
	self._folder = f
	return self
end

function ConfigManager:IgnoreIndexes(list)
	self._exclude = list or {}
	return self
end

function ConfigManager:Collect()
	local data = {}
	for id, opt in pairs(self._options) do
		if opt and opt.Value ~= nil then
			local skip = false
			for _, ex in ipairs(self._exclude) do
				if tostring(ex) == tostring(id) then skip = true; break end
			end
			if not skip then
				data[id] = opt.Value
			end
		end
	end
	return data
end

function ConfigManager:Apply(data)
	for id, value in pairs(data or {}) do
		local opt = self._options[id]
		if opt and opt.SetValue then
			pcall(function() opt:SetValue(value) end)
		end
	end
end

function ConfigManager:List()
	local list = {}
	pcall(function()
		if not isfolder(self._folder) then return end
		for _, name in ipairs(listfiles(self._folder)) do
			if name:match('%.json$') then
				local short = name:gsub('^.+[\\/]', ''):gsub('%.json$', '')
				if short:sub(1, 1) ~= "_" then
					table.insert(list, short)
				end
			end
		end
	end)
	table.sort(list)
	return list
end

function ConfigManager:Save(name)
	name = name or self._autoload
	local data = self:Collect()
	pcall(function()
		if not isfolder(self._folder) then makefolder(self._folder) end
		writefile(self._folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
	end)
end

function ConfigManager:Load(name)
	name = name or self._autoload
	local path = self._folder .. "/" .. name .. ".json"
	pcall(function()
		if isfile(path) then
			local s, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
			if s then self:Apply(data) end
		end
	end)
end

function ConfigManager:Delete(name)
	local path = self._folder .. "/" .. name .. ".json"
	pcall(function() if isfile(path) then delfile(path) end end)
end

function ConfigManager:Rename(old, new)
	if not old or not new or old == new then return end
	local oldPath = self._folder .. "/" .. old .. ".json"
	local newPath = self._folder .. "/" .. new .. ".json"
	pcall(function()
		if isfile(oldPath) then
			writefile(newPath, readfile(oldPath))
			delfile(oldPath)
		end
	end)
end

function ConfigManager:Exists(name)
	local path = self._folder .. "/" .. tostring(name) .. ".json"
	local ok, result = pcall(function() return isfile(path) end)
	return ok and result
end

function ConfigManager:GetAutoloadConfig()
	local path = self._folder .. "/_autoload.json"
	local ok, result = pcall(function()
		if isfile(path) then
			local data = HttpService:JSONDecode(readfile(path))
			return data and data.name or nil
		end
	end)
	return ok and result or nil
end

function ConfigManager:SetAutoloadConfig(name)
	local path = self._folder .. "/_autoload.json"
	pcall(function()
		if not isfolder(self._folder) then makefolder(self._folder) end
		writefile(path, HttpService:JSONEncode({ name = name }))
	end)
end

function ConfigManager:ResetAutoloadConfig()
	local path = self._folder .. "/_autoload.json"
	pcall(function() if isfile(path) then delfile(path) end end)
end

function ConfigManager:LoadAutoloadConfig()
	local autoloadName = self:GetAutoloadConfig()
	if autoloadName then
		self:Load(autoloadName)
	end
end

function ConfigManager:BuildConfigSection(tab)
	local selected = self._autoload
	local configDropdown

	local function refresh()
		local list = self:List()
		if #list == 0 then table.insert(list, "No configs") end
		if configDropdown and configDropdown.SetValues then
			configDropdown:SetValues(list)
		end
	end

	tab:AddSection({ Title = "Config Manager", Icon = "" })

	local saveAsInput = tab:AddInput("CM_SaveAs", {
		Title = "Config Name",
		Default = "",
		Placeholder = "Enter config name..."
	})

	tab:AddButton({
		Title = "Save As",
		Description = "Saves as new config",
		Callback = function()
			local name = saveAsInput and saveAsInput.Value or ""
			if name ~= "" then
				self:Save(name)
				refresh()
			end
		end
	})

	local configValues = self:List()
	if #configValues == 0 then configValues = {"No configs"} end
	configDropdown = tab:AddDropdown("CM_Dropdown", {
		Title = "Config List",
		Values = configValues,
		Default = configValues[1],
		Callback = function(v) selected = v end
	})

	tab:AddButton({
		Title = "Load",
		Description = "Loads selected config",
		Callback = function()
			if selected and selected ~= "No configs" then
				self:Load(selected)
			end
		end
	})

	tab:AddButton({
		Title = "Overwrite",
		Description = "Overwrites selected config",
		Callback = function()
			if selected and selected ~= "No configs" then
				self:Save(selected)
			end
		end
	})

	local renameInput = tab:AddInput("CM_Rename", {
		Title = "Rename To",
		Default = "",
		Placeholder = "New name..."
	})

	tab:AddButton({
		Title = "Rename",
		Description = "Renames selected config",
		Callback = function()
			local new = renameInput and renameInput.Value or ""
			if selected and selected ~= "No configs" and new ~= "" then
				self:Rename(selected, new)
				refresh()
				selected = new
			end
		end
	})

	tab:AddButton({
		Title = "Delete",
		Description = "Deletes selected config",
		Callback = function()
			if selected and selected ~= "No configs" then
				self:Delete(selected)
				refresh()
				selected = nil
			end
		end
	})
end

return ConfigManager
