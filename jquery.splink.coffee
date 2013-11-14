do ( $ = jQuery ) ->
  $.fn.splink = ( targetSelector, options, callback ) ->
  
    unless (window.sessionStorage and window.history.pushState)
      return
    
    config = 
      dataAttr    : "data-splink-selector"
      loadingClass: "splink-loading"
      animate     : false
      cbAjaxOnly  : true

    if options
      if $.isFunction(options)
        callback = options
        options = undefined
      else if $.isObject(options)
        $.extend(config, options)
    
    # TODO determine which of these are necessary
    s = 
      session     : window.sessionStorage
      elements    : this
      $elements   : $(this)
      $selector   : $(this).selector
      $target     : $(targetSelector)
      $html       : $("html")
      $body       : $("body")
    
    window.addEventListener "popstate", (event) ->
      s.$target.html(s.session[window.location.pathname])
      return

    s.$body.on "click", "#{s.$selector}", (event) ->
      event.preventDefault()
      
      # TODO determine which of these are necessary
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
          url        : e.path
          type       : "GET"
          dataType   : "html"
          context    : s.$target
          beforeSend : (xhr, settings) ->
            settings.context.addClass(config.loadingClass)
            
        ).done((responseText) ->
          e.html = do ->
            if e.subselector
              # If a selector was specified, locate the right elements in a dummy div
              # Exclude scripts to avoid IE 'Permission Denied' errors
              return jQuery("<div>").append(jQuery.parseHTML(responseText)).find(e.subselector) 
            else 
              # Otherwise use the full result 
              return responseText
            
          if e.html.length
            s.session[e.path] = $(this).html(e.html).html()
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
        
        return
        
    return this
    
  return