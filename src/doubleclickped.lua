local touch_events = {
    POP = 1,
    PUSH = 2,
    MOVE = 3
  }

local dbp = {}

local lastClick = nil
local lastClickTime = nil
dbp.doubleClickThreshold = 0.5
dbp.clickRadius = 8

function findPedByRaycasts(screenX, screenY, maxDistance)
    local worldX, worldY, worldZ = convertScreenCoordsToWorld3D(screenX, screenY, maxDistance)

    local camX, camY, camZ = getActiveCameraCoordinates()
    local res, col = processLineOfSight(camX, camY, camZ, worldX, worldY, worldZ, true, false, true)
    
    if res and col.entityType == 3 then
        return col.entity
    end

    return nil
end

local function onTouch(type, id, x, y)
    local currentTime = os.clock()

    if type == touch_events.PUSH and lastClick ~= nil and distance(lastClick, {x, y}) <= dbp.clickRadius and currentTime - lastClickTime <= dbp.doubleClickThreshold then
        local handle = findPedByRaycasts(x, y, isCharInAnyCar(PLAYER_PED) and 150 or 50)

        if handle then
            local ped = getCharPointerHandle(handle)
            dbp.onDoubleClickedPed(ped, x, y)
        end
        
        lastClick = nil
        lastClickTime = nil
    elseif type == touch_events.PUSH then
        lastClick = {x, y}
        lastClickTime = currentTime
    end
end
if MONET_VERSION then addEventHandler('onTouch', onTouch) end

function dbp.onDoubleClickedPed(ped, x,y) end

function distance(point1, point2)
    local dx = point1[1] - point2[1]
    local dy = point1[2] - point2[2]
    return math.sqrt(dx * dx + dy * dy)
end

return dbp