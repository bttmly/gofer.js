do ( $ = jQuery ) ->
  $.fn.splink = ( targetSelector, options, callback ) ->
  
    unless (window.sessionStorage and window.history.pushState)
      return
    
    config = 
      dataAttr    : "data-splink-selector"
      loadingClass: "splink-loading"
      animate     : false

    if options
      if $.isFunction(options)
        callback = options
        options = undefined
      else if $.isObject(options)
        $.extend(config, options)

    s = 
      session     : window.sessionStorage
      elements    : this
      $elements   : $(this)
      $selector   : $(this).selector
      $target     : $(targetSelector)
      $html       : $("html")
      $body       : $("body")
    
    ###
    window.bind "popstate", (event) ->
      s.$target.html(s.session[window.location.pathname])
      return
    ###

    s.$body.on "click", "#{s.$selector}", (event) ->
      event.preventDefault()

      e =
        link        : this
        href        : this.href
        path        : this.pathname
        $link       : $(this)
        subselector : $(this).attr(config.dataAttr)
      
      if s.session[e.path]
        s.$target.html(s.session[e.path])
        window.history.pushState(null, null, e.path)
        console.log "html pulled from sessionStorage"
        return
      else
        unless s.session[window.location.pathname]
          s.session[window.location.pathname] = s.$target.html()
        
        # slightly modified AJAX call cribbed from the jQuery.fn.load function
        # setting context gives us $(this) = s.$target in all callbacks.
        $.ajax(
          url        : e.href
          type       : "GET"
          dataType   : "html"
          context    : s.$target
          beforeSend : (xhr, settings) ->
            settings.context.addClass(config.loadingClass)
        ).done((responseText) ->
          e.html = do ->
            if s.subselector
              # If a selector was specified, locate the right elements in a dummy div
              # Exclude scripts to avoid IE 'Permission Denied' errors
              return jQuery("<div>").append(jQuery.parseHTML(responseText)).find(e.subselector) 
            else 
              # Otherwise use the full result 
              return responseText

          if e.html.length
            s.session[e.href] = $(this).html(e.html).html()
            window.history.pushState(null, null, e.href)
          else
            # figure out what to do with an empty response.
            console.warn("No HTML returned")

        ).fail((xhr, status, error) ->
          console.error(error)
        ).always((text, status, xhr) ->
          
          response =
            text : text
            status : status
            xhr : xhr

          $(this).removeClass(config.loadingClass)

          if callback?
            callback(response, $(this), e.html)
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
        ###

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