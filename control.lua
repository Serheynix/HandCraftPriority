script.on_event(defines.events.on_player_cancelled_crafting, function(event)
    if global.HandCraftPriority and (global.HandCraftPriority.reset_crafting or global.HandCraftPriority.no_action) then
        return
    end
    local player = game.players[event.player_index]
    inventory_bonus = player.force.character_inventory_slots_bonus
    global.HandCraftPriority = {}
    global.HandCraftPriority.cancelled_crafting = true
    global.HandCraftPriority.inventory_bonus = inventory_bonus
    player.force.character_inventory_slots_bonus = inventory_bonus + 1000
    global.HandCraftPriority.ingredients = {count = event.cancel_count, recipe = event.recipe}
end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    if global.HandCraftPriority and global.HandCraftPriority.cancelled_crafting then
        local player = game.players[event.player_index]
        if player.get_main_inventory().count_empty_stacks() < 1000 then
            player.begin_crafting(global.HandCraftPriority.ingredients)
            game.print({'inventory-full-message.main'})
            player.force.character_inventory_slots_bonus = global.HandCraftPriority.inventory_bonus
            global.HandCraftPriority = {}
            return
        end
        if global.HandCraftPriority.reset_crafting then
            if player.crafting_queue then
                last_craft = player.crafting_queue[player.crafting_queue_size]
                global.HandCraftPriority.ingredients = last_craft
                player.cancel_crafting{index=last_craft.index, count=last_craft.count}
                return
            end
        end
        player.force.character_inventory_slots_bonus = global.HandCraftPriority.inventory_bonus
        global.HandCraftPriority = {}
    end
end)

script.on_event("reset-craft", function(event)
    local player = game.players[event.player_index]
    if player.crafting_queue_size > 0 then
        inventory_bonus = player.force.character_inventory_slots_bonus
        last_craft = player.crafting_queue[player.crafting_queue_size]
        global.HandCraftPriority = {}
        global.HandCraftPriority.cancelled_crafting = true
        global.HandCraftPriority.reset_crafting = true
        global.HandCraftPriority.inventory_bonus = inventory_bonus
        global.HandCraftPriority.ingredients = last_craft
        player.force.character_inventory_slots_bonus = inventory_bonus + 1000
        player.cancel_crafting{index=last_craft.index, count=last_craft.count}
    end
end)

script.on_event("promote-craft", function(event)
    local player = game.players[event.player_index]
    if player.crafting_queue_size > 1 then
        inventory_bonus = player.force.character_inventory_slots_bonus
        last_craft = player.crafting_queue[player.crafting_queue_size]
        global.HandCraftPriority = {}
        global.HandCraftPriority.no_action = true
        player.force.character_inventory_slots_bonus = inventory_bonus + 1000

        crafts = {}
        index = 1
        while player.crafting_queue_size > 0 do
            last_craft = player.crafting_queue[player.crafting_queue_size]
            crafts[index] = last_craft
            player.cancel_crafting{index=last_craft.index, count=last_craft.count}
            index = index + 1
        end
        index = index - 1

        next_craft = crafts[1]
        player.begin_crafting{count=next_craft.count, recipe=next_craft.recipe, silent=False}

        for remake_index = index, 2, -1 do
            next_craft = crafts[remake_index]
            player.begin_crafting{count=next_craft.count, recipe=next_craft.recipe, silent=False}
        end

        player.force.character_inventory_slots_bonus = inventory_bonus
        global.HandCraftPriority = {}
    end
end)

script.on_event("demote-craft", function(event)
    local player = game.players[event.player_index]
    if player.crafting_queue_size > 1 then
        inventory_bonus = player.force.character_inventory_slots_bonus
        last_craft = player.crafting_queue[player.crafting_queue_size]
        global.HandCraftPriority = {}
        global.HandCraftPriority.no_action = true
        player.force.character_inventory_slots_bonus = inventory_bonus + 1000

        crafts = {}
        index = 1
        while player.crafting_queue_size > 0 do
            last_craft = player.crafting_queue[player.crafting_queue_size]
            crafts[index] = last_craft
            player.cancel_crafting{index=last_craft.index, count=last_craft.count}
            index = index + 1
        end
        index = index - 1

        for remake_index = index-1, 1, -1 do
            next_craft = crafts[remake_index]
            player.begin_crafting{count=next_craft.count, recipe=next_craft.recipe, silent=False}
        end
        next_craft = crafts[index]
        player.begin_crafting{count=next_craft.count, recipe=next_craft.recipe, silent=False}

        player.force.character_inventory_slots_bonus = inventory_bonus
        global.HandCraftPriority = {}
    end
end)
