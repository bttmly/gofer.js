Gofer = window.Gofer or {}

Gofer.goferLinks = goferLinks = ->
  return $( Gofer.config.linkSelector )

Gofer.goferPaths = goferPaths = ->
  for a in goferLinks()
    a.pathname

Gofer.config =
  preloadImages : true

Gofer.pages = {}

Gofer.imageCache = []

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
  Gofer.buildPageFromDOM()

  $( "body" ).on "click", Gofer.config.linkSelector, ( event ) ->
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

  $( window ).on "popstate.gofer", ( event ) ->
    Gofer.popStateHandler( event )

Gofer.buildPageFromDOM = ->
  path = window.location.pathname
  page = new Gofer.Page path

  page.build $( "html" )[0].outerHTML

  return Gofer.pages[path] = page



Gofer.clickHandler =  ( event, link ) ->

  path = link.pathname

  # Gofer.config.beforeRender()

  # if this matches, we have the page in memory
  if Gofer.pages[path]?.fragments
    Gofer.pages[path].renderAll()

  # if this matches, we have the page in sessionStorage
  else if window.sessionStorage.getItem( path )
    Gofer.pages[path] = new Gofer.Page path

    Gofer.pages[path]
    .retrieve()
    .renderAll()

  # otherwise, we need to go get it
  else
    Gofer.pages[path] = new Gofer.Page path

    Gofer.pages[path]
    .load()
    .then this.renderAll()

  # Gofer.config.afterRender()

Gofer.pageByUrl = ( url ) ->
  if Gofer.pages[url]
    return Gofer.pages[url]

  else 
    Gofer.pages[url] = new Gofer.Page url

    if window.sessionStorage.getItem( url )
      Gofer.pages[url].retrieve()

    else
      Gofer.pages[url].load()

  return Gofer.pages[url]

Gofer.popStateHandler = ( event ) ->

  console.log event.originalEvent

  if event.originalEvent.state
    Gofer.pageByUrl( event.originalEvent.state.path ).renderAll()


Gofer.loadLinks = ->
  for path, i in goferPaths()

    console.log path

    # return if Gofer.config.limit and i > Gofer.config.limit

    if not Gofer.pages[path]

      Gofer.pages[path] = new Gofer.Page path

      if window.sessionStorage.getItem( path )
        Gofer.pages[path].retrieve()

      else
        Gofer.pages[path].load()
        

# Only retains in memory the pages that might be navigated to from this page
# Other pages sent to sessionStorage
Gofer.tidyStorage = ->

  pathsToKeep = goferPaths()

  for path, obj of Gofer.pages
    if Gofer.pages.hasOwnProperty( path ) and path not in pathsToKeep
        Gofer.pages[path].save()
        delete Gofer.pages[path]

Gofer.tryRequestNext = ->
  if Gofer.queue.pending().length < Gofer.queue.max()
    
    path = Gofer.queue.shiftQueue()
    Gofer.queue.pushPending( path )

    if not Gofer.pages[path]
      Gofer.pages[path] = new Gofer.Page path

    Gofer.pages[path].load()

Gofer.queue = do ->
  _max = 5
  _queue = []
  _pending = []
  max : -> return _max
  queue : -> return _queue
  pending : -> return _pending

  pushQueue : ( path ) ->
    _queue.push path

  shiftQueue : ->
    _queue.shift()

  pushPending : ( path ) ->
    _pending.push path

  removePending : ( path ) ->
    if ( spot = _pending.indexOf( path ) ) isnt -1
      _pending.splice( spot, 1 )
    return _pending

# # whenever a request is queued, see if there are open spots
# $.subscribe "gofer.queueRequest", ( event, page ) ->
#   Gofer.tryRequestNext()

# # whenever a request is returned, see if there are open spots
# $.subscribe "gofer.loadSuccess", ( event, page ) ->
#   Gofer.queue.removePending page.path
#   Gofer.tryRequestNext()

# dev
$.subscribe "gofer", ( event, data... ) ->
  console.log event

$.subscribe "gofer.renderAll", ( event, page ) ->
  console.log "renderAll #{ page.url }"
  page.addToHistory()
  Gofer.tidyStorage()
  Gofer.loadLinks()



$.fn.gofer = Gofer.fnGofer