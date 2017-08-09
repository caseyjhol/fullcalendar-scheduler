
# NOTE: for public methods, always be sure of the return value. for chaining
Calendar_initEventManager = Calendar::initEventManager
Calendar_buildSelectFootprint = Calendar::buildSelectFootprint


Calendar::resourceManager = null


###
initializes resourceManager
unrelated to events! but could not hook into Calendar's constructor
TODO: fix
###
Calendar::initEventManager = ->
	Calendar_initEventManager.apply(this, arguments)

	@resourceManager = new ResourceManager(this)


Calendar::instantiateView = (viewType) ->
	spec = @getViewSpec(viewType)
	viewClass = spec['class']

	if @opt('resources') and spec.options.resources != false
		if spec.queryResourceClass
			viewClass = spec.queryResourceClass(spec) or viewClass # might return falsy
		else if spec.resourceClass
			viewClass = spec.resourceClass

	new viewClass(this, spec)


# for the API only
# retrieves what is currently in memory. no fetching
Calendar::getResources = ->
	Array.prototype.slice.call( # make a copy
		@resourceManager.topLevelResources
	)


Calendar::addResource = (resourceInput, scroll=false) -> # assumes all resources already loaded
	promise = @resourceManager.addResource(resourceInput)

	if scroll and @view.scrollToResource
		promise.then (resource) =>
			@view.scrollToResource(resource)

	return


Calendar::removeResource = (idOrResource) -> # assumes all resources already loaded
	@resourceManager.removeResource(idOrResource)


Calendar::refetchResources = -> # for API
	@resourceManager.clear()
	@view.flash('initialResources')
	return


Calendar::rerenderResources = -> # for API
	@resourceManager.resetCurrentResources()
	return


Calendar::buildSelectFootprint = (zonedStartInput, zonedEndInput, resourceId) ->
	plainFootprint = Calendar_buildSelectFootprint.apply(this, arguments)

	if resourceId
		new ResourceComponentFootprint(
			plainFootprint.unzonedRange,
			plainFootprint.isAllDay,
			resourceId
		)
	else
		plainFootprint


Calendar::getResourceById = (id) ->
	@resourceManager.getResourceById(id)


# Resources + Events
# ----------------------------------------------------------------------------------------


# DEPRECATED. for external API backwards compatibility
Calendar::getEventResourceId = (event) ->
	@getEventResourceIds(event)[0]


Calendar::getEventResourceIds = (event) ->
	eventDef = @eventManager.getEventDefByUid(event._id)

	if eventDef
		eventDef.getResourceIds()
	else
		[]


# DEPRECATED
Calendar::setEventResourceId = (event, resourceId) ->
	@setEventResourceIds(
		event
		if resourceId then [ resourceId ] else []
	)


Calendar::setEventResourceIds = (event, resourceIds) ->
	eventDef = @eventManager.getEventDefByUid(event._id)

	if eventDef
		eventDef.resourceIds =
			for rawResourceId in resourceIds
				Resource.normalizeId(rawResourceId)


# NOTE: views pair *segments* to resources. that's why there's no code reuse
Calendar::getResourceEvents = (idOrResource) ->
	resource =
		if typeof idOrResource == 'object'
			idOrResource
		else
			@getResourceById(idOrResource)

	if resource
		# return the event cache, filtered by events assigned to the resource
		# TODO: move away from using clientId
		@clientEvents (event) =>
			$.inArray(resource.id, @getEventResourceIds(event)) != -1
	else
		[]


# DEPRECATED. for external API backwards compatibility
Calendar::getEventResource = (idOrEvent) ->
	@getEventResources(idOrEvent)[0]


Calendar::getEventResources = (idOrEvent) ->
	event =
		if typeof idOrEvent == 'object'
			idOrEvent
		else
			@clientEvents(idOrEvent)[0]

	resources = []
	if event
		for resourceId in @getEventResourceIds(event)
			resource = @getResourceById(resourceId)
			if resource
				resources.push(resource)
	resources
