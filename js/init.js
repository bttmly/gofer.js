$(function() {

	window.sessionStorage.clear();

	$("a.gofer-link").gofer(
	  ["div.content", "div.navigation"], {
	  	beforeRender: function( targets ) {
	  		return $( targets ).fadeOut();
	  	},
	  	afterRender: function( targets, callback ) {
	  		return $( targets ).fadeIn();
	  	}
	  }
	);

	$("p.outside").html("This content generated on <code>$(document).ready()</code> from path " + window.location.pathname + " and is outside Gofer target elements.")

});