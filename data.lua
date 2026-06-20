for locomotive_name, locomotive in pairs(data.raw['locomotive']) do
    log("UPDATING: " .. locomotive_name)
    log("" .. serpent.block(locomotive))
    -- THIS ACTUALLY DOESNT WORK
    -- locomotive.minimap_representation.flags = {};
    -- table.insert(
    --     locomotive.minimap_representation.flags,
    --     "no-scale"
    -- )
end
