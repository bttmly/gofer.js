set = window.sessionStorage.setItem
get = window.sessionStorage.getItem

Gofer = window.Gofer or {}

class Gofer.Request extends Object

  constructor : ( options ) ->

  pushQueue : ( p ) ->
    Gofer.Request.prototype.queue.push( p )

  shiftQueue : ->
    return Gofer.Request.prototype.queue.shift()

  max : 5
  queue: []
  pending: []

class Gofer.Page extends Object

  constructor : ( options ) ->
    if options.fragments 
      this.fragments = for fragment in fragments
        this.add fragment
    else
      this.fragments = []

    this.url = options.url
    this.targets = Gofer.config.contentTargets

    return this

  save : ->
    collection = []
    for fragment in this.fragments
      collection.push fragment.serialize
    set JSON.stringify( collection )
    return this

  retrieve : ->
    for fragment in JSON.parse get this.url
      this.add fragment
    return this

  renderAll : ->
    for fragment in this.fragments
      fragment.render()
    if Gofer.history is true then this.addToHistory()
    return this

  empty : ->
    delete this.fragments
    return this

  add : ( options ) ->
    this.fragments.push new Fragment options
    return this

  build : ( html ) ->
    $html = $( html ) 
    for target in this.targets
      fragmentHtml = $html.find( selector ).html()
      this.add
        html: fragmentHtml
        target: target
    # add preload image call here?
    return this

  load : ->
    return $.ajax
      url      : this.path
      type     : "GET"
      dataType : "html"

    error : ( req, status, err ) =>
      $.publish "gofer.loadError", [this]     

    success : ( data, status, req ) =>
      $.publish "gofer.loadSuccess", [this]
      this.build( data )

    done : ( data, status, req ) =>
      if this.waiting then this.deferred.resolve()

  queue : ->

    requestQueue.push this.url
    $.publish "gofer.queueRequest", this

    this.deferred = $.Deferred
    return this.deferred
    

  addToHistory : ->
    window.history.pushState( path : this.path, null, this.path )
    return this

class Gofer.Fragment extends Object

  constructor : ( options ) ->

    this.html = options.html
    this.target = options.target

    this.$target = $( this.target )
    this.$html = $( this.html )

  render : ->
    this.$target.empty().append( this.$html )
    return this

  preloadImages : ->
    this.$html.find( "img" ).each ->
      src = $( this ).src
      unless src in Gofer.imageCache
        img = new Image()
        img.src = src
        Gofer.imageCache.push src

  serialize : ->
    return JSON.stringify
      target : this.target
      html : this.html

# publish gofer.{method} event whenever a method is called
wrapMethodPublish = ( proto ) ->
  for key in Object.keys proto
    if typeof proto[key] is "function"
      proto[key] = Gofer.util.wrap proto[key], ( func ) ->
        func( arguments )
        $.publish "gofer.#{ key }", [this]

wrapMethodPublish( Gofer.Page.prototype )
wrapMethodPublish( Gofer.Fragment.prototype )





