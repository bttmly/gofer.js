// Generated by CoffeeScript 1.6.3
var $body, Gofer, goferLinks, goferPaths, maxRequests, pendingRequests, requestQueue,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

$body = $("body");

requestQueue = [];

pendingRequests = [];

maxRequests = 5;

goferLinks = function() {
  return $(Gofer.config.linkSelector);
};

goferPaths = function() {
  var a, _i, _len, _ref, _results;
  _ref = goferLinks();
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    a = _ref[_i];
    _results.push(a.pathname);
  }
  return _results;
};

Gofer = window.Gofer || {};

Gofer.fnGofer = function(targets, options) {
  Gofer.config.linkSelector = this.selector;
  Gofer.config.contentTargets = targets;
  switch (Gofer.util.getType(targets)) {
    case "boolean":
      if (!targets) {
        Gofer.goferOff();
        return this;
      }
      break;
    case "array":
      Gofer.config.targets = targets;
      break;
    case "string":
      Gofer.config.targets = [targets];
  }
  Gofer.loadLinks();
  return $body.on("click", Gofer.config.linkSelector, function(event) {
    var active;
    if (event.which > 1 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
      return this;
    }
    if (this.tagName.toUpperCase() !== 'A') {
      return this;
    }
    if (location.protocol !== this.protocol) {
      return this;
    }
    if (location.hostname !== this.hostname) {
      return this;
    }
    if (this.hash && this.href.replace(this.hash, '') === location.href.replace(location.hash, '')) {
      return this;
    }
    if (this.href === location.href + '#') {
      return this;
    }
    if (Gofer.config.limit) {
      active = $(Gofer.config.linkSelector).slice(0, limit);
      if (!$(this).is(active)) {
        return this;
      }
    }
    event.preventDefault();
    return Gofer.clickHandler(event, this);
  });
};

Gofer.clickHandler = function(event, link) {
  var path, _ref;
  path = link.pathname;
  if ((_ref = Gofer.pages[path]) != null ? _ref.fragments : void 0) {
    return Gofer.pages[path].renderAll();
  } else if (window.sessionStorage.getItem(path)) {
    return Gofer.pages[path] = new Gofer.Page({
      url: path
    }).retrieve().renderAll();
  } else {
    return Gofer.pages[path] = new Gofer.Page({
      url: path
    }).load().then(this.build());
  }
};

Gofer.loadLinks = function() {
  var i, path, _i, _len, _ref;
  _ref = goferPaths();
  for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
    path = _ref[i];
    if (Gofer.config.limit && i > Gofer.config.limit) {
      return;
    }
    if (!Gofer.pages[path]) {
      if (window.sessionStorage.getItem(path)) {
        Gofer.pages[path] = new Gofer.Page({
          url: path
        }).retrieve();
      } else {
        Gofer.pages[path] = new Gofer.Page({
          url: path
        }).load();
      }
    }
  }
};

Gofer.tidyStorage = function() {
  var obj, path, pathsToKeep, _ref, _results;
  pathsToKeep = goferPaths();
  _ref = Gofer.pages;
  _results = [];
  for (path in _ref) {
    obj = _ref[path];
    if (Gofer.pages.hasOwnProperty(path) && __indexOf.call(pathsToKeep, path) < 0) {
      Gofer.pages[path].save;
      _results.push(delete Gofer.pages[path]);
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

Gofer.requestNext = function() {
  var path;
  if (pendingRequests.length < maxRequests) {
    path = requestQueue.shift();
    pendingRequests.push(path);
    if (!Gofer.pages[path]) {
      Gofer.pages[path] = new Gofer.Page({
        url: path
      });
    }
    return Gofer.pages[path].load();
  }
};

$.subscribe("gofer.queueRequest", function(event, page) {
  return Gofer.tryRequestNext();
});

$.subscribe("gofer.loadSuccess", function(event, page) {
  Gofer.util.removeVals(requestQueue, page.url);
  return Gofer.tryRequestNext();
});

$.subscribe("gofer", function() {
  var data, event;
  event = arguments[0], data = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  return console.log(event);
});

$.subscribe("gofer.renderAll", function(event, page) {
  page.addToHistory();
  Gofer.tidyStorage();
  return Gofer.loadLinks();
});