do ( $ = jQuery ) ->
  $.fn.outerHTML = ( str ) ->
    if str then this.before( str ).remove() else $( "<p>" ).append( this.eq(0).clone() ).html()



do ( $ = jQuery ) ->

  # Internal.
  # Config is private
  # Can all modifications to config be made here? Let's hope so.
  # About these arguments...
  # context we get for free. It's "this" as passed to $.fn.splink.
  # where is required, at least if we get this far -- if where = false, we'll have exited already
  # we'll do an existential test for both options and callback.
  # options will get merged with defaults, and then merged into config.
  # if callback exists 
  # the preloadImg default is really clumsy; just guesses on screen width. 

  config = {}
  makeConfig = ( context, where, options, callback ) ->

    defaults = 
      loadingClass : "splink-loading"
      prefetch     : true
      limit        : 0
      animate      : 250
      stripOut     : false
      preloadImg   : true
      runScripts   : true
      customData   : {}
      customHeader : []

    config = 
      links   : context
      $links  : $(context)
      selector: $(context).selector
      $html   : $("html")
      $body   : $("body")
      $window : $(window)
      selectors : []
      targets   : []
      imgCache  : []
      $targets  : {}
      limit     : 0

    # the where argument can be an a boolean, a string, an object, or an array.
    # we've alrady handled the where = false case.
    # if it's a string, use that value for both target and selector
    # if it's an object, use where.target for target and where.selector for selector.
    # the DOM element of the target won't be changing, just the innerHTM, so we can cache the elements here for later.
    # if it's an array, it will be an array of objects so, where[0].selector is the first selector, where[0].target is the first target, etc.
    # we need to reference the target elements both sequentially and by name so we store each twice... is there a better way to do this?
    if typeof where is "string"
      config.targets[0]   = config.$targets[where] = $( where )
      config.selectors[0] = where
      
    else if $.isPlainObject( where )
      config.targets[0]   = config.$targets[where.target] = $( where.target )
      config.selectors[0] = if where.selector is "same" then where.target else where.selector
      
    else if $.isArray( where )
      for o, i in where
        config.targets[i]   = config.$targets[o.target] = $( o.target )
        config.selectors[i] = if o.selector is "same" then o.target else o.selector

    if options
      # If this argument is a function, assume it's the callback and no options are being passed.
      if $.isFunction( options )
        config.callback = options
        settings = defaults
        options  = {}
      # If it's an object, and callback exists, set config.callback 
      else if $.isPlainObject( options ) and callback
          config.callback = callback
    else
      options = {}

    return splinkConfiguration = $.extend( true, {}, defaults, options, config )

  # handleClick() is bound to elements matching the selector on which splink is called.
  handleClick = ( event, link ) ->

    path = link.pathname

    # Middle click, cmd click, and ctrl click should open
    # links in a new tab as normal.
    if event.which > 1 or event.metaKey or event.ctrlKey or event.shiftKey or event.altKey
      return

    # Check if we have it in storage. If so, grab the HTML and update the DOM with it.
    #   Then, if the callback exists, run it, with type = "local", indicating the HTML was retrieved from storage.
    # If we don't have it in storage, make an AJAX request for it.
    if window.sessionStorage[path]?
      putAndPush( path, true )
      if config.callback
        config.callback( config.targets, "local", "success" )
        return
    else
      splinkLoad( path )
      return

  splinkOff = ->
    config.$body.off( "click" )
    config.$window.off( "popstate" )    

  fnSplink = ( where, options, callback ) ->
    # Passing false as the first argument will turn off splink.
    #   Turn off bindings and finish.
    if typeof where is "boolean" and where is false
      splinkOff()
      return this
    
    config = makeConfig( this, where, options, callback )

    config.$body.on "click", "#{config.selector}", (event) ->

      if config.limit
        active = $(config.selector).slice(0, limit)
        return unless $(this).is(active)

      # This series of conditions are appropriated from pjax.
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

      event.preventDefault()

      handleClick( event, this )

    # This handles popstate events, generally, the back button
    # remove previously attached handlers before attaching
    # if we have multiple target areas, and thus multiple calls of splink, we don't want to repeatedly attach events (thus repeatedly firing them onpopstate)
    # since all instances of splink will be saving html to sessionStorage, we only need one popstate.
    $( window ).on "popstate", ( event ) ->
      handlePop( event )

    # We want to put the parts of the initial page that match the passed targets and selectors into sessionStorage.
    storeThisPage()

    # Start prefetching and storing pages.
    if config.prefetch
      beginPrefetch()

  handlePop = ( event ) ->
    state = event.originalEvent.state
    if state and window.sessionStorage[state.path]
      putAndPush( state.path, false )
    return

  # this mirrors the construction of a sessionStorage entry from the AJAX success callback option
  # but occurs on the initial page that splink is called on.
  storeThisPage = () ->
    
    tempArr = []

    for selector, i in config.selectors
      tempArr[i] = {}
      tempArr[i].html = $( selector ).html() or "oops"
      tempArr[i].target = config.targets[i].selector

    window.sessionStorage.setItem( window.location.pathname, JSON.stringify( tempArr ) )

  beginPrefetch = () ->

    $links = $( config.selector )

    if config.limit
      $links = $links.slice( 0, limit )

    $links.each ( i ) ->
      path = this.pathname
      if window.sessionStorage.getItem( path )?
      else
        queueRequest( path, false )
      return

    return

  injectScriptTags = ->
    $( ".script-placeholder" ).each ->
      replacer = $("<script>")
      for key, val of $( this ).data()
        replacer.attr( key, val )
      $( this ).replaceWith( replacer )


  # really need to pick a better name for this.
  putAndPush = ( path, pushIt ) ->

    partials = JSON.parse( window.sessionStorage.getItem( path ) )
    first = true

    actualPut = ->
      for partial, i in partials
        config.$targets[partial.target].html( partial.html )
      if config.runScripts
        injectScriptTags()
      if pushIt
        actualPush()
      if config.prefetch
        beginPrefetch()
      return

    actualPush = ->
      window.history.pushState( {path : path}, null, path )
      return

    if config.animate
      duration = if typeof config.animate is "boolean" then 250 else config.animate
      $( config.selectors.join( ", " ) ).animate
        opacity: 0, duration, ->
          if first is true
            first = false
            actualPut()
          $( this ).animate
            opacity: 1, duration
    else
      actualPut()

    config.$window.trigger( "splinkUpdate", config.selectors )
    return

    # public
    # this function is where AJAX requests are issued.
    # arguments:
    # path -- the pathname used in the url request. All requests kept to this host & protocol.
    # immediate -- load the HTML into the target elements as soon as the request finishes? optional boolean
    #   requests from beginPrefetch() have immediate = false
    #   requests initiated by a click event have immediate = true
    # config -- internally, we'll be passing around the config object.
    #           a public call to this would have to be an object with targets and selectors properties, and optionally a callback property
    #           targets should be an array of jQuery objects representing where HTML should be inserted
    #           selectors should be an array of CSS selector strings, used to find HTML snippets in the returned document. 
    #             They're associated with the target at the same array index position.

  splinkLoad = ( path, immediate ) ->

    if immediate
      config.$html.addClass(config.loadingClass)

    $.ajax
      url      : path
      type     : "GET"
      dataType : "html"
      context  : config.$html
      data     : config.customData

      beforeSend : ( xhr ) ->
        unless $.isEmptyObject( config.customHeader )
          xhr.setRequestHeader( config.customHeader[0], config.customHeader[1] )

      error : ( xhr, status, error ) ->
        console.error( error ) 

      success : ( data, status, xhr ) ->

        tempArr = []
        window.splinkScripts or= []
        
        $data = $( data )

        
        if config.runScripts

          console.log $( data ).find( ".content" )
          $data.find( "script" ).each (i, el) ->
            replacer = $("<div class='script-placeholder'>")
            $.each this.attributes, ( i, attr ) ->
              replacer.attr( "data-#{ attr.name }", attr.value )
            $( this ).replaceWith( replacer )

        for selector, i in config.selectors

          tempArr[i] = {}
          tempArr[i].html = $( "<div>" ).append( $data ).find( selector ).html() or "oops"
          # tempArr[i].html = $data.find(selector).html()
          tempArr[i].target = config.targets[i].selector
          if not immediate and config.preloadImg
            preloadImages( tempArr[i].html )



        window.sessionStorage.setItem( path, JSON.stringify( tempArr ) )

        if immediate
          putAndPush( path, true )

        else
          shiftQueue( path )

      complete : ( text, status, xhr ) ->

        console.log ( "request to #{path} complete: #{status}" )

        if immediate
          $(this).removeClass( config.loadingClass )
        
          if config.callback

            targets = for element in config.targets
              element.selector

            config.callback( targets, "ajax", status )

  preloadImages = ( htmlString ) ->

    images = $( htmlString ).find( "img" )
    i = 0

    while i < images.length
      image = images.eq(i)
      src = image.attr( "src" )

      unless src in config.imgCache
        img = new Image()
        img.src = src
        config.imgCache.push(src)

      i++

    return images

  # private object
  # max set to 5 by default since most browsers set a limit of 6 ajax requests to the same domain
  # we want to leave one slot open for a click event, which will fire an immediate AJAX request
  prefetch =
    max     : 5
    pending : []
    queue   : []

  # Every request that is not immediate is passed to this for queueing. 
  # First, check if URL is already in queue or pending; if so we don't need to proceed.
  # Next, see if the number of pending requests is less than the maximum number of allowed requests (prefetch.max)
  #   If so, we can make the request immediately and add this URL to the list of pending requests
  #   Otherwise, save it in the queue for later.
  #
  # ** This function needs a better name since queueRequest() is not really accurate.
  #
  queueRequest = ( url ) ->
    if url in prefetch.queue or url in prefetch.pending
      return
    else
      if prefetch.pending.length < prefetch.max
        prefetch.pending.push( url )
        splinkLoad( url, false )
      else
        prefetch.queue.push( url )

  # This is fired by the complete callback on every AJAX request.
  # prev is the path of the request that completed.
  # We remove it from the array of pending requests
  # Then, get the next URL in the queue and pass it to queueRequest()
  shiftQueue = ( prev ) ->
    utils.removeVals( prefetch.pending, prev )
    url = prefetch.queue.shift()
    if url
      queueRequest( url )

  # Public function
  splinkGo = ( path ) ->
    splinkLoad( path, true )

  # Public function
  splinkCache = ( path ) ->
    queueRequest( path )

  attach = ->
    $.fn.splink      = fnSplink
    $.splink         = {}
    $.splink.go      = splinkGo
    $.splink.cache   = splinkCache
    $.splink.click   = handleClick
    $.splink.attach  = $.noop
    $.splink.detatch = detatch

  detatch = ->
    $.fn.splink      = $.noop
    $.splink         = {}
    $.splink.go      = $.noop
    $.splink.cache   = $.noop
    $.splink.click   = $.noop
    $.splink.attach  = attach
    $.splink.detatch = $.noop

  $.support.pjax = 
  window.history and
  window.history.pushState and
  window.sessionStorage and
  not navigator.userAgent.match( /((iPod|iPhone|iPad).+\bOS\s+[1-4]|WebApps\/.+CFNetwork)/ )

  if $.support.pjax then attach() else detatch()

  utils = ->

  utils.removeVals = ( arr, vals... ) ->
    for val in vals
      if (spot = arr.indexOf(val)) isnt -1
        arr.splice(spot, 1)
    return arr

  return

#