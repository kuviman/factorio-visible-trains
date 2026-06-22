local drawn = {}

-- Queue implemented using two stacks
Queue = {
    new = function()
        return { front = {}, back = {} }
    end,
    push = function(self, x)
        table.insert(self.back, x)
    end,
    pop = function(self)
        if #(self.front) == 0 then
            while #(self.back) ~= 0 do
                table.insert(self.front, table.remove(self.back))
            end
        end
        return table.remove(self.front)
    end,
}

function current_player()
    return game.players[1]
end

function current_zoom_scale()
    return settings.global["visible-trains-icon-scale"].value / current_player().zoom
end

function redraw_rail_graph()
    local surface = current_player().surface
    for _, drawn in ipairs(drawn) do
        drawn.destroy()
    end
    drawn = {}
    if not settings.global["visible-trains-draw-rails"].value then
        return
    end
    local zoom_scale = current_zoom_scale()

    function draw_line(from, to)
        table.insert(drawn,
            rendering.draw_line({
                color = { 0.5, 0.5, 0.5, 1 },
                width = 2 * zoom_scale,
                from = from,
                to = to,
                surface = from.surface,
                draw_on_ground = true,
                render_mode = "chart",
            })
        )
    end

    -- store for each rail distance from closest keypoint and keypoint itself
    -- keypoints are there in order to reduce amount of vertices for performance
    local state = {}

    -- queue for bfs
    local q = Queue.new()
    for _, rail in ipairs(surface.find_entities_filtered(
        { name = {
            "curved-rail-a",
            "curved-rail-b",
            "half-diagonal-rail",
            "straight-rail",
            "legacy-straight-rail",
            "legacy-curved-rail",
        } }
    )) do
        if state[rail.unit_number] == nil then
            state[rail.unit_number] = { distance = 0, keypoint = rail, direct_parent = rail }
            log("START BFS FROM" .. serpent.block(rail))
            Queue.push(q, rail)
            while true do
                rail = Queue.pop(q)
                if rail == nil then
                    break
                end
                local is_junction = false
                local connected_rails = {}
                for _, rail_direction in pairs(defines.rail_direction) do
                    local connected_rails_in_this_direction = 0
                    for rail_connection_direction_name, rail_connection_direction in pairs(defines.rail_connection_direction) do
                        if rail_connection_direction_name ~= "none" then
                            local connected_rail = rail.get_connected_rail({
                                rail_direction = rail_direction,
                                rail_connection_direction = rail_connection_direction,
                            })
                            if connected_rail ~= nil then
                                connected_rails_in_this_direction = connected_rails_in_this_direction + 1
                                table.insert(connected_rails, connected_rail)
                            end
                        end
                    end
                    if connected_rails_in_this_direction >= 2 then
                        is_junction = true
                    end
                end
                local is_keypoint = state[rail.unit_number].distance >= 10 or is_junction
                if is_keypoint then
                    if state[rail.unit_number].keypoint.unit_number ~= rail.unit_number then
                        draw_line(rail, state[rail.unit_number].keypoint)
                    end
                    state[rail.unit_number] = {
                        keypoint = rail,
                        direct_parent = state[rail.unit_number].direct_parent,
                        distance = 0,
                    }
                end
                for _, connected_rail in ipairs(connected_rails) do
                    if state[connected_rail.unit_number] == nil then
                        Queue.push(q, connected_rail)
                        state[connected_rail.unit_number] = {
                            keypoint = state[rail.unit_number].keypoint,
                            distance = state[rail.unit_number].distance + 1,
                            direct_parent = rail,
                        }
                    elseif state[connected_rail.unit_number].keypoint.unit_number ~= state[rail.unit_number].keypoint.unit_number then
                        draw_line(state[rail.unit_number].keypoint, state[connected_rail.unit_number].keypoint)
                    end
                end
            end
        end
    end
end

function draw_all_trains()
    local train_manager = game.train_manager
    local zoom_scale = current_zoom_scale()

    for _, train in ipairs(train_manager.get_trains({})) do
        for i = 1, #train.carriages do
            local carriage = train.carriages[i]
            local sprite = "entity/" .. carriage.prototype.name
            local layer = "arrow"

            if settings.global["visible-trains-wagon-content-icon"].value then
                if carriage.type == "cargo-wagon" then
                    local inventory = carriage.get_inventory(defines.inventory.cargo_wagon)
                    local contents = inventory.get_contents()
                    if #contents > 0 then
                        sprite = "item/" .. contents[1].name
                    end
                elseif carriage.type == "fluid-wagon" then
                    local fluid_contents = carriage.get_fluid_contents()
                    for fluid_name, amount in pairs(fluid_contents) do
                        if amount > 0 then
                            sprite = "fluid/" .. fluid_name
                            break
                        end
                    end
                else
                    layer = "collision-selection-box"
                end
            end

            rendering.draw_sprite({
                sprite = sprite,
                x_scale = zoom_scale,
                y_scale = zoom_scale,
                time_to_live = 1,
                target = carriage,
                surface = carriage.surface,
                render_mode = "chart",
                render_layer = layer,
            })
        end
    end
end

script.on_event(defines.events.on_built_entity,
    function(event)
        if event.entity.name == "straight-rail" or event.entity.name == "legacy-straight-rail" then
            redraw_rail_graph()
        end
    end
)

local prev_zoom_scale = nil
local ticks_since_changed_zoom = 0

-- TODO instead of drawing every tick, could add a sprite when train spawns,
-- and then update scale when zoom level changes
-- would help performance maybe
script.on_event(defines.events.on_tick,
    function(event)
        local zoom_scale = current_zoom_scale()
        if zoom_scale ~= prev_zoom_scale then
            ticks_since_changed_zoom = ticks_since_changed_zoom + 1
            if ticks_since_changed_zoom > 100 then
                ticks_since_changed_zoom = 0
                prev_zoom_scale = zoom_scale
                redraw_rail_graph()
            end
        end
        draw_all_trains()
    end
)
