# jquery.splink

### Sorta like PJAX, but for static HTML

Mimics jQuery's .load() method, but adds in the history API.

splink = **s**tatic **p**ushState **link**

### Use Case

The typical use case would be for a blog. Generally, users are navigating from post to post. The content of the post changes but probably nothing else does... so why reload the whole page? Instead, just swap out the current post's HTML for the new post's HTML.



```
<!-- HTML -->
<a class="post-link" href="/posts/my-new-post" data-splink-selector="article.post">My  New Post</a>
```

```
// JS
$("a.post-link").splink( ".post-holder", callback() )
```

The `data-splink-selector` attribute determines which part of the returned HTML to use. If omitted, the whole returned document will be used. Though the syntax and structure are different, it is inspired by jQuery's .load() method which takes as it's first argument a URL, and, optionally, a selector separated from the URL by a space. 