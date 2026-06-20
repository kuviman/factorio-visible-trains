-- TODO instead of drawing every tick, could add a sprite when train spawns,
-- and then update scale when zoom level changes
-- would help performance maybe

script.on_event(defines.events.on_tick,
  function(event)
    local train_manager = game.train_manager
    local player = game.players[1]
    local zoom_scale = settings.global["visible-trains-icon-scale"].value / player.zoom
    
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
                surface = 1, -- TODO
                render_mode = "chart",
                render_layer = layer,
            })
        end
    end
  end
)
