local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Fluent " .. Fluent.Version,
    SubTitle = "by dawid",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "target" })
}

local Options = Fluent.Options

local levelsFolder = workspace.Levels
local buttonModels = {}

for _, levelFolder in pairs(levelsFolder:GetChildren()) do
    local buttonModel = levelFolder:FindFirstChild("ButtonModel")
    if buttonModel then
        table.insert(buttonModels, buttonModel)
    end
end

do
    Fluent:Notify({
        Title = "Notification",
        Content = "This is a notification",
        SubContent = "SubContent", -- Optional
        Duration = 5 -- Set to nil to make the notification not disappear
    })



    Tabs.Main:AddParagraph({
        Title = "Paragraph",
        Content = "This is a paragraph.\nSecond line!"
    })



    Tabs.Main:AddButton({
        Title = "Button",
        Description = "Very important button",
        Callback = function()
            Window:Dialog({
                Title = "Title",
                Content = "This is a dialog",
                Buttons = {
                    {
                        Title = "Confirm",
                        Callback = function()
                            print("Confirmed the dialog.")
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            print("Cancelled the dialog.")
                        end
                    }
                }
            })
        end
    })

    Tabs.ESP:AddButton({
        Title = "ESP Button",
        Description = "hmmm",
        Callback = function()
            Window:Dialog({
                Title = "You sure?",
                Content = "just checkin",
                Buttons = {
                    {
                        Title = "Enable",
                        Callback = function()
                            for i, btn in pairs(buttonModels) do
                                print(i, btn:GetFullName())
                                
                                -- Add highlight ESP
                                local highlight = Instance.new("Highlight")
                                highlight.FillColor = Color3.new(0, 1, 0) -- Green
                                highlight.OutlineColor = Color3.new(1, 1, 1) -- White outline
                                highlight.Parent = btn
                            end
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            print("Cancelled the dialog.")
                        end
                    }
                }
            })
        end
    })

    local levelNames = {}
for _, levelFolder in pairs(levelsFolder:GetChildren()) do
    if levelFolder:FindFirstChild("ButtonModel") then
        table.insert(levelNames, "Level " .. levelFolder.Name)
    end
end

table.sort(levelNames, function(a, b)
    local numA = tonumber(a:match("Level (%d+)")) or 0
    local numB = tonumber(b:match("Level (%d+)")) or 0
    return numA < numB
end)

-- Toggle for walk vs teleport
local WalkToggle = Tabs.ESP:AddToggle("WalkMode", {
    Title = "Walk to Button", 
    Description = "Enable to walk, disable to teleport",
    Default = false 
})

local TeleportDropdown = Tabs.ESP:AddDropdown("TeleportDropdown", {
    Title = "Go to Level",
    Description = "Select a level to go to its button",
    Values = levelNames,
    Multi = false,
    Default = 1,
})

TeleportDropdown:OnChanged(function(Value)
    local levelNum = Value:match("Level (%S+)")
    local targetButton = nil
    
    for _, levelFolder in pairs(levelsFolder:GetChildren()) do
        if levelFolder.Name == levelNum then
            targetButton = levelFolder:FindFirstChild("ButtonModel")
            break
        end
    end
    
    if targetButton then
        local targetCFrame = nil
        
        -- Try to get CFrame from PrimaryPart or first part found
        if targetButton.PrimaryPart then
            targetCFrame = targetButton.PrimaryPart.CFrame
        else
            -- Find any part in the model
            for _, child in pairs(targetButton:GetChildren()) do
                if child:IsA("BasePart") then
                    targetCFrame = child.CFrame
                    break
                end
            end
        end
        
        if targetCFrame then
            local player = game.Players.LocalPlayer
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and rootPart then
                -- Check if walk mode is enabled
                if Options.WalkMode.Value then
                    -- Use pathfinding to walk to the button
                    local pathfindingService = game:GetService("PathfindingService")
                    local path = pathfindingService:CreatePath()
                    
                    local success, errorMessage = pcall(function()
                        path:ComputeAsync(rootPart.Position, targetCFrame.Position)
                    end)
                    
                    if success and path.Status == Enum.PathStatus.Success then
                        local waypoints = path:GetWaypoints()
                        
                        Fluent:Notify({
                            Title = "Walking",
                            Content = "Walking to " .. Value,
                            Duration = 2
                        })
                        
                        for _, waypoint in pairs(waypoints) do
                            humanoid:MoveTo(waypoint.Position)
                            humanoid.MoveToFinished:Wait()
                        end
                        
                        Fluent:Notify({
                            Title = "Arrived",
                            Content = "Walked to " .. Value,
                            Duration = 2
                        })
                    else
                        -- Fallback to teleport if pathfinding fails
                        rootPart.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                        Fluent:Notify({
                            Title = "Teleported",
                            Content = "Pathfinding failed, teleported to " .. Value,
                            Duration = 2
                        })
                    end
                else
                    -- Teleport mode
                    rootPart.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                    Fluent:Notify({
                        Title = "Teleported",
                        Content = "Teleported to " .. Value,
                        Duration = 2
                    })
                end
            end
        end
    end
end)



    local Toggle = Tabs.Main:AddToggle("MyToggle", {Title = "Toggle", Default = false })

    Toggle:OnChanged(function()
        print("Toggle changed:", Options.MyToggle.Value)
    end)

    Options.MyToggle:SetValue(false)


    
    local Slider = Tabs.Main:AddSlider("Slider", {
        Title = "Slider",
        Description = "This is a slider",
        Default = 2,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(Value)
            print("Slider was changed:", Value)
        end
    })

    Slider:OnChanged(function(Value)
        print("Slider changed:", Value)
    end)

    Slider:SetValue(3)



    local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
        Title = "Dropdown",
        Values = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"},
        Multi = false,
        Default = 1,
    })

    Dropdown:SetValue("four")

    Dropdown:OnChanged(function(Value)
        print("Dropdown changed:", Value)
    end)


    
    local MultiDropdown = Tabs.Main:AddDropdown("MultiDropdown", {
        Title = "Dropdown",
        Description = "You can select multiple values.",
        Values = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"},
        Multi = true,
        Default = {"seven", "twelve"},
    })

    MultiDropdown:SetValue({
        three = true,
        five = true,
        seven = false
    })

    MultiDropdown:OnChanged(function(Value)
        local Values = {}
        for Value, State in next, Value do
            table.insert(Values, Value)
        end
        print("Mutlidropdown changed:", table.concat(Values, ", "))
    end)



    local Colorpicker = Tabs.Main:AddColorpicker("Colorpicker", {
        Title = "Colorpicker",
        Default = Color3.fromRGB(96, 205, 255)
    })

    Colorpicker:OnChanged(function()
        print("Colorpicker changed:", Colorpicker.Value)
    end)
    
    Colorpicker:SetValueRGB(Color3.fromRGB(0, 255, 140))



    local TColorpicker = Tabs.Main:AddColorpicker("TransparencyColorpicker", {
        Title = "Colorpicker",
        Description = "but you can change the transparency.",
        Transparency = 0,
        Default = Color3.fromRGB(96, 205, 255)
    })

    TColorpicker:OnChanged(function()
        print(
            "TColorpicker changed:", TColorpicker.Value,
            "Transparency:", TColorpicker.Transparency
        )
    end)



    local Keybind = Tabs.Main:AddKeybind("Keybind", {
        Title = "KeyBind",
        Mode = "Toggle", -- Always, Toggle, Hold
        Default = "LeftControl", -- String as the name of the keybind (MB1, MB2 for mouse buttons)

        -- Occurs when the keybind is clicked, Value is `true`/`false`
        Callback = function(Value)
            print("Keybind clicked!", Value)
        end,

        -- Occurs when the keybind itself is changed, `New` is a KeyCode Enum OR a UserInputType Enum
        ChangedCallback = function(New)
            print("Keybind changed!", New)
        end
    })

    -- OnClick is only fired when you press the keybind and the mode is Toggle
    -- Otherwise, you will have to use Keybind:GetState()
    Keybind:OnClick(function()
        print("Keybind clicked:", Keybind:GetState())
    end)

    Keybind:OnChanged(function()
        print("Keybind changed:", Keybind.Value)
    end)

    task.spawn(function()
        while true do
            wait(1)

            -- example for checking if a keybind is being pressed
            local state = Keybind:GetState()
            if state then
                print("Keybind is being held down")
            end

            if Fluent.Unloaded then break end
        end
    end)

    Keybind:SetValue("MB2", "Toggle") -- Sets keybind to MB2, mode to Hold


    local Input = Tabs.Main:AddInput("Input", {
        Title = "Input",
        Default = "Default",
        Placeholder = "Placeholder",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            print("Input changed:", Value)
        end
    })

    Input:OnChanged(function()
        print("Input updated:", Input.Value)
    end)
end


-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
