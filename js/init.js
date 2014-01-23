$(function() {

	window.sessionStorage.clear();

	$("#clear-storage").on("click", function(event) {
		console.log("sessionStorage keys before clear:")
		var key, _i, _len;
		for (_i = 0, _len = sessionStorage.length; _i < _len; _i++) {
		  key = sessionStorage[_i];
		  console.log(key);
		}
	  window.sessionStorage.clear();
	});

	$("#hard-reload").on("click", function(event) {
		window.location.reload()
	})

	$("a.gofer-link").gofer(
	  [{target: "div.content", selector: "same"},
	  {target: "div.navigation", selector: "same"}],
	  {
	  	prefetch: true, 
	  	animate: 250,
	  	runScripts: true
	  }
	);

	$("p.outside").html("This content generated on <code>$(document).ready()</code> from path " + window.location.pathname + " and is outside Gofer target elements.")

});