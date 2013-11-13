do ( $ = jQuery ) ->
  $.fn.splink = ( targetSelector, callback ) ->
  
    unless (window.sessionStorage and window.history.pushState)
      return
    
    opts = 
      dataAttr    : "data-splink-selector"
      htmlClass   : "splink-loading"
      animate     : false
    
    s = 
      session   : window.sessionStorage
      elements  : this
      $elements : $(this)
      $selector : $(this).selector
      $target   : $(targetSelector)
      $html     : $("html")
      $body     : $("body")
    
    window.addEventListener "popstate", (event) ->
      s.$target.html(s.session[window.location.pathname])
      return
    
    s.$body.on "click", "#{s.$selector}", (event) ->
      event.preventDefault()

      e =
        link        : this
        href        : this.href
        path        : this.pathname
        $link       : $(this)
        subselector : $(this).attr("data-splink-selector")
      
      if s.session[e.path]
        s.$target.html(s.session[e.path])
        window.history.pushState(null, null, e.path)
        console.log "html pulled from sessionStorage"
        return true
        
      else
        unless s.session[window.location.pathname]
          s.session[window.location.pathname] = s.$target.html()
        
        ###
        $.ajax(
        	url: url
        	type: "GET"
        	dataType: "html"
        	context: document.documentElement
        	beforeSend: (jqXHR, settings) ->
        		$(settings.context).addClass(opts.htmlClass)
        
        ).done(( responseText, textStatus, jqXHR ) ->
        	`response = arguments`
        	target.html if selector then $("<div>").append($.parseHTML(responseText)).find(selector) else responseText
        
        ).fail((jqXHR, textStatus, errorThrown ) ->
        	console.error errorThrown
        	
        ).always( ) ->
        	$(this).removeClass(opts.htmlClass)
        	callback({}, e.link)
        )
        ###
        
        s.$target.load "#{e.href} #{e.subselector}", (response, status, xhr) ->
          # console.log response
          # console.log status
          # console.log xhr
          if status is "error"
            console.log "#{xhr.status} #{xhr.statusText}"
          else
            window.history.pushState(null, null, e.href)
            s.session[window.location.pathname] = s.$target.html()
          callback(response, status, xhr)
          return
        return
    return this
  return
  
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