local drawn_rails = {}

function current_player()
    return game.players[1]
end

function current_zoom_scale()
    return settings.global["visible-trains-icon-scale"].value / current_player().zoom
end

function redraw_rail_graph()
    local surface = current_player().surface
    for _, drawn in ipairs(drawn_rails) do
        drawn.destroy()
    end
    drawn_rails = {}
    if not settings.global["visible-trains-draw-rails"].value then
        return
    end
    local zoom_scale = current_zoom_scale()
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
        for _, rail_direction in pairs(defines.rail_direction) do
            for rail_connection_direction_name, rail_connection_direction in pairs(defines.rail_connection_direction) do
                if rail_connection_direction_name ~= "none" then
                    local connected_rail = rail.get_connected_rail({
                        rail_direction = rail_direction,
                        rail_connection_direction = rail_connection_direction,
                    })
                    if connected_rail ~= nil then
                        table.insert(drawn_rails,
                            rendering.draw_line({
                                color = { 1, 1, 1, 1 },
                                width = 0.1 * zoom_scale,
                                from = rail,
                                to = connected_rail,
                                surface = surface,
                                draw_on_ground = true,
                                render_mode = "chart",
                            })
                        )
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
