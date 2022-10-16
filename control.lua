local this = {
    players = {}
}

script.on_event(defines.events.on_player_cancelled_crafting, function(event)
    local player = game.players[event.player_index]
    local player_config = this.players[event.player_index]
    if player_config and (player_config.reset_crafting or no_action) then
        return
    end

    if player.character.character_inventory_slots_bonus == 0 then
        player.character.character_inventory_slots_bonus = 100
    end
    this.players[event.player_index] = {
        ingredients = {count = event.cancel_count, recipe = event.recipe}
    }
end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.players[event.player_index]
    local player_config = this.players[event.player_index]
    if not player_config or player_config.no_action then
        return
    end

    if player_config.ingredients then
        if player.get_main_inventory().count_empty_stacks() < 100 then
            player.begin_crafting(player_config.ingredients)
            game.print({'inventory-full-message.main'})
            player.character.character_inventory_slots_bonus = 0
            this.players[event.player_index] = {}
            return
        end
    end

    if player_config.reset_crafting and player.crafting_queue then
        local last_craft = player.crafting_queue[player.crafting_queue_size]
        player_config.ingredients = last_craft
        player.cancel_crafting{index=last_craft.index, count=last_craft.count}
        return
    end

    player.character.character_inventory_slots_bonus = 0
    this.players[event.player_index] = {}
end)

script.on_event("reset-craft", function(event)
    local player = game.players[event.player_index]
    if player.crafting_queue_size > 0 then
        if player.character.character_inventory_slots_bonus == 0 then
            player.character.character_inventory_slots_bonus = 100
        end
        local last_craft = player.crafting_queue[player.crafting_queue_size]

        player.cancel_crafting{index=last_craft.index, count=last_craft.count}
        this.players[event.player_index] = {
            reset_crafting = true,
            ingredients = last_craft
        }
    end
end)

script.on_event("promote-craft", function(event)
    local player = game.players[event.player_index]
    if player.crafting_queue_size > 1 then
        local inventory_bonus = player.character.character_inventory_slots_bonus
        local last_craft = player.crafting_queue[player.crafting_queue_size]
        player.character.character_inventory_slots_bonus = inventory_bonus + 1000
        this.players[event.player_index] = {
            no_action = true,
        }

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

        player.character.character_inventory_slots_bonus = inventory_bonus
        this.players[event.player_index] = {}
    end
end)

script.on_event("demote-craft", function(event)
    local player = game.players[event.player_index]
    if player.crafting_queue_size > 1 then
        local inventory_bonus = player.character.character_inventory_slots_bonus
        local last_craft = player.crafting_queue[player.crafting_queue_size]
        player.character.character_inventory_slots_bonus = inventory_bonus + 1000
        this.players[event.player_index] = {
            no_action = true,
        }

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

        player.character.character_inventory_slots_bonus = inventory_bonus
        this.players[event.player_index] = {}
    end
end)
