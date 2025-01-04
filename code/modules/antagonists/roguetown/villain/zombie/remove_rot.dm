/proc/remove_rot(mob/living/carbon/human/target, mob/living/user, method = "unknown", damage = 0, success_message = "The rot is removed.", fail_message = "The rot removal failed.")
	if (!istype(target, /mob/living/carbon/human) || QDELETED(target))
		return FALSE

	// Check if the target has rot
	var/has_rot = FALSE
	var/datum/antagonist/zombie/was_zombie = target.mind?.has_antag_datum(/datum/antagonist/zombie)

	if (was_zombie)
		has_rot = TRUE
	else if (istype(target, /mob/living/carbon))
		has_rot = check_bodyparts_for_rot(target)

	// Handle failure case
	if (!has_rot)
		to_chat(user, span_warning(fail_message))
		return FALSE

	if (was_zombie)
		remove_zombie_antag(target, user, method)

	// Remove rot component
	remove_rot_component(target)

	// Clean body parts
	clean_body_parts(target)

	//Doing it out of this proc for now
	//to_chat(user, span_notice(success_message))

	return TRUE

/proc/check_bodyparts_for_rot(mob/living/carbon/target)
	for (var/obj/item/bodypart/bodypart in target.bodyparts)
		if (bodypart.rotted || bodypart.skeletonized)
			return TRUE
	return FALSE


/proc/remove_zombie_antag(mob/living/carbon/target, mob/living/user, method)
	var/datum/antagonist/zombie/was_zombie = target.mind?.has_antag_datum(/datum/antagonist/zombie)
	if (!was_zombie)
		return

	was_zombie.become_rotman = FALSE
	target.mind.remove_antag_datum(/datum/antagonist/zombie)
	target.Unconscious(20 SECONDS)
	target.emote("breathgasp")
	target.Jitter(100)

	if (!HAS_TRAIT(target, TRAIT_IWASUNZOMBIFIED) && user?.ckey)
		adjust_playerquality(PQ_GAIN_UNZOMBIFY, user.ckey)
		ADD_TRAIT(target, TRAIT_IWASUNZOMBIFIED, "[method]")

///Removes the rot amount from the target
/proc/remove_rot_component(mob/living/carbon/target)
	var/datum/component/rot/rot = target.GetComponent(/datum/component/rot)
	if (rot)
		rot.amount = 0

///Cure bodyparts
/proc/clean_body_parts(mob/living/carbon/target)
	for (var/obj/item/bodypart/bodypart in target.bodyparts)
		bodypart.rotted = FALSE
		bodypart.skeletonized = FALSE
		bodypart.update_limb()
		bodypart.update_disabled()

	target.update_body()