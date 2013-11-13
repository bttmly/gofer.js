do ( $ = jQuery ) ->
  $.fn.splink = ( targetSelector, callback ) ->
  
    unless (window.sessionStorage and window.history.pushState)
      return
    
    session = window.sessionStorage
    # elements = @
    target = $(targetSelector)
    # html = $("html")
    # body = $("body")
    
    window.addEventListener "popstate", (event) ->
      target.html(session[window.location.pathname])
      return
    
    $("body").on "click", "a[data-splink-selector]", (event) ->
      event.preventDefault()
      
      link  = @
      $link = $(@)
      url  = link.href
      selector = $link.attr("data-splink-selector")
      # response  = undefined
      
      console.log "String passed to .load "
      console.log "#{url} #{selector}"
      
      
      if session[url]
        target.html(session[url])
        window.history.pushState(null, null, url)
      
      else
        
        unless session[window.location.pathname]
          session[window.location.pathname] = target.html()
          
        target.load "#{url} #{selector}", (response, status, xhr) ->
          if status is "error"
            console.log "#{xhr.status} #{xhr.statusText}"
          else
            window.history.pushState(null, null, url)
            session[window.location.pathname] = target.html()
          callback(response, status, xhr)
          return
