// Generated by CoffeeScript 1.6.3
(function() {
  var Fragment, Page,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Gofer.Page = Page = (function() {
    function Page(url) {
      this.addToHistory = __bind(this.addToHistory, this);
      this.load = __bind(this.load, this);
      this.build = __bind(this.build, this);
      this.add = __bind(this.add, this);
      this.empty = __bind(this.empty, this);
      this.renderAll = __bind(this.renderAll, this);
      this.retrieve = __bind(this.retrieve, this);
      this.save = __bind(this.save, this);
      this.url = url;
      this.fragments = [];
      this.targets = Gofer.config.contentTargets;
    }

    Page.prototype.save = function() {
      var collection, fragment, _i, _len, _ref;
      collection = [];
      _ref = this.fragments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fragment = _ref[_i];
        collection.push(fragment.serialize());
      }
      window.sessionStorage.setItem(this.url, JSON.stringify(collection));
      $.publish("gofer.pageSave", [this]);
      return this;
    };

    Page.prototype.retrieve = function() {
      var fragment, obj, _i, _len;
      obj = JSON.parse(window.sessionStorage.getItem(this.url));
      for (_i = 0, _len = obj.length; _i < _len; _i++) {
        fragment = obj[_i];
        this.add({
          parent: this,
          html: fragment.html,
          $el: $(fragment.html),
          target: fragment.target
        });
      }
      $.publish("gofer.pageRetrieve", [this]);
      return this;
    };

    Page.prototype.renderAll = function() {
      var fragment, _i, _len, _ref;
      $("title").html(this.title);
      _ref = this.fragments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fragment = _ref[_i];
        fragment.render();
      }
      $.publish("gofer.pageRenderAll", [this]);
      return this;
    };

    Page.prototype.empty = function() {
      delete this.fragments;
      $.publish("gofer.pageEmpty", [this]);
      return this;
    };

    Page.prototype.add = function(options) {
      var frag;
      frag = new Fragment(options);
      this.fragments.push(frag);
      if (Gofer.config.preloadImages === true) {
        frag.preloadImages();
      }
      $.publish("gofer.pageAdd", frag);
      return frag;
    };

    Page.prototype.build = function(html) {
      var $html, fragmentHtml, target, _i, _len, _ref;
      this.raw = html;
      $html = $(html);
      this.title = $html.findIn("title").html();
      _ref = this.targets;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        target = _ref[_i];
        fragmentHtml = $html.find(target);
        this.add({
          parent: this,
          html: fragmentHtml,
          $el: $html.find(target),
          target: target
        });
      }
      $.publish("gofer.pageBuild", [this]);
      return this;
    };

    Page.prototype.load = function() {
      var page;
      page = this;
      if (this.request) {
        return this.request;
      }
      $.publish("gofer.pageLoadStart", [page]);
      return this.request = $.ajax({
        url: this.url,
        type: "GET",
        dataType: "html",
        error: function(req, status, err) {
          return $.publish("gofer.pageLoadError", [page]);
        },
        success: function(data, status, req) {
          $.publish("gofer.pageLoadSuccess", [page]);
          page.raw = data;
          return page.build(data);
        },
        done: function(data, status, req) {
          return $.publish("gofer.pageLoadDone", [page]);
        }
      });
    };

    Page.prototype.addToHistory = function() {
      window.history.pushState({
        path: this.url
      }, null, this.url);
      return this;
    };

    return Page;

  })();

  Gofer.Fragment = Fragment = (function() {
    function Fragment(options) {
      this.serialize = __bind(this.serialize, this);
      this.setHtml = __bind(this.setHtml, this);
      this.preloadImages = __bind(this.preloadImages, this);
      this.render = __bind(this.render, this);
      this.parent = options.parent, this.html = options.html, this.target = options.target, this.$el = options.$el;
      this.$target = function() {
        return $(this.target);
      };
      this.$html = $(this.html);
    }

    Fragment.prototype.render = function() {
      this.$target().replaceWith(this.$el);
      return this;
    };

    Fragment.prototype.preloadImages = function() {
      return this.$html.find("img").each(function() {
        var img;
        img = new Image();
        return img.src = this.src;
      });
    };

    Fragment.prototype.setHtml = function(contents) {
      if (contents instanceof jQuery) {
        this.$html = contents;
        return this.html = contents.html();
      } else {
        this.$html = $(contents);
        return this.html = contents;
      }
    };

    Fragment.prototype.serialize = function() {
      return {
        target: this.target,
        html: this.$html.outerHTML()
      };
    };

    return Fragment;

  })();

}).call(this);
