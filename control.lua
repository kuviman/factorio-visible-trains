-- TODO instead of drawing every tick, could add a sprite when train spawns,
-- and then update scale when zoom level changes
-- would help performance maybe

script.on_event(defines.events.on_tick,
  function(event)
    local train_manager = game.train_manager
    local player = game.players[1]
    for _, train in ipairs(train_manager.get_trains({})) do
        for i = #train.carriages, 1, -1 do
            local carriage = train.carriages[i]
            rendering.draw_sprite({
                sprite = "entity/" .. carriage.prototype.name,
                x_scale = 1 / player.zoom,
                y_scale = 1 / player.zoom,
                time_to_live = 1,
                target = carriage,
                surface = 1, -- TODO
                render_mode = "chart",
            })
        end
    end
  end
)
