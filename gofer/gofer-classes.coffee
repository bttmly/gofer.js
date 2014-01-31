set = window.sessionStorage.setItem
get = window.sessionStorage.getItem

Gofer = window.Gofer or {}

Gofer.Page = class Page

  constructor : ( url ) ->

    this.url = url
    this.fragments = []
    this.targets = Gofer.config.contentTargets

    this.loaded = false

  save : =>
    collection = []
    for fragment in this.fragments
      collection.push fragment.serialize()
    window.sessionStorage.setItem this.url, JSON.stringify( collection )
    return this

  retrieve : =>
    for fragment in JSON.parse window.sessionStorage.getItem this.url
      this.add
        parent: this
        html: fragment.html
        target: fragment.target
    this.loaded = true
    return this

  renderAll : =>
    for fragment in this.fragments
      fragment.render()
    $.publish "gofer.renderAll", this
    return this

  empty : =>
    delete this.fragments
    return this

  add : ( options ) =>
    frag = new Fragment options
    this.fragments.push frag
    if Gofer.config.preloadImages is true
      frag.preloadImages()
    return frag

  build : ( html ) =>
    $html = $( html ) 
    for target in this.targets
      fragmentHtml = $html.find( target ).html()
      this.add
        parent: this
        html: fragmentHtml
        target: target

    # add preload image call here?
    return this

  load : =>

    page = this

    return $.ajax
      url      : this.url
      type     : "GET"
      dataType : "html"

      error : ( req, status, err ) ->
        $.publish "gofer.pageLoadError", [page]     

      success : ( data, status, req ) ->
        $.publish "gofer.pageLoadSuccess", [page]
        page.loaded = true
        page.build( data )

      done : ( data, status, req ) ->
        if this.waiting then this.deferred.resolve()    

  addToHistory : =>
    window.history.pushState( path : this.url, null, this.url )
    return this

Gofer.Fragment = class Fragment

  constructor : ( options ) ->

    { @parent, @html, @target } = options

    this.$target = $( this.target )
    this.$html = $( this.html )
    
    this.gists = []

    this.getGists()

  render : =>
    this.$target.empty().append( this.$html )
    return this

  preloadImages : =>
    this.$html.find( "img" ).each ->
      src = this.src
      unless src in Gofer.imageCache
        img = new Image()
        img.src = src
        Gofer.imageCache.push src

  getGists : =>

    fragment = this
    gistBaseUrl = "https://gist.github.com"
    gistIds = []
    $html = $( "<div>#{ fragment.html }</div>" )

    $html
    .find( "script" )
    .filter ->
      return this.src.substring( 0, gistBaseUrl.length ) is gistBaseUrl
    .each ->
      urlPieces = this.src.split( "/" )
      id = urlPieces[ urlPieces.length - 1 ].split( "." )[0]
      $( this ).replaceWith $( "<div data-gist-placeholder='#{ id }'></div>" )

      gistIds.push id

    fragment.html = $html.html()
    fragment.$html = $ fragment.html
    
    for id in gistIds
      fragment.gists.push new Gofer.Gist
        id: id
        parent: fragment

  serialize : =>
    return {
      target : this.target
      html : this.$html.html()
    }


Gofer.Gist = class Gist
  constructor : ( options ) ->
    { @id, @parent } = options
    this.loaded = false

    this.load()

  load : =>
    gist = this
    return $.ajax
      url      : "https://gist.github.com/#{ this.id }.json"
      type     : "GET"
      dataType : "jsonp"
      error : ( req, status, err ) ->
        $.publish "gofer.gistLoadError", [gist]     
      success : ( data, status, req ) ->
        $.publish "gofer.gistLoadSuccess", [gist]
        gist.loaded = true
        gist.json = data
        gist.render()
      done : ( data, status, req ) ->

  render : =>

    unless this.loaded
      return this.load().then this.render()

    gistElement = $( this.json.div )

    $html = $( "<div>#{ this.parent.html }</div>" )

    $html.find( "[data-gist-placeholder='#{ this.id }']" ).replaceWith gistElement

    $html.prepend( "<link rel='stylesheet' href='https://gist.github.com/#{ this.json.stylesheet }'>" )

    this.parent.html = $html.html()
    this.parent.$html = $ this.parent.html 




