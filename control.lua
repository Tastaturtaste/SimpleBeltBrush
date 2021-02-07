local Inventory = require('__stdlib__/stdlib/entity/inventory')
local table = require('__stdlib__/stdlib/utils/table')
local Event = require('__stdlib__/stdlib/event/event').set_protected_mode(true)
local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')


brush_types = {
    ['transport-belt'] = true,
    ['wall'] = true
}

local function match_placed_type(stack)
    if not stack.valid_for_read then 
        return
    end
    if not stack.prototype.place_result then
        return
    end
    return brush_types[stack.prototype.place_result.type]
end

local function revive_brush(event)
    local player = game.get_player(event.player_index)
    local ent = event.created_entity
    if ent.name == 'entity-ghost' and brush_types[ent.ghost_type] and Inventory.is_named_bp(player.cursor_stack, 'BrushBP') then
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

local function build_brush(stack, ent_name, lanes)
    local entities = {}
    local _, width = Area(game.entity_prototypes[ent_name].collision_box):size()
    width = math.ceil(width)
    for i = 1,lanes do
        entities[#entities + 1] = {
            entity_number = i,
            name = ent_name,
            position = {-lanes*width*0.5 + i*width, 0},
            direction = defines.direction.north
        }
    end
    stack.set_blueprint_entities(entities)
    stack.label = 'BrushBP ' .. lanes
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

local function incr_decr_lanes(event)
    local player = game.get_player(event.player_index)
    local inventory = player.get_main_inventory()
    local stack = player.cursor_stack
    local brush = Inventory.is_named_bp(stack,'BrushBP')
    local change = 0
    if not (match_placed_type(stack) or brush) then
        return
    end
    if event.input_name == 'brush-inc' then
        change = 1
    elseif event.input_name == 'brush-dec' then
        change = -1
    end
    if match_placed_type(stack) and change > 0 then
        local name = stack.name
        if not player.clear_cursor() then 
            return
        end
        stack.set_stack('blueprint')
        build_brush(stack,name,1+change)
        return
    end
    if brush then
        local lanes = stack.label:match('%d+')
        local ents = stack.get_blueprint_entities()
        local ent = table.find(
            ents,
            function(e)
                return brush_types[game.entity_prototypes[e.name].type]
            end
        )
        if lanes + change > 1 then
            build_brush(stack, ent.name, lanes+change)
        elseif lanes + change <= 1 then
            stack.set_stack(nil)
            inv_stack, inv_stack_idx = inventory.find_item_stack(ent.name)
            stack.swap_stack(inv_stack)
            player.hand_location = {inventory = defines.inventory.character_main, slot = inv_stack_idx}
        end
    end
end
Event.register('brush-inc',incr_decr_lanes)
Event.register('brush-dec',incr_decr_lanes)