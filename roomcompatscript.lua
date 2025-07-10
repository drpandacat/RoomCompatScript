--[[
    Room Compatibility Script by Kerkel
    Version 1.0
]]

local VERSION = 1.3
---@type table<integer, table<integer, boolean>>
local ENTITY_WHITELIST = {
    [EntityType.ENTITY_PICKUP] = {
        [PickupVariant.PICKUP_NULL] = true,
    }
}

if RoomCompatScript then
    if RoomCompatScript.Internal.VERSION > VERSION then return end
    ENTITY_WHITELIST = RoomCompatScript.ENTITY_WHITELIST
    for _, v in ipairs(RoomCompatScript.Internal.CallbackEntries) do
        RoomCompatScript:RemoveCallback(v[1], v[3])
    end
end

RoomCompatScript = RegisterMod("Room Compatibility Script", 1)
RoomCompatScript.Internal = {}
RoomCompatScript.Internal.VERSION = VERSION
RoomCompatScript.Internal.DEBUG = false

RoomCompatScript.ATTEMPTS_STRICT = 20
RoomCompatScript.ATTEMPTS_LOOSE = 20
RoomCompatScript.ENTITY_WHITELIST = ENTITY_WHITELIST

---@param str string
function RoomCompatScript.Internal:Print(str)
    (RoomCompatScript.Internal.DEBUG and print or Isaac.DebugString)("[Room Compatibility Script] " .. str)
end

---@param config RoomConfigRoom?
function RoomCompatScript:IsEligibleRoom(config)
    if not config then return false end

    for spawnIndex = 0, config.Spawns.Size - 1 do
        local spawn = config.Spawns:Get(spawnIndex)

        for entryIndex = 0, spawn.Entries.Size - 1 do
            ---@class RoomConfigEntry
            ---@field Type EntityType
            ---@field Variant integer
            ---@field Subtype integer
            ---@field Weight number
            ---@diagnostic disable-next-line: assign-type-mismatch
            local entry = spawn.Entries:Get(entryIndex)

            if entry.Type < EntityType.ENTITY_EFFECT and (
                not RoomCompatScript.ENTITY_WHITELIST[entry.Type]
                or not RoomCompatScript.ENTITY_WHITELIST[entry.Type][entry.Variant]
            ) then
                RoomCompatScript.Internal:Print("---Found non-existent entity " .. entry.Type .. "." .. entry.Variant .. "." .. entry.Subtype)
                return false
            end
        end
    end

    return true
end

RoomCompatScript.Internal.CallbackEntries = {
    {
        ModCallbacks.MC_PRE_LEVEL_PLACE_ROOM,
        CallbackPriority.IMPORTANT,
        ---@param slot LevelGeneratorRoom
        ---@param config RoomConfigRoom
        ---@param seed integer
        function (_, slot, config, seed)
            if RoomCompatScript:IsEligibleRoom(config) then return end

            local shape = slot:Shape()
            local doors = slot:DoorMask()
            local rng = RNG(seed)

            for _ = 1, RoomCompatScript.ATTEMPTS_STRICT do
                local new = RoomConfigHolder.GetRandomRoom(
                    rng:Next(),
                    true,
                    config.StageID,
                    config.Type,
                    shape,
                    0,
                    -1,
                    config.Difficulty,
                    config.Difficulty,
                    doors,
                    config.Subtype,
                    config.Mode
                )

                if RoomCompatScript:IsEligibleRoom(new) then
                    RoomCompatScript.Internal:Print("Replaced with strict match")
                    return new
                end
            end

            for _ = 1, RoomCompatScript.ATTEMPTS_LOOSE do
                local new = RoomConfigHolder.GetRandomRoom(
                    rng:Next(),
                    true,
                    config.StageID,
                    config.Type,
                    shape,
                    nil,
                    nil,
                    nil,
                    nil,
                    nil,
                    config.Subtype
                )

                if RoomCompatScript:IsEligibleRoom(new) then
                    RoomCompatScript.Internal:Print("Replaced with loose match")
                    return new
                end
            end

            RoomCompatScript.Internal:Print("Failed replacement on room with type " .. config.Type)
        end,
    },
    {
        ModCallbacks.MC_PRE_ENTITY_SPAWN,
        CallbackPriority.IMPORTANT,
        function (_, type, variant, subtype, _, _, _, seed)
            if RoomCompatScript.ENTITY_WHITELIST[type] then return end
            RoomCompatScript.Internal:Print("Prevented spawn " .. type .. "." .. variant .. "." .. subtype)
            return {EntityType.ENTITY_EFFECT, 40, 0, seed}
        end
    },
    {
        ModCallbacks.MC_POST_MODS_LOADED,
        CallbackPriority.DEFAULT,
        function ()
            for i = 0, XMLData.GetNumEntries(XMLNode.ENTITY) do
                local entry = XMLData.GetEntryByOrder(XMLNode.ENTITY, i)

                if entry and entry.id and entry.variant then
                    local id = tonumber(entry.id) ---@cast id integer
                    RoomCompatScript.ENTITY_WHITELIST[id] = RoomCompatScript.ENTITY_WHITELIST[id] or {}
                    RoomCompatScript.ENTITY_WHITELIST[id][tonumber(entry.variant)] = true
                end
            end
        end
    }
}

for _, v in ipairs(RoomCompatScript.Internal.CallbackEntries) do
    RoomCompatScript:AddPriorityCallback(v[1], v[2], v[3], v[4])
end