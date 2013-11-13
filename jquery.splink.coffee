###
This is the JS for jQuery.load()

jQuery.fn.load = function( url, params, callback ) {
	if ( typeof url !== "string" && _load ) {
		return _load.apply( this, arguments );
	}

	var selector, response, type,
		self = this,
		off = url.indexOf(" ");

	if ( off >= 0 ) {
		selector = url.slice( off, url.length );
		url = url.slice( 0, off );
	}

	// If it's a function
	if ( jQuery.isFunction( params ) ) {

		// We assume that it's the callback
		callback = params;
		params = undefined;

	// Otherwise, build a param string
	} else if ( params && typeof params === "object" ) {
		type = "POST";
	}

	// If we have elements to modify, make the request
	if ( self.length > 0 ) {
		jQuery.ajax({
			url: url,

			// if "type" variable is undefined, then "GET" method will be used
			type: type,
			dataType: "html",
			data: params
		}).done(function( responseText ) {

			// Save response for use in complete callback
			response = arguments;

			self.html( selector ?

				// If a selector was specified, locate the right elements in a dummy div
				// Exclude scripts to avoid IE 'Permission Denied' errors
				jQuery("<div>").append( jQuery.parseHTML( responseText ) ).find( selector ) :

				// Otherwise use the full result
				responseText );

		}).complete( callback && function( jqXHR, status ) {
			self.each( callback, response || [ jqXHR.responseText, status, jqXHR ] );
		});
	}

	return this;
};


###


###

markup:

	<a href="/this/that.html" data-splink-selector=".post" data-splink-group="post">This link</a>


original load syntax
$(targetElement).load(url, function() {
  // callback
});

spload syntax
$(links).splink(targetSelector, function() {
	
})

this way you can give different data-attrs or classes of links or whatever different targets.
###



do ( $ = jQuery ) ->
	$.fn.splink = ( targetSelector, callback ) ->
		# no point in proceeding if we don't have these.
		return if not (window.sessionStorage and window.history.pushState)
		
		session   = window.sessionStorage
		elements	= @
		target    = $(targetSelector)
		
		window.addEventListener "popstate", (e) ->
			target.html(session[window.location.pathname])

		@each ->
			link  = @
			$link = $(@)
			url  = link.href
			selector = $link.attr("data-splink-selector")
			response 	= undefined

			$link.click (event) ->
				event.preventDefault

				if session[url]
					target.html(session[url])
				else
					session[window.location.pathname] = target.html()

					$.ajax(
						url: url
						type: "GET"
						dataType: "html"
					).done(( responseText ) ->

						# CoffeeScript flubs arguments to _arguments, so use a short embedded JS string here.
						`response = arguments`						

						# cribbed from .load
						target.html if selector then $("<div>").append($.parseHTML(responseText)).find(selector) else responseText

					).complete( callback and (jqXHR, status) ->
						self.each( callback, response or [ jqXHR.responseText, status, jqXHR ] )
					)