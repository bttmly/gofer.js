Gofer.Page = class Page

  constructor : ( url ) ->
    this.url = url
    this.fragments = []
    this.targets = Gofer.config.contentTargets

  save : =>
    collection = []
    for fragment in this.fragments
      collection.push fragment.serialize()
    window.sessionStorage.setItem this.url, JSON.stringify( collection )

    $.publish "gofer.pageSave", [this]
    return this

  retrieve : =>
    obj = JSON.parse window.sessionStorage.getItem this.url
    console.log "retrieving #{ this.url }"
    console.log obj
    for fragment in obj
      this.add
        parent: this
        html: fragment.html
        $el: $( fragment.html )
        target: fragment.target

    $.publish "gofer.pageRetrieve", [this]
    return this

  renderAll : =>
    for fragment in this.fragments
      fragment.render()

    $.publish "gofer.pageRenderAll", [this]
    return this

  empty : =>
    delete this.fragments

    $.publish "gofer.pageEmpty", [this]
    return this

  add : ( options ) =>
    frag = new Fragment options
    this.fragments.push frag
    if Gofer.config.preloadImages is true
      frag.preloadImages()

    $.publish "gofer.pageAdd", [this, frag]
    return frag

  build : ( html ) =>
    this.raw = html
    $html = $( html ) 
    for target in this.targets
      fragmentHtml = $html.find( target )
      this.add
        parent: this
        html: fragmentHtml
        $el: $html.find( target )
        target: target

    $.publish "gofer.pageBuild", [this]
    return this

  load : =>
    page = this

    return this.request if this.request

    $.publish "gofer.pageLoadStart", [page]
    return this.request = $.ajax
      url      : this.url
      type     : "GET"
      dataType : "html"
      error : ( req, status, err ) ->
        $.publish "gofer.pageLoadError", [page]
      success : ( data, status, req ) ->
        $.publish "gofer.pageLoadSuccess", [page]
        page.raw = data
        page.build( data )
      done : ( data, status, req ) ->
        $.publish "gofer.pageLoadDone", [page]

  addToHistory : =>
    window.history.pushState( path : this.url, null, this.url )
    return this

Gofer.Fragment = class Fragment

  constructor : ( options ) ->

    { @parent, @html, @target, @$el } = options

    this.$target = -> $( this.target )
    this.$html = $( this.html )

  render : =>
    # this.$target.empty().append this.$html
    this.$target().replaceWith this.$el

    # if this.gists?.length
    #   gist.render() for gist in this.gists

    return this

  preloadImages : =>
    this.$html.find( "img" ).each ->
      img = new Image()
      img.src = this.src

  # keep html and $html in sync
  setHtml : ( contents ) =>
    if contents instanceof jQuery
      this.$html = contents
      this.html = contents.html()
    else
      this.$html = $ contents
      this.html = contents

  serialize : =>
    return {
      target : this.target
      html : this.$html.outerHTML()
    }