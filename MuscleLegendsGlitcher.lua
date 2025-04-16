local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Инициализация интерфейса Fluent UI с оптимизацией
local Window = Fluent:CreateWindow({
    Title = "Muscle Legends Trainer " .. Fluent.Version,
    SubTitle = "by Fluent",
    TabWidth = 160,
    Size = UDim2.fromOffset(700, 500),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Проверка успешной инициализации окна
if not Window then
    warn("Не удалось создать окно Fluent UI. Проверьте подключение к библиотеке.")
    return
end

-- Создание вкладок
local Tabs = {
    Auto = Window:AddTab({ Title = "Auto", Icon = "zap" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Eggs = Window:AddTab({ Title = "Eggs", Icon = "egg" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart-2" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Проверка создания вкладок
for tabName, tab in pairs(Tabs) do
    if not tab then
        warn("Вкладка " .. tabName .. " не создана. Проверьте библиотеку Fluent.")
    end
end

local Options = Fluent.Options

-- Механизм debounce для уведомлений
local lastNotification = 0
local notificationCooldown = 5

local function notifyWithDebounce(title, content, duration)
    local currentTime = tick()
    if currentTime - lastNotification >= notificationCooldown then
        Fluent:Notify({
            Title = title,
            Content = content,
            Duration = duration
        })
        lastNotification = currentTime
    end
end

-- Уведомление о загрузке
notifyWithDebounce("Muscle Legends Trainer", "Скрипт успешно загружен.", 5)

-- Переменные для автопрокачки, ребирта и открытия кристаллов
local autoMuscleEnabled = false
local autoRebirthEnabled = false
local autoCrystalEnabled = false
local savePositionEnabled = true
local savedPosition = nil
local selectedCrystal = "Blue Crystal"

-- Список кристаллов
local crystals = {
    "Blue Crystal",
    "Green Crystal",
    "Inferno Crystal",
    "Galaxy Oracle Crystal",
    "Muscle Elite Crystal",
    "Jungle Crystal",
    "Mythical Crystal",
    "Legends Crystal",
    "Frost Crystal"
}

-- Координаты сундуков
local chests = {
    {-140, 7, -276},
    {-2571, 7, -551},
    {2209, 7, 914},
    {-6711, 7, -1458},
    {4672, 1001, -3693},
    {-7912, 4, 3021}
}

-- Функция прокачки силы
local function boostStrength()
    local success, err = pcall(function()
        local args = { "rep" }
        LocalPlayer:WaitForChild("muscleEvent", 5):FireServer(unpack(args))
    end)
    if not success then
        notifyWithDebounce("Ошибка", "Не удалось прокачать силу: " .. tostring(err), 5)
        return false
    end
    return true
end

-- Функция для ребирта с сохранением позиции и телепортацией на 8 секунд
local function requestRebirth()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        savedPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
        notifyWithDebounce("Позиция сохранена", "Ваша позиция сохранена для телепортации после ребирта.", 3)
    end
    local args = { "rebirthRequest" }
    game:GetService("ReplicatedStorage"):WaitForChild("rEvents"):WaitForChild("rebirthRemote"):InvokeServer(unpack(args))
    
    local teleportStartTime = tick()
    task.spawn(function()
        while savedPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (tick() - teleportStartTime) <= 8 do
            task.wait(0.1)
            LocalPlayer.Character.HumanoidRootPart.CFrame = savedPosition
            notifyWithDebounce("Телепортация", "Вы телепортированы на сохранённую позицию.", 3)
        end
        if (tick() - teleportStartTime) > 8 then
            notifyWithDebounce("Телепортация завершена", "Телепортация на сохранённую позицию остановлена после 8 секунд.", 3)
            savedPosition = nil
        end
    end)
    return true
end

-- Функция открытия кристалла
local function openCrystal(crystalName)
    local args = {
        [1] = "openCrystal",
        [2] = crystalName
    }
    game:GetService("ReplicatedStorage"):WaitForChild("rEvents"):WaitForChild("openCrystalRemote"):InvokeServer(unpack(args))
    return true
end

-- Создание платформы
task.spawn(function()
    task.wait(5)
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(500, 5, 500)
    platform.Position = Vector3.new(13486, 537, -2184)
    platform.Anchored = true
    platform.Material = Enum.Material.Plastic
    platform.BrickColor = BrickColor.new("Bright blue")
    platform.Parent = game.Workspace
    notifyWithDebounce("Платформа", "Платформа создана на координатах (13486, 537, -2184) с размером 500x5x500.", 3)
end)

-- Функция телепортации
local function teleportToPosition(x, y, z)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
    else
        notifyWithDebounce("Ошибка", "Персонаж не найден. Попробуйте снова.", 3)
    end
end

-- Функция для телепортации ко всем сундукам
local function claimAllChests()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        notifyWithDebounce("Ошибка", "Персонаж не найден. Невозможно начать телепортацию.", 3)
        return
    end
    local startPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    notifyWithDebounce("Начало", "Телепортация ко всем сундукам началась.", 3)
    
    for i, chest in ipairs(chests) do
        task.wait(0.5)
        teleportToPosition(chest[1], chest[2], chest[3])
        notifyWithDebounce("Сундук " .. i, "Телепортирован к сундуку " .. i .. ".", 3)
    end
    
    task.wait(0.5)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = startPosition
        notifyWithDebounce("Завершение", "Возвращён на исходную позицию.", 3)
    else
        notifyWithDebounce("Ошибка", "Не удалось вернуться на исходную позицию.", 3)
    end
end

-- Категория Auto
task.spawn(function()
    task.wait(0)
    Tabs.Auto:AddParagraph({
        Title = "Автоматическая прокачка",
        Content = "Включайте авто-прокачку силы и ребирты для быстрого прогресса."
    })

    local AutoMuscleToggle = Tabs.Auto:AddToggle("AutoMuscleToggle", {
        Title = "Авто-прокачка силы",
        Description = "Включает автоматическую прокачку силы",
        Default = false
    })

    AutoMuscleToggle:OnChanged(function()
        autoMuscleEnabled = Options.AutoMuscleToggle.Value
        if autoMuscleEnabled then
            task.spawn(function()
                while autoMuscleEnabled do
                    task.wait(0.5)
                    boostStrength()
                end
            end)
            notifyWithDebounce("Авто-прокачка силы", "Включено. Прокачка началась.", 3)
        else
            notifyWithDebounce("Авто-прокачка силы", "Отключено.", 2)
        end
    end)

    local AutoRebirthToggle = Tabs.Auto:AddToggle("AutoRebirthToggle", {
        Title = "Авто-ребирт",
        Description = "Включает автоматические ребирты",
        Default = false
    })

    AutoRebirthToggle:OnChanged(function()
        autoRebirthEnabled = Options.AutoRebirthToggle.Value
        if autoRebirthEnabled then
            task.spawn(function()
                while autoRebirthEnabled do
                    task.wait(1)
                    requestRebirth()
                end
            end)
            notifyWithDebounce("Авто-ребирт", "Включено. Ребирты начались.", 3)
        else
            notifyWithDebounce("Авто-ребирт", "Отключено.", 2)
        end
    end)
end)

-- Категория Teleport
task.spawn(function()
    task.wait(1)
    Tabs.Teleport:AddParagraph({
        Title = "Телепортация",
        Content = "Выберите локацию для телепортации."
    })

    Tabs.Teleport:AddButton({
        Title = "Beach",
        Description = "Телепортация на (6, 7, 314)",
        Callback = function()
            teleportToPosition(6, 7, 314)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Frost Gym",
        Description = "Телепортация на (-2623, 7, -409)",
        Callback = function()
            teleportToPosition(-2623, 7, -409)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Mythical Gym",
        Description = "Телепортация на (2251, 7, 1073)",
        Callback = function()
            teleportToPosition(2251, 7, 1073)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Eternal Gym",
        Description = "Телепортация на (-6759, 7, -1285)",
        Callback = function()
            teleportToPosition(-6759, 7, -1285)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Legends Gym",
        Description = "Телепортация на (4603, 992, -3898)",
        Callback = function()
            teleportToPosition(4603, 992, -3898)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "King Gym",
        Description = "Телепортация на (-8626, 17, -5730)",
        Callback = function()
            teleportToPosition(-8626, 17, -5730)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Event",
        Description = "Телепортация на (-8646, 7, 2396)",
        Callback = function()
            teleportToPosition(-8646, 7, 2396)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Безопасная Зона",
        Description = "Телепортация в безопасную зону!",
        Callback = function()
            teleportToPosition(13486, 550, -2184)
        end
    })

    Tabs.Teleport:AddButton({
        Title = "Claim All Chest",
        Description = "Телепортирует ко всем сундукам по очереди и возвращает обратно.",
        Callback = function()
            claimAllChests()
        end
    })
end)

-- Категория Eggs
task.spawn(function()
    task.wait(2)
    Tabs.Eggs:AddParagraph({
        Title = "Открытие кристаллов",
        Content = "Выберите кристалл для открытия."
    })

    local CrystalDropdown = Tabs.Eggs:AddDropdown("CrystalDropdown", {
        Title = "Выбор кристалла",
        Description = "Выберите кристалл для открытия:\nBlue Crystal - 1K Валюты\nGreen Crystal - 3K Валюты\nInferno Crystal - 15K Валюты\nGalaxy Oracle Crystal - 1.5M Валюты\nMuscle Elite Crystal - 1M Валюты\nJungle Crystal - 3M Валюты\nMythical Crystal - 8K Валюты\nLegends Crystal - 30K Валюты\nFrost Crystal - 5K Валюты",
        Values = crystals,
        Default = 1
    })

    CrystalDropdown:OnChanged(function()
        selectedCrystal = Options.CrystalDropdown.Value
    end)

    Tabs.Eggs:AddButton({
        Title = "Открыть кристалл",
        Description = "Открывает выбранный кристалл",
        Callback = function()
            openCrystal(selectedCrystal)
        end
    })

    local AutoCrystalToggle = Tabs.Eggs:AddToggle("AutoCrystalToggle", {
        Title = "Авто-открытие кристаллов",
        Description = "Включает автоматическое открытие выбранного кристалла",
        Default = false
    })

    AutoCrystalToggle:OnChanged(function()
        autoCrystalEnabled = Options.AutoCrystalToggle.Value
        if autoCrystalEnabled then
            task.spawn(function()
                while autoCrystalEnabled do
                    task.wait(1)
                    openCrystal(selectedCrystal)
                end
            end)
        end
    end)
end)

-- Категория Stats
task.spawn(function()
    task.wait(3)
    Tabs.Stats:AddParagraph({
        Title = "Статистика игрока",
        Content = "Отображает текущую статистику вашего персонажа."
    })

    local statsKillsLabel = Tabs.Stats:AddParagraph({ Title = "Убийства", Content = "Загрузка..." })
    local statsRebirthsLabel = Tabs.Stats:AddParagraph({ Title = "Перерождения", Content = "Загрузка..." })
    local statsStrengthLabel = Tabs.Stats:AddParagraph({ Title = "Сила", Content = "Загрузка..." })
    local statsAgilityLabel = Tabs.Stats:AddParagraph({ Title = "Скорость", Content = "Загрузка..." })
    local statsDurabilityLabel = Tabs.Stats:AddParagraph({ Title = "Долговечность", Content = "Загрузка..." })
    local statsGemsLabel = Tabs.Stats:AddParagraph({ Title = "Гемы", Content = "Загрузка..." })

    local function updateStats(kills, rebirths, strength, agility, durability, gems, errorMessage)
        if errorMessage then
            statsKillsLabel:Set({ Title = "Убийства", Content = "Ошибка: " .. errorMessage })
            statsRebirthsLabel:Set({ Title = "Перерождения", Content = "Ошибка: " .. errorMessage })
            statsStrengthLabel:Set({ Title = "Сила", Content = "Ошибка: " .. errorMessage })
            statsAgilityLabel:Set({ Title = "Скорость", Content = "Ошибка: " .. errorMessage })
            statsDurabilityLabel:Set({ Title = "Долговечность", Content = "Ошибка: " .. errorMessage })
            statsGemsLabel:Set({ Title = "Гемы", Content = "Ошибка: " .. errorMessage })
        else
            statsKillsLabel:Set({ Title = "Убийства", Content = kills and tostring(kills) or "N/A" })
            statsRebirthsLabel:Set({ Title = "Перерождения", Content = rebirths and tostring(rebirths) or "N/A" })
            statsStrengthLabel:Set({ Title = "Сила", Content = strength and tostring(strength) or "N/A" })
            statsAgilityLabel:Set({ Title = "Скорость", Content = agility and tostring(agility) or "N/A" })
            statsDurabilityLabel:Set({ Title = "Долговечность", Content = durability and tostring(durability) or "N/A" })
            statsGemsLabel:Set({ Title = "Гемы", Content = gems and tostring(gems) or "N/A" })
        end
    end

    task.spawn(function()
        local maxAttempts = 5
        local attempt = 0
        local leaderstats, agility, durability, gems

        while attempt < maxAttempts do
            local success, err = pcall(function()
                if not LocalPlayer then
                    error("LocalPlayer не найден")
                end
                leaderstats = LocalPlayer:WaitForChild("leaderstats", 15)
                if not leaderstats then
                    error("leaderstats не найден")
                end
                local kills = leaderstats:FindFirstChild("Kills")
                local rebirths = leaderstats:FindFirstChild("Rebirths")
                local strength = leaderstats:FindFirstChild("Strength")
                agility = LocalPlayer:WaitForChild("Agility", 15)
                durability = LocalPlayer:WaitForChild("Durability", 15)
                gems = LocalPlayer:WaitForChild("Gems", 15)

                if not kills then error("Kills не найден в leaderstats") end
                if not rebirths then error("Rebirths не найден в leaderstats") end
                if not strength then error("Strength не найден в leaderstats") end
                if not agility then error("Agility не найден") end
                if not durability then error("Durability не найден") end
                if not gems then error("Gems не найден") end
            end)

            if success and leaderstats and agility and durability and gems then
                updateStats(
                    leaderstats.Kills.Value,
                    leaderstats.Rebirths.Value,
                    leaderstats.Strength.Value,
                    agility.Value,
                    durability.Value,
                    gems.Value,
                    nil
                )
                while true do
                    task.wait(10)
                    local successUpdate, errUpdate = pcall(function()
                        updateStats(
                            leaderstats.Kills.Value,
                            leaderstats.Rebirths.Value,
                            leaderstats.Strength.Value,
                            agility.Value,
                            durability.Value,
                            gems.Value,
                            nil
                        )
                    end)
                    if not successUpdate then
                        updateStats(nil, nil, nil, nil, nil, nil, "Ошибка обновления: " .. errUpdate)
                        break
                    end
                end
            else
                attempt = attempt + 1
                task.wait(2) -- Пауза перед следующей попыткой
                if attempt == maxAttempts then
                    updateStats(nil, nil, nil, nil, nil, nil, err or "Не удалось загрузить статистику после " .. maxAttempts .. " попыток")
                    notifyWithDebounce("Ошибка", "Не удалось загрузить статистику: " .. (err or "Таймаут") .. ". Проверьте подключение или перезапустите скрипт.", 5)
                end
            end
        end
    end)
end)

-- Категория Visual
task.spawn(function()
    task.wait(4)
    Tabs.Visual:AddParagraph({
        Title = "Визуальное изменение характеристик",
        Content = "Измените значения характеристик (только визуально, на стороне клиента)."
    })

    Tabs.Visual:AddInput("VisualStrength", {
        Title = "Сила",
        Description = "Введите новое значение силы (визуально)",
        Default = "0",
        Numeric = true,
        Callback = function(value)
            if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Strength") then
                LocalPlayer.leaderstats.Strength.Value = tonumber(value) or 0
                notifyWithDebounce("Визуальное изменение", "Сила изменена на " .. value, 3)
            else
                notifyWithDebounce("Ошибка", "Не удалось изменить силу.", 3)
            end
        end
    })

    Tabs.Visual:AddInput("VisualAgility", {
        Title = "Скорость",
        Description = "Введите новое значение скорости (визуально)",
        Default = "0",
        Numeric = true,
        Callback = function(value)
            if LocalPlayer:FindFirstChild("Agility") then
                LocalPlayer.Agility.Value = tonumber(value) or 0
                notifyWithDebounce("Визуальное изменение", "Скорость изменена на " .. value, 3)
            else
                notifyWithDebounce("Ошибка", "Не удалось изменить скорость.", 3)
            end
        end
    })

    Tabs.Visual:AddInput("VisualGems", {
        Title = "Гемы",
        Description = "Введите новое значение гемов (визуально)",
        Default = "0",
        Numeric = true,
        Callback = function(value)
            if LocalPlayer:FindFirstChild("Gems") then
                LocalPlayer.Gems.Value = tonumber(value) or 0
                notifyWithDebounce("Визуальное изменение", "Гемы изменены на " .. value, 3)
            else
                notifyWithDebounce("Ошибка", "Не удалось изменить гемы.", 3)
            end
        end
    })

    Tabs.Visual:AddInput("VisualDurability", {
        Title = "Долговечность",
        Description = "Введите новое значение долговечности (визуально)",
        Default = "0",
        Numeric = true,
        Callback = function(value)
            if LocalPlayer:FindFirstChild("Durability") then
                LocalPlayer.Durability.Value = tonumber(value) or 0
                notifyWithDebounce("Визуальное изменение", "Долговечность изменена на " .. value, 3)
            else
                notifyWithDebounce("Ошибка", "Не удалось изменить долговечность.", 3)
            end
        end
    })

    Tabs.Visual:AddInput("VisualRebirths", {
        Title = "Перерождения",
        Description = "Введите новое значение перерождений (визуально)",
        Default = "0",
        Numeric = true,
        Callback = function(value)
            if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Rebirths") then
                LocalPlayer.leaderstats.Rebirths.Value = tonumber(value) or 0
                notifyWithDebounce("Визуальное изменение", "Перерождения изменены на " .. value, 3)
            else
                notifyWithDebounce("Ошибка", "Не удалось изменить перерождения.", 3)
            end
        end
    })
end)

-- Категория Settings
task.spawn(function()
    task.wait(5)
    Tabs.Settings:AddButton({
        Title = "Прокачать силу",
        Description = "Запускает одиночную прокачку силы",
        Callback = function()
            boostStrength()
            notifyWithDebounce("Успех", "Прокачка силы выполнена!", 3)
        end
    })

    Tabs.Settings:AddButton({
        Title = "Запустить ребирт",
        Description = "Запускает одиночный ребирт",
        Callback = function()
            requestRebirth()
            notifyWithDebounce("Успех", "Ребирт выполнен!", 3)
        end
    })

    local SavePositionToggle = Tabs.Settings:AddToggle("SavePositionToggle", {
        Title = "Сохранять позицию при ребирте",
        Description = "Включает сохранение позиции и телепортацию после ребирта",
        Default = true
    })

    SavePositionToggle:OnChanged(function()
        savePositionEnabled = Options.SavePositionToggle.Value
        if savePositionEnabled then
            notifyWithDebounce("Сохранение позиции", "Сохранение позиции включено.", 3)
        else
            savedPosition = nil
            notifyWithDebounce("Сохранение позиции", "Сохранение позиции отключено. Телепортация остановлена.", 2)
        end
    end)
end)

-- Настройка SaveManager и InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("MuscleLegendsTrainer")
SaveManager:SetFolder("MuscleLegendsTrainer/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Активация первой вкладки
Window:SelectTab(1)

-- Автозагрузка конфигурации
SaveManager:LoadAutoloadConfig()
