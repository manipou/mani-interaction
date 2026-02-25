local Config = lib.load('config')

local ScreenW, ScreenH = GetActualScreenResolution()

local GlobalPlayers, InteractionEntities, InteractionPoints = {}, {}, {}

local Keybind, Interaction, RadialOpen

local function Draw3DSprite(Coords, DictName, TxtName)
    SetDrawOrigin(Coords.x, Coords.y, Coords.z)
    if HasStreamedTextureDictLoaded(DictName) then
        DrawInteractiveSprite(DictName, TxtName, 0, 0, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    end
end

local function RadialLoop()
    RadialOpen = true

    CreateThread(function()
        while RadialOpen do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 106, true)
            Wait(0)
        end
    end)
end

local function HandleMultiOption(Options)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SetCursorLocation(0.5, 0.5)
    SendNUIMessage({
        action = 'OpenRadial',
        data = Options
    })

    RadialLoop()
end

local function SelectCurrentOption()
    if RadialOpen then
        SendNUIMessage({
            action = 'selectCurrentOption',
        })
    end
end

local function CloseRadial(UI)
    RadialOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if UI then
        SendNUIMessage({
            action = 'CloseRadial',
        })
    end
end

CreateThread(function()
    local Tick, Dui

    Keybind = lib.addKeybind({
        name = 'Interact',
        description = 'press/hold E to Interact',
        defaultKey = 'E',
        disabled = true,
        onPressed = function(self)
            if Interaction then
                if #Interaction.Options > 1 then
                    HandleMultiOption(Interaction.Options)
                else
                    Interaction.Options[1].action(Interaction)
                end
            end
        end,
        onReleased = function(self)
            if RadialOpen then
                SelectCurrentOption(Interaction)
            end
        end
    })

    while true do
        local PlayerPed = cache.ped
        local PlayerCoords = GetEntityCoords(PlayerPed)

        Interaction = nil

        if next(GlobalPlayers) then
            local NearbyPlayers = lib.getNearbyPlayers(PlayerCoords, Config.MaxDistance, Config.Debug)
            
            if next(NearbyPlayers) then
                for Index, Player in ipairs(NearbyPlayers) do
                    local Coords = Player.coords
                    Player.Distance = #(PlayerCoords - vec3(Coords.x, Coords.y, Coords.z))
                    
                    if not Interaction or Player.Distance < Interaction.Distance then
                        local PlayerSource = GetPlayerServerId(Player.id)

                        Interaction = {
                            Entity = Player.ped,
                            Source = PlayerSource,
                            Id = Player.id,
                            Distance = Player.Distance,
                            GetCenter = function()
                                local BoneIndex = GetPedBoneIndex(Player.ped, 24817)
                                local BonePos = GetWorldPositionOfEntityBone(Player.ped, BoneIndex)
                                return vec3(BonePos.x, BonePos.y, BonePos.z)
                            end,
                            Options = {}
                        }
                    end
                end

                for Name, Data in pairs(GlobalPlayers) do
                    if Data.radius > Interaction.Distance then
                        if Data.canInteract == nil or Data.canInteract({
                            Source = Interaction.Source,
                            Ped = Interaction.Entity,
                            Id = Interaction.Id,
                            Distance = Interaction.Distance,
                        }) then -- Todo: Make this more efficient
                            for i = 1, #Data.options do
                                Interaction.Options[#Interaction.Options + 1] = Data.options[i]
                            end
                        end
                    end
                end

                if not next(Interaction.Options) then
                    Interaction = nil
                end
            end
        end

        if next(InteractionPoints) then
            local NearbyPoints = lib.grid.getNearbyEntries(PlayerCoords, function(Entry) return #(PlayerCoords - vec3(Entry.coords.x, Entry.coords.y, Entry.coords.z)) <= Entry.radius end)
            if next(NearbyPoints) then
                for Index, Point in pairs(NearbyPoints) do
                    Point.Distance = #(PlayerCoords - vec3(Point.coords.x, Point.coords.y, Point.coords.z))

                    if Point.canInteract == nil or Point.canInteract({
                        Distance = Point.Distance
                    }) then
                        if not Interaction or Point.Distance < Interaction.Distance then
                            Interaction = {
                                Coords = Point.coords,
                                Options = Point.options,
                                Distance = Point.Distance
                            }
                        end
                    end
                end
            end
        end

        if next(InteractionEntities) then
            for Entity, InteractionEntity in pairs(InteractionEntities) do
                if DoesEntityExist(Entity) then
                    InteractionEntity.GetCenter = InteractionEntity.GetCenter or function() return GetEntityCoords(Entity) end
                    InteractionEntity.Distance = #(PlayerCoords - InteractionEntity.GetCenter())
                    if InteractionEntity.Distance <= (InteractionEntity.radius or Config.MaxDistance) and (not Interaction or InteractionEntity.Distance < Interaction.Distance) then
                        Interaction = {
                            Entity = Entity,
                            Distance = InteractionEntity.Distance,
                            GetCenter = InteractionEntity.GetCenter,
                            Options = InteractionEntity.options,
                        }
                    end
                else
                    InteractionEntities[Entity] = nil
                end
            end
        end

        if not Tick then
            if Interaction then
                Dui = lib.dui:new(
                    {
                        url = "nui://j-interaction/web/build/index.html", 
                        width = ScreenW,
                        height = ScreenH,
                    }
                )

                CreateThread(function()
                    Wait(150)

                    Dui:sendMessage({
                        action = 'SetVisualizer',
                        data = true
                    })
                end)

                Keybind:disable(false)

                Tick = SetInterval(function()
                    if not Dui then return end

                    local VisualizerCoords = Interaction.coords or Interaction.GetCenter()

                    Draw3DSprite(VisualizerCoords, Dui.dictName, Dui.txtName)
                end, 0)
            end
        elseif not Interaction then
            Tick = ClearInterval(Tick)
            Dui:remove()
            Dui = nil
            Keybind:disable(true)

            if RadialOpen then CloseRadial(true) end
        end

        Wait(300)
    end
end)

RegisterNuiCallback('onRadialSelect', function(index, cb)
    if Interaction then Interaction.Options[index].action() end

    CloseRadial()
    cb({})
end)

RegisterNuiCallback('onCancel', function(data, cb)
    CloseRadial()
    cb({})
end)

exports('AddGlobalPlayer', function(Data)
    GlobalPlayers[Data.name] = Data
    return Data.name
end)

exports('RemoveGlobalPlayer', function(Name)
    GlobalPlayers[Name] = nil
end)

exports('AddPoint', function(Data)
    lib.grid.addEntry(Data)
    InteractionPoints[Data.name] = Data
end)

exports('RemovePoint', function(Name)
    lib.grid.removeEntry(InteractionPoints[Name])
    InteractionPoints[Name] = nil
end)

exports('AddEntity', function(Entity, Data)
    InteractionEntities[Entity] = Data
end)

exports('RemoveEntity', function(Entity)
    InteractionEntities[Entity] = nil
end)