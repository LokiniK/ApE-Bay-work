/datum/preferences
	var/list/prefix_keys_by_type

/datum/category_item/player_setup_item/player_global/prefixes
	name = "Prefixes"
	sort_order = 2

	var/static/list/prefix_by_name

/datum/category_item/player_setup_item/player_global/prefixes/New()
	..()
	SETUP_SUBTYPE_SINGLETONS_BY_NAME(/singleton/prefix, prefix_by_name)

/datum/category_item/player_setup_item/player_global/prefixes/load_preferences(datum/pref_record_reader/R)
	var/list/prefix_keys_by_name
	prefix_keys_by_name = R.read("prefix_keys")

	if(istype(prefix_keys_by_name))
		pref.prefix_keys_by_type = list()
		for(var/prefix_name in prefix_keys_by_name)
			var/singleton/prefix/prefix_instance = prefix_by_name[prefix_name]
			if(prefix_instance)
				pref.prefix_keys_by_type[prefix_instance.type] = prefix_keys_by_name[prefix_name]

/datum/category_item/player_setup_item/player_global/prefixes/save_preferences(datum/pref_record_writer/W)
	var/list/prefix_keys_by_name = list()
	for(var/prefix_type in pref.prefix_keys_by_type)
		var/singleton/prefix/prefix_instance = GET_SINGLETON(prefix_type)
		prefix_keys_by_name[prefix_instance.name] = pref.prefix_keys_by_type[prefix_type]

	W.write("prefix_keys", prefix_keys_by_name)

/datum/category_item/player_setup_item/player_global/prefixes/sanitize_preferences()
	if(!istype(pref.prefix_keys_by_type))
		pref.prefix_keys_by_type = list()

	// Setup the default keys for any prefix without one
	for(var/prefix_name in prefix_by_name)
		var/singleton/prefix/prefix_instance = prefix_by_name[prefix_name]
		if(!(prefix_instance.type in pref.prefix_keys_by_type))
			pref.prefix_keys_by_type[prefix_instance.type] = prefix_instance.default_key

	// Then check for duplicate keys.
	// In case of overlap, all affected prefixes are given their default key
	reset_duplicate_keys()

/datum/category_item/player_setup_item/player_global/prefixes/content(mob/user)
	. += "<b>Prefix Keys:</b><br>"
	. += "<table>"
	for(var/prefix_name in prefix_by_name)
		var/singleton/prefix/prefix_instance = prefix_by_name[prefix_name]
		var/current_prefix = pref.prefix_keys_by_type[prefix_instance.type]

		. += "<tr><td>[prefix_instance.name]</td><td>[pref.prefix_keys_by_type[prefix_instance.type]]</td><td>"

		if(prefix_instance.is_locked)
			. += SPAN_CLASS("linkOff", "Change")
		else

			. += "<a href='?src=\ref[src];change_prefix=\ref[prefix_instance]'>Change</a>"

		. += "</td><td>"

		if(prefix_instance.is_locked || current_prefix == prefix_instance.default_key)
			. += SPAN_CLASS("linkOff", "Reset")
		else
			. += "<a href='?src=\ref[src];reset_prefix=\ref[prefix_instance]'>Reset</a>"
		. += "</td></tr>"
	. += "</table>"

/datum/category_item/player_setup_item/player_global/prefixes/OnTopic(href, list/href_list, mob/user)
	if(href_list["change_prefix"])
		var/singleton/prefix/prefix_instance = locate(href_list["change_prefix"])
		if(!istype(prefix_instance) || prefix_instance.is_locked)
			return TOPIC_NOACTION

		do
			var/keys_in_use = list()
			for(var/prefix_type in pref.prefix_keys_by_type)
				if(prefix_type == prefix_instance.type)
					continue
				keys_in_use += pref.prefix_keys_by_type[prefix_type]

			var/new_key = input(user, "Enter a single special character. The following characters are already in use as prefixes: [jointext(keys_in_use, " ")]", CHARACTER_PREFERENCE_INPUT_TITLE, pref.prefix_keys_by_type[prefix_instance.type]) as null|text
			if(!new_key || new_key == pref.prefix_keys_by_type[prefix_instance.type] || !CanUseTopic(user))
				return TOPIC_NOACTION

			if(length(new_key) != 1)
				alert(user, "Only single characters are allowed.", "Error", "Ok")
			else if(contains_az09(new_key))
				alert(user, "Only special character are allowed.", "Error", "Ok")
			else if(new_key == " ")
				alert(user, "The space character is not allowed.", "Error", "Ok")
			else
				pref.prefix_keys_by_type[prefix_instance.type] = new_key

				// Here we attempt to replace any matching prefix keys with their default value, to allow quick replacements
				for(var/prefix_type in pref.prefix_keys_by_type)
					if(prefix_type == prefix_instance.type)
						continue
					var/prefix_key = pref.prefix_keys_by_type[prefix_type]
					if(prefix_key == new_key)
						var/singleton/prefix/pi = GET_SINGLETON(prefix_type)
						pref.prefix_keys_by_type[pi.type] = pi.default_key
				// Then we reset any and all duplicates
				reset_duplicate_keys()
				// Then, if the new key was reset it means it matched a default key.
				// If so the user has to select another key, otherwise the selection was successful
				if(pref.prefix_keys_by_type[prefix_instance.type] != new_key)
					alert(user, "The selected key is already the default key for another prefix.", "Error", "Ok")
				else
					return TOPIC_REFRESH
		while(TRUE)

	else if(href_list["reset_prefix"])
		var/singleton/prefix/prefix_instance = locate(href_list["reset_prefix"])
		if(!istype(prefix_instance))
			return TOPIC_NOACTION
		pref.prefix_keys_by_type[prefix_instance.type] = prefix_instance.default_key
		reset_duplicate_keys()
		return TOPIC_REFRESH

	else
		return ..()

/datum/category_item/player_setup_item/player_global/prefixes/proc/reset_duplicate_keys()
	var/list/prefixes_by_key = list()
	for(var/prefix_type in pref.prefix_keys_by_type)
		var/prefix_key = pref.prefix_keys_by_type[prefix_type]
		group_by(prefixes_by_key, prefix_key, prefix_type)

	for(var/prefix_key in prefixes_by_key)
		var/list/prefix_types = prefixes_by_key[prefix_key]
		if(length(prefix_types) > 1)
			for(var/prefix_type in prefix_types)
				var/singleton/prefix/prefix_instance = GET_SINGLETON(prefix_type)
				pref.prefix_keys_by_type[prefix_instance.type] = prefix_instance.default_key

/mob/proc/get_prefix_key(prefix_type)
	if(client && client.prefs)
		return client.prefs.prefix_keys_by_type[prefix_type]
	var/singleton/prefix/prefix_instance = GET_SINGLETON(prefix_type)
	return prefix_instance.default_key