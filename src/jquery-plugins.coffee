jQueryPlugins = [
  name : "outerHTML"
  value: ->
    elem = this[0]
    if !elem
      return null
    else
      if typeof ( tmp = elem.outerHTML ) is "string"
        return tmp
      else
        return $('<div/>').html( this.eq(0).clone() ).html()
,
  name : "findIn"
  value: ( selector ) ->
    this.filter( selector ).add this.find( selector )
]

# setup the plugins
makePlugins = ( plugins ) ->
  for plugin in plugins
    $.fn[plugin.name] = plugin.value

# teardown the plugins (avoid collisions in $.fn)
cleanUpPlugins = ( plugins ) ->
  for plugin in plugins
    $.fn[plugin.name] = undefined

makePlugins( jQueryPlugins )