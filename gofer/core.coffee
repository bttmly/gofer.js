$body = $( "body" )
Gofer.requestQueue = []
Gofer.pendingRequests = []
Gofer.maxRequests = 5

goferLinks = ->
	return $( Gofer.config.linkSelector )

goferPaths = ->
	for a in goferLinks()
		a.pathname

Gofer = window.Gofer or {}

Gofer.config = {}
Gofer.pages = {}

# Gofer.fnGofer is what is called when you run $(".links").gofer()
# thus, Gofer.fnGofer, "this" referrs to .links 
Gofer.fnGofer = ( targets, options ) ->

	Gofer.config.linkSelector = this.selector
	Gofer.config.contentTargets = targets

	switch Gofer.util.getType( targets )
		when "boolean"
			if not targets
				Gofer.goferOff()
				return this
		when "array"
			Gofer.config.targets = targets
		when "string"
			Gofer.config.targets = [targets]

	Gofer.loadLinks()

	$body.on "click", Gofer.config.linkSelector, ( event ) ->
    # Not the types of clicks we want.
    if event.which > 1 or event.metaKey or event.ctrlKey or event.shiftKey or event.altKey
      return this

    # This series of conditions is pilfered from pjax.
    if this.tagName.toUpperCase() isnt 'A'
      return this
    if location.protocol isnt this.protocol
      return this
    if location.hostname isnt this.hostname
      return this
    if this.hash and this.href.replace( this.hash, '' ) is location.href.replace( location.hash, '' )
      return this
    if this.href is location.href + '#'
      return this

    if Gofer.config.limit
      active = $( Gofer.config.linkSelector ).slice( 0, limit )
      return this unless $( this ).is( active )

    event.preventDefault()

    Gofer.clickHandler( event, this )


Gofer.clickHandler =  ( event, link ) ->

	path = link.pathname

	# if this matches, we have the page in memory
	if Gofer.pages[path]?.fragments
		Gofer.pages[path].renderAll()

	# if this matches, we have the page in sessionStorage
	else if window.sessionStorage.getItem( path )
		Gofer.pages[path] = new Gofer.Page
			url: path

		Gofer.pages[path]
		.retrieve()
		.renderAll()

	# otherwise, we need to go get it
	else
		Gofer.pages[path] = new Gofer.Page
			url: path

		Gofer.pages[path]
		.load()
		.then this.renderAll()

Gofer.loadLinks = ->
	for path, i in goferPaths()

		return if Gofer.config.limit and i > Gofer.config.limit

		unless Gofer.pages[path]

			if window.sessionStorage.getItem( path )
				Gofer.pages[path] = new Gofer.Page
					url: path

				Gofer.pages[path].retrieve()

			else
				Gofer.pages[path] = new Gofer.Page
					url: path

				Gofer.pages[path].load()
				

# Only retains in memory the pages that might be navigated to from this page
# Other pages sent to sessionStorage
Gofer.tidyStorage = ->

	pathsToKeep = goferPaths()

	for path, obj of Gofer.pages
		if Gofer.pages.hasOwnProperty( path ) and path not in pathsToKeep
				Gofer.pages[path].save
				delete Gofer.pages[path]

Gofer.requestNext = ->
	if pendingRequests.length < maxRequests
		
		path = requestQueue.shift()
		pendingRequests.push( path )

		if not Gofer.pages[path]
			Gofer.pages[path] = new Gofer.Page
				url: path

		Gofer.pages[path].load()

# whenever a request is queued, see if there are open spots
$.subscribe "gofer.queueRequest", ( event, page ) ->
	Gofer.tryRequestNext()

# whenever a request is returned, see if there are open spots
$.subscribe "gofer.loadSuccess", ( event, page ) ->
	Gofer.util.removeVals requestQueue, page.url
	Gofer.tryRequestNext()

# dev
$.subscribe "gofer", ( event, data... ) ->
	console.log event

$.subscribe "gofer.renderAll", ( event, page ) ->
	page.addToHistory()
	Gofer.tidyStorage()
	Gofer.loadLinks()



$.fn.gofer = Gofer.fnGofer