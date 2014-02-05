###
Tiny Pub/Sub - v0.7.0 - 2013-01-29
https://github.com/cowboy/jquery-tiny-pubsub
Copyright (c) 2013 "Cowboy" Ben Alman; Licensed MIT
###
do ( $ = jQuery ) ->

  hub = $ {}

  $.subscribe = ->
    hub.on.apply hub, arguments

  $.unsubscribe = ->
    hub.off.apply hub, arguments

  $.publish = ->
    hub.trigger.apply hub, arguments