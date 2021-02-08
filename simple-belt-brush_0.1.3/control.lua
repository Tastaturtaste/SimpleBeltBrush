local Inventory = require('__stdlib__/stdlib/entity/inventory')
local table = require('__stdlib__/stdlib/utils/table')
local Event = require('__stdlib__/stdlib/event/event').set_protected_mode(true)
local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')


BRUSH_TYPES = {
    ['transport-belt'] = true,
    ['wall'] = true,
    ['ammo-turret'] = true,
    ['electric-turret'] = true,
    ['fluid-turred'] = true
}

local function match_placed_type(stack)
    if not stack.valid_for_read then 
        return
    end
    if not stack.prototype.place_result then
        return
    end
    return BRUSH_TYPES[stack.prototype.place_result.type]
end

local function revive_brush(event)
    local player = game.get_player(event.player_index)
    local ent = event.created_entity
    if ent.name == 'entity-ghost' and BRUSH_TYPES[ent.ghost_type] and Inventory.is_named_bp(player.cursor_stack, 'BrushBP') then
        local ghost = event.created_entity
        local name = ghost.ghost_name
        if Position.distance(player.position, ghost.position) <= player.build_distance + 1 then
            if player.get_item_count(name) > 0 then
                local _, revived = ghost.revive{raise_revive = true}
                if revived then
                    player.remove_item({name = name, count = 1})
                end
            end
        end
    end
end
Event.register(defines.events.on_built_entity, revive_brush)

local function stack_from_inventory(player,item_name)
    local inventory = player.get_main_inventory()
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read and stack.name == item_name then
            return stack
        end
    end
end

local function build_brush(stack, ent_name, lanes, depth)
    local entities = {}
    local height, width = Area(game.entity_prototypes[ent_name].collision_box):size()
    width = math.ceil(width)
    height = math.ceil(height)

    for i = 1,lanes do
        for j = 1,depth do
                entities[#entities + 1] = {
                    entity_number = (i-1)*lanes + j,
                    name = ent_name,
                    position = {-lanes*width*0.5 + i*width, -depth*height*0.5 + j*height},
                    direction = defines.direction.north
                }
        end
    end
    stack.set_blueprint_entities(entities)
    stack.label = 'BrushBP-L' .. lanes .. '-D' .. depth
    stack.allow_manual_label_change = false
end

local function delete_from_inventory(event)
    player = game.get_player(event.player_index)
    inventory = player.get_main_inventory()
    for i = 1,#inventory do
        stack = inventory[i]
        if stack.valid_for_read and stack.is_blueprint and stack.label and stack.label:find('BrushBP') then
            stack.clear()
        end
    end
end
Event.register(defines.events.on_player_cursor_stack_changed, delete_from_inventory)

local function get_lanes_depth(label)
    l,d =  label:match('L(%d+)%-D(%d+)')
    return tonumber(l), tonumber(d)
end

local function init_brush(player,lanes,depth)
    local stack = player.cursor_stack
    local name = stack.name
    if not player.clear_cursor() then 
        return
    end
    stack.set_stack('blueprint')
    build_brush(stack,name,lanes,depth)
    return
end

local function modify_brush(player,lanes,depth)
    if lanes < 1 or depth < 1 then
        return
    end
    local stack = player.cursor_stack
    local ents = stack.get_blueprint_entities()
    local ent = table.find(
        ents,
        function(e)
            return BRUSH_TYPES[game.entity_prototypes[e.name].type]
        end
    )
    build_brush(stack, ent.name, lanes, depth)
end

local function reset_brush(player)
    local stack = player.cursor_stack
    local ents = stack.get_blueprint_entities()
    local ent = table.find(
        ents,
        function(e)
            return BRUSH_TYPES[game.entity_prototypes[e.name].type]
        end
    )
    stack.set_stack(nil)
    local inv_stack, inv_stack_idx = inventory.find_item_stack(ent.name)
    stack.swap_stack(inv_stack)
    player.hand_location = {inventory = defines.inventory.character_main, slot = inv_stack_idx}
end

local function incr_lanes(event)
    local player = game.get_player(event.player_index)
    local stack = player.cursor_stack
    local brush = Inventory.is_named_bp(stack,'BrushBP')
    if not (match_placed_type(stack) or brush) then
        return
    end
    if match_placed_type(stack) then
        init_brush(player, 2,1)
        return
    end
    if brush then
        local lanes, depth = get_lanes_depth(stack.label)
        modify_brush(player, lanes+1,depth)
    end
end

local function decr_lanes(event)
    local player = game.get_player(event.player_index)
    local stack = player.cursor_stack
    local brush = Inventory.is_named_bp(stack,'BrushBP')
    if not (match_placed_type(stack) or brush) then
        return
    end
    if brush then
        local lanes, depth = get_lanes_depth(stack.label)
        if lanes > 2 then
            modify_brush(player, lanes-1,depth)
        else
            reset_brush(player)
        end
    end
end

local function incr_depth(event)
    local player = game.get_player(event.player_index)
    local stack = player.cursor_stack
    local brush = Inventory.is_named_bp(stack,'BrushBP')
    if not (match_placed_type(stack) or brush) then
        return
    end
    if match_placed_type(stack) then
        init_brush(player, 1,2)
        return
    end
    if brush then
        local lanes, depth = get_lanes_depth(stack.label)
        modify_brush(player, lanes,depth+1)
    end
end

local function decr_depth(event)
    local player = game.get_player(event.player_index)
    local stack = player.cursor_stack
    local brush = Inventory.is_named_bp(stack,'BrushBP')
    if not (match_placed_type(stack) or brush) then
        return
    end
    if brush then
        local lanes, depth = get_lanes_depth(stack.label)
        if depth > 2 then
            modify_brush(player, lanes,depth-1)
        else
            reset_brush(player)
        end
    end
end

Event.register('brush-inc-lanes',incr_lanes)
Event.register('brush-dec-lanes',decr_lanes)
Event.register('brush-inc-depth',incr_depth)
Event.register('brush-dec-depth',decr_depth)