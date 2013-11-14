do ( $ = jQuery ) ->
  $.fn.splink = ( targetSelector, options, callback ) ->
  
    unless (window.sessionStorage and window.history.pushState)
      return
    
    defaults = 
      dataAttr     : "data-splink-selector"
      loadingClass : "splink-loading"
      prefetch     : false
      animate      : false

    if options
      if $.isFunction(options)
        callback = options
        options  = undefined
        settings = defaults
      else if $.isObject(options)
        settings = $.extend({}, defaults, options)
    
    # TODO determine which of these are necessary
    s = 
      session     : window.sessionStorage
      elements    : this
      $elements   : $(this)
      $selector   : $(this).selector
      $target     : $(targetSelector)
      $html       : $("html")
      $body       : $("body")
    
    if settings.prefetch
      $elements.each ->
        # get each.

    splinkLoad = (el, immediate, callback) ->
      html = undefined

      ###
      l =
        link        : el
        href        : el.href
        path        : el.pathname
        $link       : $(el)
        subselector : $(el).attr(settings.dataAttr)
      ###

      $.ajax
        url        : el.path
        type       : "GET"
        dataType   : "html"
        context    : s.$target

        # call back options...
        beforeSend : (xhr, settings) ->
          if immediate
            settings.context.addClass(settings.loadingClass)

        error : (xhr, status, error) ->
          console.error(error)

        success : (data, status, xhr) ->
          s.session[el.path] = html = do ->
            if el.subselector
              # If a selector was specified, locate the right elements in a dummy div
              # Exclude scripts to avoid IE 'Permission Denied' errors
              return $("<div>").append(jQuery.parseHTML(data)).find(el.subselector).html()
            else 
              # Otherwise use the full result 
              return data

          # need a more complete solution for empty response
          unless html.length
            console.warn "No HTML returned"

          # set the target's html if immediate
          if immediate
            state = 
              path : el.path
              target : s.$target
              tarHtml: s.session[el.path]
            window.history.pushState(state, null, el.path)
            s.$target.html(s.session[el.path])

        complete : (text, status, xhr) ->
          if immediate
            $(this).removeClass(settings.loadingClass)
          
          if callback?
            callback($(this), "ajax", status)

    setHtml = (element, html) ->
      element.html(html)

    # popstate handler
    # remove previously attached handlers before attaching
    # if we have multiple target areas, and thus multiple calls of splink, we don't want to repeatedly attach events.
    # since all instances of splink will be saving html to sessionStorage, we only need one popstate.
    $(window).off "popstate"
    $(window).on "popstate", (event) ->
      if s.session[window.location.pathname]
        s.$target.html(s.session[window.location.pathname])
      else
        window.location.pathname
      return

    s.$body.on "click", "#{s.$selector}", (event) ->
      event.preventDefault()
      
      # TODO determine which of these are necessary
      el =
        link        : this
        href        : this.href
        path        : this.pathname
        $link       : $(this)
        subselector : $(this).attr(settings.dataAttr)
      
      if s.session[el.path]
        state = 
          path    : el.path
          target  : s.$target
          tarHtml : s.session[el.path]
        window.history.pushState({
          path : el.path
          target : s.$target
          tarHtml : s.session[el.path]
        }, null, el.path)

        s.$target.html(s.session[el.path])
        
        callback(s.$target, "local", "success")
        
      else
        unless s.session[window.location.pathname]
          s.session[window.location.pathname] = s.$target.html()
          
        splinkLoad(el, true, callback)

        return
        
    return this
    
  return