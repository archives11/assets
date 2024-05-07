--[[ Credits
    @matas - Created UI
]]

-- Services

    local PLAYERS = cloneref(game:GetService("Players"));
    local RUN_SERVICE = cloneref(game:GetService("RunService"));
    local REPLICATED_STORAGE = cloneref(game:GetService("ReplicatedStorage"));
    --
    local camera = workspace.CurrentCamera;
    local localPlayer = PLAYERS.LocalPlayer;
    local closestDir = nil;
    local specateFrame = localPlayer.PlayerGui.MainGui.Spectate;
    --
    local new_proj = require(REPLICATED_STORAGE:WaitForChild("GunSystem").GunSharedAssets.Projectile).New;
    local fire = require(REPLICATED_STORAGE:WaitForChild("GunSystem").GunClientAssets.Modules.Gun).Fire;

--
local settings = {
    combat = {
        silentAim = false;
        hitPart = "Head";
        useFov = false;
		maxDist = 400;
        triggerBot = false;
		triggerBotDelay = 0.1;
		infiniteAmmo = false;
		instantreload = false;
		meelerange = true;
        rapidFire = false;
        noSpread = false;
		noRecoil = false;
		instantequip = false;
        fovCircle = {
            enabled = false;
            sides = 64;
            color = Color3.fromRGB(255, 255, 255);
            transparency = 1;
            radius = 75;
            thickness = 2;
            filled = false
        }
    }
}
--
do -- silent aim and gun mods
	local function is_not_spectating()
		if specateFrame.Visible then
			return false;
		end
		return true;
	end
	
	local function get_closest()
		local closest = nil;
		local maxDist = settings.combat.maxDist;
	
		for _, player in pairs(workspace:GetChildren()) do
			if player:IsA("Model") and player.Name ~= localPlayer.Name and player:FindFirstChild(settings.combat.hitPart) then
				local pos = player[settings.combat.hitPart].CFrame.p;
				local posv2, onScreen = camera:WorldToScreenPoint(pos);
	
				if onScreen then
					local distance = (Vector2.new(posv2.X, posv2.Y) - (camera.ViewportSize / 2)).Magnitude;
					
					if distance < settings.combat.fovCircle.radius then
						distance = (camera.CFrame.p - pos).Magnitude;
	
						if distance < maxDist then
							closest = player;
							maxDist = distance;
						end
					end
				end
			end
		end
	
		if closest then
			return closest;
		end
	end
	
	RUN_SERVICE.Heartbeat:Connect(function()
		if is_not_spectating() then
			local closest = get_closest();
			local localChar = localPlayer.Character;
			local localHitBox = workspace.Hitboxes:FindFirstChild(localPlayer.Name);
			local hitPart = closest and closest:FindFirstChild(settings.combat.hitPart);
		
			if closest and localChar and localHitBox and hitPart then
				local screenPos = camera:WorldToScreenPoint(hitPart.CFrame.p);
				local rayDir = camera:ScreenPointToRay(screenPos.X, screenPos.Y).Direction;
		
				local origin = camera.CFrame.p;
				local destination = hitPart.CFrame.p;
				local direction = destination - origin;
				local params = RaycastParams.new();
				params.FilterDescendantsInstances = {camera, localChar, workspace.Hitboxes:FindFirstChild(localPlayer.Name)};
				params.FilterType = Enum.RaycastFilterType.Exclude;
				params.IgnoreWater = true;
				result = workspace:Raycast(origin, direction, params);

				if result and result.Instance and (result.Instance:IsDescendantOf(workspace.Hitboxes:FindFirstChild(closest.Name)) or result.Instance:IsDescendantOf(closest)) then
					closestDir = rayDir;
		
					if settings.combat.triggerBot and not closest:FindFirstChild("RoundForceField") then
						task.wait(settings.combat.triggerBotDelay);
						mouse1click();
						task.wait(settings.combat.triggerBotDelay);
					end
				else
					closestDir = nil;
				end


			end
		end
	end);
	
	--targetcolor
	-- Function Hooks
	local silentHook;
	local fireHook;
	
	silentHook = hookfunction(new_proj, function(...)
		local args = {...};
	
		args[6] = (settings.combat.silentAim and closestDir) or args[6];
	
		return silentHook(table.unpack(args));
	end);
	
	fireHook = hookfunction(fire, function(...)
		local args = {...};
	
		if settings.combat.infiniteAmmo then
			local ammoVal = args[1].Ammo;
			args[1].Ammo = math.huge;
		end
		if settings.combat.rapidFire then
			args[1].FireRate = 0.01;
		end
		if settings.combat.noSpread then
			args[1].Spread = 0;
		end
		if settings.combat.meelerange then
			args[1].Range = 1000000;
			args[1].Damage = 1000000;
			args[1].ProjectileType = "Bullet"

		end
		if settings.combat.instantreload then
			args[1].ReloadTime = 0;
			--args[1].Animations.Fire = false; -- Breaks gun system.
		end

		if settings.combat.noRecoil then
			args[1].RecoilMult = 0;
		end
		if settings.combat.instantequip then
			args[1].EquipTime = 0;
		end
		return fireHook(table.unpack(args))
	end);
	
	local CircleInline = Drawing.new("Circle")
	local CircleOutline = Drawing.new("Circle")
	RUN_SERVICE.RenderStepped:Connect(function()
		CircleInline.Radius = settings.combat.fovCircle.radius;
		CircleInline.Thickness = settings.combat.fovCircle.thickness;
		CircleInline.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2);
		CircleInline.Transparency = settings.combat.fovCircle.transparency;
		CircleInline.Color = settings.combat.fovCircle.color;

		CircleInline.Visible = settings.combat.fovCircle.enabled;
		CircleInline.ZIndex = 2
		CircleInline.Filled = settings.combat.fovCircle.filled;
		
		CircleOutline.Radius = settings.combat.fovCircle.radius;
		CircleOutline.Thickness = 3
		CircleOutline.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2);
		CircleOutline.Transparency = settings.combat.fovCircle.transparency;
		CircleOutline.Color = Color3.new()
		CircleOutline.Visible = settings.combat.fovCircle.enabled;
		CircleOutline.ZIndex = 1
	end)
end

local Library, Utility, Flags, Theme = loadfile("Library.lua")()

local Settings = loadfile("esp.lua")();

do -- Utility
    function Utility:GetTableIndexes(Table, Custom)
        local Table2 = {}
        --
        for Index, Value in pairs(Table) do
            Table2[Custom and Value[1] or #Table2 + 1] = Index 
        end
        --
        return Table2
    end
    --
    function Utility:ConvertTable(Table1)
        local Table2 = {}
        --
        for Index, Value in pairs(Table1) do
            Table2[typeof(Index) ~= "number" and Index or (#Table2 + 1)] = tostring(Value)
        end
        --
        return Table2
    end
    --
    function Utility:ConvertString(Value)
        if typeof(Value) == "Color3" then
            Value = Value:ToHex()
        end
        --
        return Value
    end
    --
    function Utility:Encode(Table)
        local Table2 = {}
        --
        for Index, Value in pairs(Table) do
            Table2[Index] = Utility:ConvertString(Value)
        end
        --
        return HttpService:JSONEncode(Table2)
    end
    --
    function Utility:Decode(Table)
        return HttpService:JSONDecode(Table)
    end
    --
    function Library:UpdateColor(ColorType, ColorValue)
        local ColorType = ColorType:lower()
        --
        Theme[ColorType] = ColorValue
        --
        for Index, Value in pairs(Library.colors) do
            for Index2, Value2 in pairs(Value) do
                if Value2 == ColorType then
                    Index[Index2] = Theme[Value2]
                end
            end
        end
    end
    --
    function Library:UpdateTheme(ThemeType, ThemeValue)
        if Flags["ConfigTheme_" .. ThemeType] then
            Flags["ConfigTheme_" .. ThemeType]:Set(ThemeValue)
        end
    end
    --
    function Library:LoadTheme(ThemeType)
        if Themes[ThemeType] then
            local ThemeValue = Utility:Decode(Themes[ThemeType][2])
            --
            for Index, Value in pairs(ThemeValue) do
                Library:UpdateTheme(Index, Color3.fromHex(Value)) 
            end
        end
    end
    --
    function Library:RefreshConfigList()
        Flags["ConfigConfiguration_Box"].options = Atlanta.Configs
        Flags["ConfigConfiguration_Box"].current = Clamp(Flags["ConfigConfiguration_Box"].current, 0, #Atlanta.Configs)
        Flags["ConfigConfiguration_Box"]:UpdateScroll()
    end
    --
    function Library:GetConfig()
        local Config = ""
        --
        for Index, Value in pairs(Flags) do
            if Index ~= "ConfigConfiguration_Box" and Index ~= "ConfigConfiguration_Name" then
                local Value2 = Value:Get()
                local Final = ""
                --
                if typeof(Value2) == "Color3" then
                    local Values = Value.current
                    --
                    Final = ("rgb(%s,%s,%s,%s)"):format(Values[1], Values[2], Values[3], Values[4])
                elseif typeof(Value2) == "table" and Value2.Color and Value2.Transparency then
                    local Values = Value.current
                    --
                    Final = ("rgb(%s,%s,%s,%s)"):format(Values[1], Values[2], Values[3], Values[4])
                elseif Value.mode then
                    local Values = Value.current
                    --
                    Final = ("key(%s,%s,%s)"):format(Values[1] or "nil", Values[2] or "nil", Value.mode)
                elseif (Value2 ~= nil) then
                    if typeof(Value2) == "boolean" then
                        Value2 = ("bool(%s)"):format(tostring(Value2))
                    elseif typeof(Value2) == "table" then
                        local New = "table("
                        --
                        for Index2, Value3 in pairs(Value2) do
                            New = New .. Value3 .. ","
                        end
                        --
                        if New:sub(#New) == "," then
                            New = New:sub(0, #New - 1)
                        end
                        --
                        Value2 = New .. ")"
                    elseif typeof(Value2) == "string" then
                        Value2 = ("string(%s)"):format(Value2)
                    elseif typeof(Value2) == "number" then
                        Value2 = ("number(%s)"):format(Value2)
                    end
                    --
                    Final = Value2
                end
                --
                Config = Config .. Index .. ": " .. Final .. "\n"
            end
        end
        --
        return Config .. "[ gamesneeze.cc ]"
    end
    --
    function Library:LoadConfig(Config)
        if typeof(Config) == "table" then
            for Index, Value in pairs(Config) do
                if typeof(Flags[Index]) ~= "nil" then
                    Flags[Index]:Set(Value)
                end
            end
        end
    end
    --
    function Library:PerformConfigAction(ConfigName, Action)
        if ConfigName then
            if Action == "Delete" then
                local Found = Find(Atlanta.Configs, ConfigName)
                --
                if Found then
                    Remove(Atlanta.Configs, Found) 
                    Library:RefreshConfigList()
                end
                --
                delfile(("Atlanta/Configs/%s/%s"):format(Atlanta.Version, ConfigName .. ".Atlanta"), Config)
            elseif Action == "Save" then
                local Config = Library:GetConfig()
                --
                if Config then
                    if not Find(Atlanta.Configs, ConfigName) then
                        Atlanta.Configs[#Atlanta.Configs + 1] = ConfigName
                        Library:RefreshConfigList()
                    end
                    --
                    writefile(("Atlanta/Configs/%s/%s"):format(Atlanta.Version, ConfigName .. ".Atlanta"), Config)
                end
            elseif Action == "Load" then
                local Config = readfile(("Atlanta/Configs/%s/%s"):format(Atlanta.Version, ConfigName .. ".Atlanta"))
                local Table = Split(Config, "\n")
                local Table2 = {}
                --
                if Table[#Table] == "[ gamesneeze.cc ]" then
                    Remove(Table, #Table)
                end
                --
                for Index, Value in pairs(Table) do
                    local Table3 = Split(Value, ":")
                    --
                    if Table3[1] ~= "ConfigConfiguration_Name" and #Table3 >= 2 then
                        local Value = Table3[2]:sub(2, #Table3[2])
                        --
                        if Value:sub(1, 3) == "rgb" then
                            local Table4 = Split(Value:sub(5, #Value - 1), ",")
                            --
                            Value = Table4
                        elseif Value:sub(1, 3) == "key" then
                            local Table4 = Split(Value:sub(5, #Value - 1), ",")
                            --
                            if Table4[1] == "nil" and Table4[2] == "nil" then
                                Table4[1] = nil
                                Table4[2] = nil
                            end
                            --
                            Value = Table4
                        elseif Value:sub(1, 4) == "bool" then
                            local Bool = Value:sub(6, #Value - 1)
                            --
                            Value = Bool == "true"
                        elseif Value:sub(1, 5) == "table" then
                            local Table4 = Split(Value:sub(7, #Value - 1), ",")
                            --
                            Value = Table4
                        elseif Value:sub(1, 6) == "string" then
                            local String = Value:sub(8, #Value - 1)
                            --
                            Value = String
                        elseif Value:sub(1, 6) == "number" then
                            local Number = tonumber(Value:sub(8, #Value - 1))
                            --
                            Value = Number
                        end
                        --
                        Table2[Table3[1]] = Value
                    end
                end
                -- 
                Library:LoadConfig(Table2)
            end
        end
    end
    --
    function Library:UpdateHue()
        if (tick() - Atlanta.Locals.ShiftTick) >= (1 / 60) then
            Atlanta.Locals.Shift = Atlanta.Locals.Shift + 0.01
            --
            if Flags["ConfigTheme_AccentEffect"]:Get() == "Rainbow" then
                Library:UpdateColor("Accent", Color3.fromHSV(Math:Shift(Atlanta.Locals.Shift), 0.55, 1))
            elseif Flags["ConfigTheme_AccentEffect"]:Get() == "Shift" then
                local Hue, Saturation, Value = Flags["ConfigTheme_Accent"]:Get():ToHSV()
                --
                Library:UpdateColor("Accent", Color3.fromHSV(Math:Shift(Hue + (Math:Shift(Atlanta.Locals.Shift) * (Flags["ConfigTheme_EffectLength"]:Get() / 360))), Saturation, Value))
            elseif Flags["ConfigTheme_AccentEffect"]:Get() == "Reverse Shift" then
                local Hue, Saturation, Value = Flags["ConfigTheme_Accent"]:Get():ToHSV()
                --
                Library:UpdateColor("Accent", Color3.fromHSV(Math:Shift(Clamp(Hue - (Math:Shift(Atlanta.Locals.Shift) * (Flags["ConfigTheme_EffectLength"]:Get() / 360)), 0, 9999)), Saturation, Value))
            end
            --
            Atlanta.Locals.ShiftTick = tick()
        end
    end
    --
    function Utility:ClampString(String, Length, Font)
        local Font = (Font or 2)
        local Split = String:split("\n")
        --
        local Clamped = ""
        --
        for Index, Value2 in pairs(Split) do
            if (Index * 13) <= Length then
                Clamped = Clamped .. Value2 .. (Index == #Split and "" or "\n")
            end
        end
        --
        return (Clamped ~= String and (Clamped == "" and "" or Clamped:sub(0, #Clamped - 1) .. " ...") or Clamped)
    end
    --
    function Utility:ThreadFunction(Func, Name, ...)
        local Func = Name and function()
            local Passed, Statement = pcall(Func)
            --
            if not Passed and not Atlanta.Safe then
                warn("Atlanta:\n", "              " .. Name .. ":", Statement)
            end
        end or Func
        local Thread = Create(Func)
        --
        Resume(Thread, ...)
        return Thread
    end
    --
    function Utility:SafeCheck(Text)
        local Safe = Text:lower()
        --
        for Index, Value in pairs(Atlanta.Locals.BadWords) do Safe = Safe:gsub(Value, "_") end
        --
        return Safe
    end
    --
    function Utility:TableToString(Table)
        if #Table > 1 then
            local Text = ""
            --
            for Index, Value in pairs(Table) do
                Text = Text .. Value .. "\n"
            end
            --
            return Text:sub(0, #Text - 1)
        else
            return Table[1]
        end
    end
    --
    function Utility:MousePosition(Offset)
        if Offset then
            return UserInputService:GetMouseLocation() + Atlanta:CursorOffset()
        else
            return UserInputService:GetMouseLocation()
        end
    end
    --
    function Utility:Console(Action, ...)
        if not Atlanta.Safe then
            Action(...)
        end
    end
end

do
    local lib = Library:New({Name = 'Cypher - (' .. game:GetService('Players').LocalPlayer.UserId .. ')', style = 1})
    
    local rage2 = lib:Page({name = "Rage"})
    local visuals = lib:Page({name = "Visuals"})
    local players = lib:Page({name = "Players"})
    local misc = lib:Page({name = "Misc"})
    local config = lib:Page({name = "Config"})
    
do -- Rage
    local rage = rage2:Section({name = "Rage"})
    rage:RiskToggle({Name = "Enabled", Callback = function(state) settings.combat.silentAim = state end})
    rage:Dropdown({Name = "Target hitbox", Callback = function(state) settings.combat.hitPart = state end, Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", "LeftLowerLeg",  "LeftUpperLeg", "RightLowerLeg", "RightFoot",  "RightUpperLeg"}, Default = "Head"})
    rage:Slider({Name = "Field of view", Callback = function(state) settings.combat.fovCircle.radius = state end, Decimals = 0.1, Min = 0, Max = 360, Default = 360})
    rage:Toggle({Name = "Automatic fire", Callback = function(state) settings.combat.triggerBot = state end})
    rage:Slider({Name = "Automatic fire delay", Callback = function(state) settings.combat.triggerBotDelay = state end, Decimals = 0.01, Min = 0, Max = 1, Default = 0.1, suffix = "ms"})
    rage:Slider({Name = "Max distance", Callback = function(state) settings.combat.maxDist = state end, Decimals = 1, Min = 0, Max = 5000, Default = 360, suffix = "st"})
    --
    local mods = rage2:Section({Name = "Other", side = "right"})
    --mods:Toggle({Name = "Automatic", Callback = function(state) settings.combat.automatic = state end, Risk = true})
    mods:RiskToggle({Name = "Infinite ammo", Callback = function(state) settings.combat.infiniteAmmo = state end})
    mods:RiskToggle({Name = "Rapid fire", Callback = function(state) settings.combat.rapidFire = state end})
    mods:RiskToggle({Name = "Melee exploits", Callback = function(state) settings.combat.meelerange = state end})
    mods:Toggle({Name = "Instant reload", Callback = function(state) settings.combat.instantreload = state end})
    mods:Toggle({Name = "Remove spread", Callback = function(state) settings.combat.noSpread = state end})
    mods:Toggle({Name = "Remove recoil", Callback = function(state) settings.combat.noRecoil = state end})
    mods:RiskToggle({Name = "Instant equip", Callback = function(state) settings.combat.instantequip = state end})


    local cfg = rage2:Section({Name = "FOV"})
    cfg:Toggle({Name = "Draw FOV", Callback = function(state) settings.combat.fovCircle.enabled = state end})
    :Colorpicker({Name = "Color", Callback = function(color) settings.combat.fovCircle.color = color end, Default = Color3.fromRGB(255,255,255)})
    cfg:Slider({Name = "Thickness", Callback = function(state) settings.combat.fovCircle.thickness = state end, Decimals = 1, Min = 0, Max = 100, Default = 1})
    cfg:Slider({Name = "Transparency", Callback = function(state) settings.combat.fovCircle.transparency = state end, Decimals = 0.01, Min = 0, Max = 1, Default = 1})
end

do -- Players
    local esp = players:Section({name = "Enemies"})
    esp:Toggle({Name = "Enabled", Callback = function(state) Settings.Enabled = state end})

    esp:Slider({Name = "Max distance", Callback = function(state) Settings["MaxDistance"] = state end, Decimals = 1, Min = 1, Max = 2000, Default = 1200})

    esp:Toggle({Name = "Name", Callback = function(state) Settings["Name"][1] = state end})
    :Colorpicker({Name = "Name color", Callback = function(color) Settings["Name"][2] = color end, Default = Color3.fromRGB(255,255,255)})


    esp:Toggle({Name = "Bounding box", Callback = function(state) Settings.Box[1] = state end})
    :Colorpicker({Name = "Box color", Callback = function(color) Settings.Box[3] = color end, Default = Color3.fromRGB(255,255,255)})
    esp:Dropdown({Name = "Box type", Callback = function(Option) Settings.Box[2] = Option  end, Options = {"Corner", "Box"}, Default = "Box"})

    esp:Toggle({Name = "Bounding box fill", Callback = function(state)  Settings["BoxFill"][1] = state end})
    :Colorpicker({Name = "Box fill color", Callback = function(color) Settings["BoxFill"][2] = color end, Default = Color3.fromRGB(255,255,255)})
    

    esp:Toggle({Name = "Distance", Callback = function(state) Settings["Distance"][1] = state end})
    :Colorpicker({Name = "Distance color", Callback = function(color) Settings["Distance"][2] = color end, Default = Color3.fromRGB(255,255,255)})

    esp:Toggle({Name = "Weapon", Callback = function(state) Settings["Weapon"][1] = state end})
    :Colorpicker({Name = "Weapon color", Callback = function(color) Settings["Weapon"][2] = color end, Default = Color3.fromRGB(255,255,255)})

    esp:Toggle({Name = "Flags", Callback = function(state) Settings["Flag"][1] = state end})
    :Colorpicker({Name = "Flags color", Callback = function(color) Settings["Flag"][2] = color end, Default = Color3.fromRGB(225,225,225)})

    esp:Toggle({Name = "Moving flag", Callback = function(state) Settings["Moving"][1] = state end})
    esp:Toggle({Name = "Jumping flag", Callback = function(state) Settings["Jumping"][1] = state end})

    local healthbar = esp:Toggle({Name = "Health bar", Callback = function(state) Settings["HealthBar"][1] = state end})
    healthbar:Colorpicker({Name = "1 color", Callback = function(color) Settings["HealthBar"][1] = color end, Default = Color3.fromRGB(0,255,0)})
    healthbar:Colorpicker({Name = "2 color", Callback = function(color) Settings["HealthBar"][2] = color end, Default = Color3.fromRGB(255,0,0)})
    esp:Toggle({Name = "Health text", Callback = function(state) Settings["HealthNumber"][1] = state end})

    local setts = players:Section({name = "Settings", side = "right"})
    setts:Slider({Name = "Fade time", Callback = function(state) Settings["FadeTime"] = state end, Decimals = 0.1, Min = 1, Max = 10, Default = 2, suffix = "s"})
    setts:Dropdown({Name = "Text case", Callback = function(Option) Settings.TextCase = Option  end, Options = {"Normal", "UPPERCASE", "lowercase"}, Default = "Normal"})
    setts:Slider({Name = "Text length", Callback = function(state) Settings["TextLength"] = state end, Decimals = 0.1, Min = 3, Max = 24, Default = 2, suffix = "l"})
    setts:Slider({Name = "Box fill transparency", Callback = function(state) Settings["BoxFill"][3] = state end, Decimals = 0.01, Min = 0, Max = 1, Default = 0.6, suffix = "t"})


end




    local menu = config:Section({name = "Menu"})
    local theme = config:Section({name = "Theme"})

    theme:Dropdown({Name = "Theme", Flag = "ConfigTheme_Theme", Default = "Default", Max = 8, Options = {"Default", "Abyss", "Fatality", "Neverlose", "Aimware", "Youtube", "Gamesense", "Onetap", "Entropy", "Interwebz", "Dracula", "Spotify", "Vape", "Neko", "Corn", "Minecraft"}, Callback = function(callback)
        if callback == "Default" then
            Library:UpdateColor("Accent", Color3.fromRGB(189, 182, 240))
            Library:UpdateColor("LightContrast", Color3.fromRGB(30, 30, 30))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(25, 25, 25))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(50, 50, 50))
        elseif callback == "Abyss" then
            Library:UpdateColor("Accent", Color3.fromRGB(140, 135, 180))
            Library:UpdateColor("LightContrast", Color3.fromRGB(30, 30, 30))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(20, 20, 20))
            Library:UpdateColor("Outline", Color3.fromRGB(10, 10, 10))
            Library:UpdateColor("Inline", Color3.fromRGB(45, 45, 45))
        elseif callback == "Fatality" then
            Library:UpdateColor("Accent", Color3.fromRGB(240, 15, 80))
            Library:UpdateColor("LightContrast", Color3.fromRGB(35, 25, 70))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(25, 20, 50))
            Library:UpdateColor("Outline", Color3.fromRGB(15, 15, 40))
            Library:UpdateColor("Inline", Color3.fromRGB(50, 40, 80))
        elseif callback == "Neverlose" then
            Library:UpdateColor("Accent", Color3.fromRGB(0, 180, 240))
            Library:UpdateColor("LightContrast", Color3.fromRGB(0, 15, 30))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(5, 5, 20))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 5))
            Library:UpdateColor("Inline", Color3.fromRGB(10, 30, 40))
        elseif callback == "Aimware" then
            Library:UpdateColor("Accent", Color3.fromRGB(200, 40, 40))
            Library:UpdateColor("LightContrast", Color3.fromRGB(43, 43, 43))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(25, 25, 25))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 5))
            Library:UpdateColor("Inline", Color3.fromRGB(55, 55, 55))            
        elseif callback == "Youtube" then
            Library:UpdateColor("Accent", Color3.fromRGB(255, 0, 0))
            Library:UpdateColor("LightContrast", Color3.fromRGB(35, 35, 35))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(15, 15, 15))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(57, 57, 57))            
        elseif callback == "Gamesense" then
            Library:UpdateColor("Accent", Color3.fromRGB(167, 217, 77))
            Library:UpdateColor("LightContrast", Color3.fromRGB(23, 23, 23))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(12, 12, 12))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(40, 40, 40))
        elseif callback == "Onetap" then
            Library:UpdateColor("Accent", Color3.fromRGB(221, 168, 93))
            Library:UpdateColor("LightContrast", Color3.fromRGB(44, 48, 55))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(31, 33, 37))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(78, 81, 88))
        elseif callback == "Entropy" then
            Library:UpdateColor("Accent", Color3.fromRGB(129, 187, 233))
            Library:UpdateColor("LightContrast", Color3.fromRGB(61, 58, 67))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(48, 47, 55))
            Library:UpdateColor("Outline", Color3.fromRGB(10, 10, 10))
            Library:UpdateColor("Inline", Color3.fromRGB(76, 74, 82))
        elseif callback == "Interwebz" then
            Library:UpdateColor("Accent", Color3.fromRGB(201, 101, 75))
            Library:UpdateColor("LightContrast", Color3.fromRGB(41, 31, 56))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(31, 22, 43))
            Library:UpdateColor("Outline", Color3.fromRGB(26, 26, 26))
            Library:UpdateColor("Inline", Color3.fromRGB(64, 54, 79))
        elseif callback == "Dracula" then
            Library:UpdateColor("Accent", Color3.fromRGB(154, 129, 179))
            Library:UpdateColor("LightContrast", Color3.fromRGB(42, 44, 56))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(37, 39, 48))
            Library:UpdateColor("Outline", Color3.fromRGB(32, 33, 38))
            Library:UpdateColor("Inline", Color3.fromRGB(60, 56, 77))
        elseif callback == "Spotify" then
            Library:UpdateColor("Accent", Color3.fromRGB(30, 215, 96))
            Library:UpdateColor("LightContrast", Color3.fromRGB(24, 24, 24))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(18, 18, 18))
            Library:UpdateColor("Outline", Color3.fromRGB(10, 10, 10))
            Library:UpdateColor("Inline", Color3.fromRGB(41, 41, 41))
        elseif callback == "Vape" then
            Library:UpdateColor("Accent", Color3.fromRGB(38, 134, 106))
            Library:UpdateColor("LightContrast", Color3.fromRGB(31, 31, 31))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(26, 26, 26))
            Library:UpdateColor("Outline", Color3.fromRGB(10, 10, 10))
            Library:UpdateColor("Inline", Color3.fromRGB(54, 54, 54))
        elseif callback == "Neko" then
            Library:UpdateColor("Accent", Color3.fromRGB(210, 31, 106))
            Library:UpdateColor("LightContrast", Color3.fromRGB(23, 23, 23))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(19, 19, 19))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(45, 45, 45))
        elseif callback == "Corn" then
            Library:UpdateColor("Accent", Color3.fromRGB(255, 144, 0))
            Library:UpdateColor("LightContrast", Color3.fromRGB(37, 37, 37))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(25, 25, 25))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(51, 51, 51))
            
        elseif callback == "Minecraft" then
            Library:UpdateColor("Accent", Color3.fromRGB(39, 206, 64))
            Library:UpdateColor("LightContrast", Color3.fromRGB(51, 51, 51))
            Library:UpdateColor("DarkContrast", Color3.fromRGB(38, 38, 38))
            Library:UpdateColor("Outline", Color3.fromRGB(0, 0, 0))
            Library:UpdateColor("Inline", Color3.fromRGB(51, 51, 51))
            
        end
    end
})
    theme:Colorpicker({name = "Accent", Default = Color3.fromRGB(93, 62, 152), Callback = function(Color) Library:UpdateColor("Accent", Color) end})
    theme:Colorpicker({name = "Light Contrast", Default = Color3.fromRGB(30, 30, 30), Callback = function(Color) Library:UpdateColor("LightContrast", Color) end})
    theme:Colorpicker({name = "Dark Contrast", Default = Color3.fromRGB(20, 20, 20), Callback = function(Color) Library:UpdateColor("DarkContrast", Color) end})
    theme:Colorpicker({name = "Outline", Default = Color3.fromRGB(0, 0, 0), Callback = function(Color) Library:UpdateColor("Outline", Color) end})
    theme:Colorpicker({name = "Inline", Default = Color3.fromRGB(50, 50, 50), Callback = function(Color) Library:UpdateColor("Inline", Color) end})
    theme:Colorpicker({name = "Light Text", Default = Color3.fromRGB(255, 255, 255), Callback = function(Color) Library:UpdateColor("TextColor", Color) end})
    theme:Colorpicker({name = "Risk Text", Default = Color3.fromRGB(255, 255, 255), Callback = function(Color) Library:UpdateColor("RiskTextColor", Color) end})
    theme:Colorpicker({name = "Dark Text", Default = Color3.fromRGB(175, 175, 175), Callback = function(Color) Library:UpdateColor("TextDark", Color) end})
    theme:Colorpicker({name = "Text Outline", Default = Color3.fromRGB(0, 0, 0), Callback = function(Color) Library:UpdateColor("TextBorder", Color) end})
    theme:Colorpicker({name = "Cursor Outline", Default = Color3.fromRGB(10, 10, 10), Callback = function(Color) Library:UpdateColor("CursorOutline", Color) end})




    
    lib:Initialize()

end
