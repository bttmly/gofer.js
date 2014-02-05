# add getGists() method to page fragments
Gofer.Fragment::getGists = ->

    fragment = this
    fragment.gists = []
    gistIds = []

    fragment.$el
    .find( "script[src^='https://gist.github.com']" )
    .each ->
      urlPieces = this.src.split( "/" )
      id = urlPieces[ urlPieces.length - 1 ].split( "." )[0]
      #$( this ).attr( "data-gist-id", id )
      $( this ).replaceWith( "<div data-gist-id=#{ id }></div>" )

      gistIds.push id

    for id in gistIds
      fragment.gists.push new Gofer.Gist
        id: id
        parent: fragment

    $.subscribe "gofer.pageRenderAll", ( event, page ) ->
      if page.url is fragment.parent.url
        gist.render() for gist in fragment.gists

# gist class
Gofer.Gist = class Gist
  constructor : ( options ) ->
    { @id, @parent } = options

    this.load()

  load : =>
    gist = this
    if gist.request
      return gist.request
    else 
      return gist.request = $.ajax
        url      : "https://gist.github.com/#{ gist.id }.json"
        type     : "GET"
        dataType : "jsonp"
        error : ( req, status, err ) =>
          $.publish "gofer.gistLoadError", [err]
        success : ( data, status, req ) =>
          $.publish "gofer.gistLoadSuccess", [data]
          gist.json = data
          gist.$div = $( data.div )

  render : =>
    if not this.request
      return this.load().then this.render()
    console.log "GIST"
    console.log this
    this.parent.$el.find( "[data-gist-id='#{ this.id }']" ).replaceWith this.$div
    $( "head" ).append( "<link rel='stylesheet' href='https://gist.github.com#{ this.json.stylesheet }'>" )

# Get gists for each fragment added
$.subscribe "gofer.pageAdd", ( event, fragment ) ->
  fragment.getGists()