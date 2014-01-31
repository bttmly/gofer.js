Gofer = window.Gofer or {}

Gofer.util =
	# _.wrap from underscore.js
	wrap : ( func, wrapper ) ->
	    return ->
	      args = [func]
	      Array.prototype.push.apply args, arguments
	      return wrapper.apply this, args

	removeVals : ( arr, vals... ) ->
    for val in vals
      if ( spot = arr.indexOf( val ) ) isnt -1
        arr.splice( spot, 1 )
    return arr

  getType : ( obj ) ->
    unless obj?
      return String obj
    classToType =
      '[object Boolean]': 'boolean'
      '[object Number]': 'number'
      '[object String]': 'string'
      '[object Function]': 'function'
      '[object Array]': 'array'
      '[object Date]': 'date'
      '[object RegExp]': 'regexp'
      '[object Object]': 'object'
    return classToType[Object.prototype.toString.call( obj )]

$.fn.outerHTML = ->
	return $('<div>').append( $( this ).clone() ).html()