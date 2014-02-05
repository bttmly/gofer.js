window.Gofer = 
  pages : {}
  defaults :
    beforeRender : $.noop
    afterRender : $.noop
    customHeaders : {}
    customData : {}
    limit: 0
  config : {}

# returns links matching the passed selector
goferLinks = ->
  return $( Gofer.config.linkSelector )

# returns the pathnames of links matching the passed selector
goferPaths = ->
  for a in goferLinks()
    a.pathname

# Gofer.fnGofer is what is called when you run $(".links").gofer()
# thus, Gofer.fnGofer, "this" referrs to .links 
Gofer.fnGofer = ( targets, options ) ->

  options or= {}
  options.linkSelector = this.selector
  options.contentTargets = targets

  $.extend( Gofer.config, Gofer.defaults, options )

  # Gofer.buildConfig( targets, options )

  # start making AJAX requests for gofer links on the current page
  Gofer.loadLinks()

  # build a Gofer Page object from the current page.
  Gofer.buildPageFromDOM()

  Gofer.makeInitialHistoryEntry()

  # event handling for click
  $( "body" ).on "click", Gofer.config.linkSelector, ( event ) ->
    Gofer.clickHandler( event, this )

  # event handling for popstate
  $( window ).on "popstate", ( event ) ->
    Gofer.popStateHandler( event )

  # return jQuery object
  return this

# creates an entry in Gofer.pages for the current page
# returns the Gofer Page object for the current page
Gofer.buildPageFromDOM = ->
  path = window.location.pathname
  page = new Gofer.Page path
  page.build $( "html" ).outerHTML()
  return Gofer.pages[path] = page



Gofer.clickHandler =  ( event, link ) ->

  # Not the types of clicks we want.
  if event.which > 1 or event.metaKey or event.ctrlKey or event.shiftKey or event.altKey
    throw "Gofer doesn't trigger on shift+click, ctrl+click, alt+click, or mouse clicks on buttons besides the left one."
    return

  # This series of conditions is pilfered from pjax.
  if link.tagName.toUpperCase() isnt 'A'
    throw "Gofer requires an anchor tag"
    return
  if location.protocol isnt link.protocol
    throw "Gofer requires links to have the same protocol"
    return
  if location.hostname isnt link.hostname
    throw "Gofer requires links to have the same hostname"
    return
  if link.hash and link.href.replace( link.hash, '' ) is location.href.replace( location.hash, '' )
    throw "Gofer doesn't work on hash links"
    return
  if link.href is location.href + '#'
    throw "Gofer doesn't work on hash links"
    return

  # 
  if Gofer.config.limit
    active = $( Gofer.config.linkSelector ).slice( 0, limit )
    return unless $( this ).is( active )

  event.preventDefault()

  path = link.pathname

  console.log path

  Gofer.config.beforeRender()

  window.history.pushState( path: path, "", link.href )
  Gofer.pageByUrl( path, "renderAll" )

  Gofer.config.afterRender()

Gofer.pageByUrl = ( url, method ) ->

  if not Gofer.pages[url]
    Gofer.pages[url] = new Gofer.Page url
    if window.sessionStorage.getItem( url )
     return Gofer.pages[url].retrieve()
     if method
      return Gofer.pages[url][method]()
    else
      req = Gofer.pages[url].load()
      if method
        req.then ->
          Gofer.pages[url][method]()

  else if method
    return Gofer.pages[url][method]()

  else
    return Gofer.pages[url]

Gofer.cachePages = ( urls ) ->
  if util.getType urls is "string"
    urls = [urls]
  else if util.getType urls isnt "array"
    return

  for url in urls
    Gofer.pageByUrl( url )

Gofer.popStateHandler = ( event ) ->

  Gofer.popEvents = Gofer.popEvents or []
  Gofer.popEvents.push event

  if event.originalEvent.state
    p = Gofer.pageByUrl( event.originalEvent.state.path )
    console.log "popping to..."
    console.log p
    p.renderAll()

Gofer.makeInitialHistoryEntry = ->
  window.history.replaceState( path: window.location.pathname, "", window.location.pathname )

Gofer.loadLinks = ->
  for path, i in goferPaths()

    return if Gofer.config.limit and i > Gofer.config.limit

    Gofer.pageByUrl( path ) unless Gofer.pages[path]

  return Gofer.pages
  
      # Gofer.pages[path] = new Gofer.Page path

      # if window.sessionStorage.getItem( path )
      #   Gofer.pages[path].retrieve()

      # else
      #   Gofer.pages[path].load()
        

# Only retains in memory the pages that might be navigated to from this page
# Other pages sent to sessionStorage
Gofer.tidyStorage = ->

  pathsToKeep = goferPaths()

  for path, obj of Gofer.pages
    if Gofer.pages.hasOwnProperty( path ) and path not in pathsToKeep
        Gofer.pages[path].save()
        delete Gofer.pages[path]

# Gofer.tryRequestNext = ->
#   if Gofer.requests.pending().length < Gofer.requests.max()
    
#     path = Gofer.requests.shiftQueue()
#     Gofer.requests.pushPending( path )

#     if not Gofer.pages[path]
#       Gofer.pages[path] = new Gofer.Page path

#     Gofer.pages[path].load()

# Gofer.requests = do ->
#   _max = 5
#   _queue = []
#   _pending = []
#   _completed = []
#   max : -> return _max
#   queue : -> return _queue
#   pending : -> return _pending

#   pushQueue : ( path ) ->
#     _queue.push path
#     return _queue

#   shiftQueue : ->
#     return _queue.shift()

#   pushPending : ( path ) ->
#     _pending.push path
#     return _pending

#   removePending : ( path ) ->
#     if ( spot = _pending.indexOf( path ) ) isnt -1
#       _pending.splice( spot, 1 )
#     return _pending

#   progressRequests : ( previous ) ->
#     _completed.push previous

#     if Gofer.requests.pending().length < Gofer.requests.max()
    
#       path = Gofer.requests.shiftQueue()
#       Gofer.requests.pushPending( path )

#       if not Gofer.pages[path]
#         Gofer.pages[path] = new Gofer.Page path

#       Gofer.pages[path].load()

# # whenever a request is queued, see if there are open spots
# $.subscribe "gofer.queueRequest", ( event, page ) ->
#   Gofer.tryRequestNext()

# # whenever a request is returned, see if there are open spots
# $.subscribe "gofer.loadSuccess", ( event, page ) ->
#   Gofer.queue.removePending page.path
#   Gofer.tryRequestNext()

$.subscribe "gofer.pageRenderAll", ( event, page ) ->
  console.log "pageRenderAll #{ page.url }"
  # page.addToHistory()
  Gofer.tidyStorage()
  Gofer.loadLinks()


$.fn.gofer = Gofer.fnGofer