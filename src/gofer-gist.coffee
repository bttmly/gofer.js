Gofer.Fragment::getGists = =>

    fragment = this
    fragment.gists = []
    gistIds = []

    fragment.$el
    .find( "script[src^='https://gist.github.com']" )
    .each ->
      urlPieces = this.src.split( "/" )
      id = urlPieces[ urlPieces.length - 1 ].split( "." )[0]
      $( this ).attr( "data-gist-id", id )

      gistIds.push id

    for id in gistIds
      fragment.gists.push new Gofer.Gist
        id: id
        parent: fragment

    $.subscribe "gofer.pageRenderAll", ( event, page ) ->
      if page.url is fragment.parent.url
        gist.render() for gist in fragment.gists

Gofer.Gist = class Gist
  constructor : ( options ) ->
    { @id, @parent } = options

    this.load()

  load : =>
    if this.request
      return this.request
    else 
      return this.request = $.ajax
        url      : "https://gist.github.com/#{ this.id }.json"
        type     : "GET"
        dataType : "jsonp"
        error : ( req, status, err ) ->
          $.publish "gofer.gistLoadError", [gist]   
        success : ( data, status, req ) ->
          $.publish "gofer.gistLoadSuccess", [gist]
          gist.loaded = true
          gist.json = data

  render : =>
    if not this.request
      return this.load().then this.render()
    $( "html" ).find( "[data-gist-id='#{ this.id }']" ).replaceWith $( this.json.div )
    $( "head" ).append( "<link rel='stylesheet' href='https://gist.github.com#{ this.json.stylesheet }'>" )
