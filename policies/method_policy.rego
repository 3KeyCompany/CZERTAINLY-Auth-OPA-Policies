package method

import future.keywords.in
import future.keywords.every

authorized = true {
	count(allow) > 0
	count(deny) == 0
}

# Allow access when all resources are allowed
allow["AllResourcesAllowed"] {
	input.principal.permissions.allowAllResources == true	
}

# Allow access when all actions are allowed on requested resource 
allow["AllActionsAllowedOnResource"] {
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name
	
	# check if all action are allowed on requested resource
	r.allowAllActions == true
}

# Allow access when requested action is allowed on requeted resource
allow["ActionAllowedOnResource"] {
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name
	
	# 
	input.requestedResource.action in r.actions
}

# Allow access when requested action on resource is allowed for some objects and no object UUIDs are specified
allow["ActionAllowedForSomeObjects"] {
	not input.requestedResource.uuids
	
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name
	
	# check that requested action is allowed for some object under the resource
	input.requestedResource.action in r.objects[_].allow 
}

# Allow access when action is allowed for given objects
allow["ActionAllowedForSpecificObject"] {
	# requested contains uuids of specific objects
	input.requestedResource.uuids
	
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name
	
	# get all objects uuids for which the action is allowed
	allowedUUIDs := [ uuid | 
		some o in r.objects
		input.requestedResource.action in o.allow
		uuid := o.uuid
	]

	# check that array of allowedUUIDs conatins all requested uuids
	every uuid in input.requestedResource.uuids {
		uuid in allowedUUIDs
	}
}

# Allow access when action is NONE and at least one action allowed is allowed for requested resource
allow["AtLeastOneActionOnResource"] {
	# requested action is NONE
	input.requestedResource.action == "NONE"
	
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name
	
	# at least one action is allowed on resource 
	count(r.actions) > 0	
}

# Allow access when action is NONE and at least one action allowed is allowed for requested resource
allow["AtLeastOneActionOnObject"] {
	# Requested action is NONE
	input.requestedResource.action == "NONE"
	# requested contains uuids of specific objects
	input.requestedResource.uuids
	
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name

	# get all objects which has at least one action allowed
	uuidsOfObjectsWithOneOrMoreAllowedActions := [ uuid | 
		some o in r.objects
		count(o.allow) > 0
		uuid := o.uuid
	]

	# check that every object has at least one action allowed
	every uuid in input.requestedResource.uuids {
		uuid in uuidsOfObjectsWithOneOrMoreAllowedActions
	}
}

# TODO no uuids and NONE

# Allows access to anonymous users to selected set of resources
allow["Anonymous"] {
	# check if user is authenticated as anonymous
	input.principal.user.username = "anonymousUser"
	
	# define the set of allowed resources
	resourcesWithAnonymousAccess := [
		{ "resource": "connector", "action": "register"	}
	]
	
	# does the requested resource belong to the allowed resources
	requestedResource := {
		"resource": input.requestedResource.name,
		"action": input.requestedResource.action
	}
	requestedResource in resourcesWithAnonymousAccess	
}

# TODO parentUUIDS

# Deny access when requested action is forbidden for given object
deny["ActionDeniedForSpecificObject"] {
	# requested contains uuids of specific objects
	input.requestedResource.uuids
	
	# find requested resource between permissions
	some r in input.principal.permissions.resources
	r.name == input.requestedResource.name
	
	# get all objects uuids for which the action is allowed
	forbiddenUUIDs := [ uuid | 
		some o in r.objects
		input.requestedResource.action in o.deny
		uuid := o.uuid
	]
	
	# check whether the array of forbiddenUUIDs conatins some of the requested uuids
	some uuid in input.requestedResource.uuids 
	uuid in forbiddenUUIDs
}


default authorized = false