/obj/effect/proc_holder/spell/invoked/minion_order
	name = "Order Minions"
	desc = "Cast on turf to goto, cast on minion to set to aggressive, cast on self to passive and follow, cast on target to focus."
	range = 12
	associated_skill = /datum/skill/misc/athletics
	chargedrain = 1
	chargetime = 1 SECONDS
	releasedrain = 0 
	charge_max = 10 SECONDS
	var/order_range = 12
	var/faction_ordering = FALSE ///this sets whether it orders mobs the user is aligned with in range or just mobs who are the character's 'friends' (ie, their summons)

/obj/effect/proc_holder/spell/invoked/minion_order/lich //as an example, this should allow the lich to command the entire undead faction
	faction_ordering = TRUE

/obj/effect/proc_holder/spell/invoked/minion_order/cast(list/targets, mob/user)
	if(!targets?.len || !user)
		revert_cast()
		return
	
	var/target = targets[1]

	var/is_turf = isturf(target)
	var/is_self = (target == user)
	var/is_mob = ismob(target)
	
	if(!is_turf && !is_self && !is_mob)
		revert_cast()
		return
	
	var/order_type
	var/turf/target_location
	var/mob/living/mob_target
	
	if(is_turf)
		order_type = "goto"
		target_location = target
	else if(is_self)
		order_type = "follow"
		mob_target = user
	else if(is_mob)
		mob_target = target
		//This will end up poorly if you somehow have two factions and want them to fight each other
		if(user.faction_check_mob(target) || (mob_target.summoner && mob_target.summoner == user.name))
			order_type = "aggressive"
		else
			order_type = "attack"
	
	process_minions(order_type, target_location, mob_target)

/obj/effect/proc_holder/spell/invoked/minion_order/proc/process_minions(order_type, turf/target_location = null, mob/living/target = null)
	var/mob/caster = usr
	var/list/valid_minions = list()
	
	//Create valid minions
	for(var/mob/living/simple_animal/minion in oview(order_range, caster))
		if(minion.client) // Skip player-controlled mobs
			continue
			
		if((faction_ordering && caster.faction_check_mob(minion)) || (!faction_ordering && minion.summoner == caster.name))
			valid_minions += minion
	
	//Iterate over
	for(var/mob/living/simple_animal/minion in valid_minions)
		var/datum/ai_controller/ai = minion.ai_controller
		
		ai.clear_blackboard_key(BB_FOLLOW_TARGET)
		ai.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		ai.clear_blackboard_key(BB_TRAVEL_DESTINATION)
		
		switch(order_type)
			if("goto")
				ai.set_blackboard_key(BB_TRAVEL_DESTINATION, target_location)
				minion.balloon_alert(caster, "Going to [target_location].")
			if("follow")
				ai.set_blackboard_key(BB_FOLLOW_TARGET, target)
				minion.balloon_alert(caster, "Following you.")
			if("aggressive")
				minion.balloon_alert(caster, "Returning to my natural state.")
			if("attack")
				ai.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
				minion.balloon_alert(caster, "Attacking [target.name].")
