# µJS (muJS)

**Lightweight AJAX navigation library — accelerate your website without a JS framework.**

µJS intercepts clicks on links and form submissions to load pages via AJAX instead of full browser navigation. The fetched content replaces part (or all) of the current page, making navigation faster and smoother.

No build step required. No dependencies. No framework. Just a single `<script>` tag.

Inspired by [pjax](https://github.com/defunkt/jquery-pjax), [Turbo](https://turbo.hotwired.dev/) and [HTMX](https://htmx.org/), µJS aims to be simpler and lighter while covering the most common use cases.

- 🚀 **Fast** — Prefetch on hover, no full page reload, progress bar
- 🪶 **Lightweight** — Single file, ~3 KB gzipped, zero dependencies
- 🔌 **Drop-in** — Works with any backend (PHP, Python, Ruby, Go…), no server-side changes needed
- 🧩 **Patch mode** — Update multiple page fragments in a single request
- ✨ **Modern** — View Transitions, DOM morphing (via idiomorph), `fetch` API, event delegation


## Table of contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Modes](#modes)
- [Patch mode](#patch-mode)
- [Forms](#forms)
- [Ghost mode](#ghost-mode)
- [Scroll restoration](#scroll-restoration)
- [Prefetch](#prefetch)
- [DOM morphing](#dom-morphing)
- [View Transitions](#view-transitions)
- [Progress bar](#progress-bar)
- [Events](#events)
- [Attributes reference](#attributes-reference)
- [Configuration reference](#configuration-reference)
- [Programmatic API](#programmatic-api)
- [Browser support](#browser-support)
- [License](#license)


## Installation

### Via `<script>` tag (recommended)

```html
<script src="/path/to/mu.min.js"></script>
<script>mu.init();</script>
```

### Via CDN

```html
<!-- unpkg -->
<script src="https://unpkg.com/mujs/dist/mu.min.js"></script>

<!-- jsDelivr -->
<script src="https://cdn.jsdelivr.net/npm/mujs/dist/mu.min.js"></script>
```

### Via npm

```bash
npm install mujs
```


## Quick start

After calling `mu.init()`, all internal links (URLs starting with `/`) are automatically intercepted. Clicking a link fetches the page via AJAX and replaces the current `<body>` with the fetched `<body>`. The page title is updated automatically. Browser history (back/forward buttons) works as expected.

```html
<!DOCTYPE html>
<html>
<head>
    <title>My site</title>
    <script src="/path/to/mu.min.js"></script>
    <script>mu.init();</script>
</head>
<body>
    <!-- These links are automatically handled by µJS -->
    <nav>
        <a href="/">Home</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>
    </nav>

    <main id="content">
        <p>Page content here.</p>
    </main>

    <!-- This link is NOT handled (external URL) -->
    <a href="https://example.com">External link</a>

    <!-- This link is NOT handled (explicitly disabled) -->
    <a href="/file.pdf" mu-disabled>Download PDF</a>
</body>
</html>
```

To replace only a fragment of the page instead of the whole body:

```html
<a href="/about" mu-target="#content" mu-source="#content">About</a>
```

This fetches `/about`, extracts the `#content` element from the response, and replaces the current `#content` with it.


## Modes

The `mu-mode` attribute controls how fetched content is injected into the page. Default: `replace`.

| Mode | Description |
|---|---|
| `replace` | Replace the target node with the source node (default). |
| `update` | Replace the inner content of the target with the source's inner content. |
| `prepend` | Insert the source node at the beginning of the target. |
| `append` | Insert the source node at the end of the target. |
| `before` | Insert the source node before the target. |
| `after` | Insert the source node after the target. |
| `remove` | Remove the target node (source is ignored). |
| `none` | Do nothing to the DOM (events are still fired). |
| `patch` | Process multiple targeted fragments (see [Patch mode](#patch-mode)). |

Example:

```html
<a href="/notifications" mu-mode="update" mu-target="#notifs" mu-source="#notifs">
    Refresh notifications
</a>
```


## Patch mode

Patch mode allows a single request to update multiple parts of the page. The server returns HTML fragments, each annotated with a target and an optional mode.

### Link triggering a patch

```html
<a href="/api/comments/new" mu-mode="patch">Add comment</a>
```

### Server response

The server returns plain HTML. Each element with a `mu-patch-target` attribute is a patch fragment:

```html
<!-- Replaces #comment-42 (default mode: replace) -->
<div class="comment" mu-patch-target="#comment-42">
    Updated comment text
</div>

<!-- Appends a new comment to #comments -->
<div class="comment" mu-patch-target="#comments" mu-patch-mode="append">
    New comment
</div>

<!-- Updates the page title -->
<title mu-patch-target="title">New page title</title>

<!-- Adds a stylesheet -->
<link rel="stylesheet" href="/css/gallery.css"
      mu-patch-target="head" mu-patch-mode="append">

<!-- Removes an element -->
<div mu-patch-target="#old-banner" mu-patch-mode="remove"></div>
```

Patch fragments are standard HTML elements — no special tags needed. The `mu-patch-*` attributes are preserved on injected nodes for debugging.

The `mu-patch-mode` attribute accepts the same values as `mu-mode` (except `patch` and `none`). Default is `replace`.

### Patch and browser history

By default, patch mode does not modify browser history. To add the URL to history:

```html
<a href="/products?cat=3" mu-mode="patch" mu-patch-ghost="false">Filter</a>
```


## Forms

µJS intercepts form submissions. HTML5 validation (`reportValidity()`) is checked before any request.

### GET forms

Data is serialized as a query string. Behaves like a link.

```html
<form action="/search" method="get" mu-target="#results" mu-source="#results">
    <input type="text" name="q">
    <button type="submit">Search</button>
</form>
```

### POST forms

Data is sent as `FormData`. Ghost mode is enabled by default (POST responses should not be replayed via the browser back button).

```html
<form action="/comment/create" method="post">
    <textarea name="body"></textarea>
    <button type="submit">Send</button>
</form>
```

### POST form with patch response

```html
<form action="/comment/create" method="post" mu-mode="patch">
    <textarea name="body"></textarea>
    <button type="submit">Send</button>
</form>
```

Server response:

```html
<div class="comment" mu-patch-target="#comments" mu-patch-mode="append">
    <p>The new comment</p>
</div>

<form action="/comment/create" method="post" mu-patch-target="#comment-form">
    <textarea name="body"></textarea>
    <button type="submit">Send</button>
</form>
```

The new comment is appended to the list, and the form is replaced with a blank version.

### Custom validation

```html
<form action="/save" method="post" mu-validate="myValidator">...</form>
<script>
function myValidator(form) {
    return form.querySelector('#name').value.length > 0;
}
</script>
```

### Quit-page confirmation

Add `mu-confirm-quit` to a form. If any input is modified, the user is prompted before navigating away:

```html
<form action="/save" method="post" mu-confirm-quit>
    <input type="text" name="title">
    <button type="submit">Save</button>
</form>
```


## Ghost mode

Ghost mode prevents a navigation from being added to browser history and disables automatic scroll-to-top.

```html
<!-- Ghost mode on a single link -->
<a href="/panel" mu-ghost>Open panel</a>

<!-- Ghost mode globally -->
<script>mu.init({ ghost: true });</script>
```

In patch mode, ghost is enabled by default. Use `mu-patch-ghost="false"` to add the URL to history.


## Scroll restoration

When the user navigates with the browser's back/forward buttons, µJS automatically restores the scroll position to where it was before leaving the page. This works out of the box — no configuration needed.


## Prefetch

When enabled (default), µJS fetches the target page when the user hovers over a link, before they click. This saves ~100-300ms of perceived loading time.

The prefetch cache stores one entry per URL and is consumed on click.

```html
<!-- Disable prefetch on a specific link -->
<a href="/heavy-page" mu-prefetch="false">Heavy page</a>

<!-- Disable prefetch globally -->
<script>mu.init({ prefetch: false });</script>
```


## DOM morphing

When a morph library is available, µJS uses it for `replace` and `update` modes to preserve DOM state (input focus, scroll positions, video playback, CSS transitions, etc.).

µJS auto-detects [idiomorph](https://github.com/bigskysoftware/idiomorph). Just load it before µJS:

```html
<script src="/path/to/idiomorph.js"></script>
<script src="/path/to/mu.min.js"></script>
<script>mu.init();</script>
```

If idiomorph is not loaded, µJS falls back to direct DOM replacement. No error, no warning.

Disable morphing globally or per-element:

```html
<!-- Globally -->
<script>mu.init({ morph: false });</script>

<!-- Per-element -->
<a href="/page" mu-morph="false">Link</a>
```

To use a different morph library:

```javascript
mu.init();
mu.setMorph(function(target, html, opts) {
    myMorphLib.morph(target, html, opts);
});
```


## View Transitions

µJS uses the [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/Document/startViewTransition) when supported by the browser, providing smooth animated transitions between page states.

Enabled by default. Falls back silently on unsupported browsers.

```html
<!-- Disable globally -->
<script>mu.init({ transition: false });</script>

<!-- Disable per-element -->
<a href="/page" mu-transition="false">Link</a>
```


## Progress bar

A thin progress bar (3px, blue) is displayed at the top of the page during fetch requests. It requires no external stylesheet.

The bar element has `id="mu-progress"` and can be customized via CSS:

```css
#mu-progress {
    background: red !important;
    height: 5px !important;
}
```

Disable globally:

```html
<script>mu.init({ progress: false });</script>
```


## Events

µJS dispatches `CustomEvent` events on `document`. All events carry a `detail` object with `lastUrl` and `previousUrl`.

| Event | Cancelable | Description |
|---|---|---|
| `mu:init` | No | Fired after initialization. |
| `mu:before-fetch` | Yes | Fired before fetching. `preventDefault()` aborts the load. |
| `mu:before-render` | Yes | Fired after fetch, before DOM injection. `detail.html` can be modified. |
| `mu:after-render` | No | Fired after DOM injection. |
| `mu:fetch-error` | No | Fired on fetch failure or HTTP error. |

### Example: run code after each page load

```javascript
document.addEventListener("mu:after-render", function(e) {
    console.log("Loaded: " + e.detail.url);
    myApp.initWidgets();
});
```

### Example: cancel a navigation

```javascript
document.addEventListener("mu:before-fetch", function(e) {
    if (e.detail.url === "/restricted") {
        e.preventDefault();
    }
});
```

### Example: modify HTML before rendering

```javascript
document.addEventListener("mu:before-render", function(e) {
    e.detail.html = e.detail.html.replace("foo", "bar");
});
```

### Example: handle errors

```javascript
document.addEventListener("mu:fetch-error", function(e) {
    if (e.detail.status === 404) {
        alert("Page not found");
    }
});
```


## Attributes reference

All attributes support both `mu-*` and `data-mu-*` syntax.

| Attribute | Description |
|---|---|
| `mu-disabled` | Disable µJS on this element. |
| `mu-mode` | Injection mode (`replace`, `update`, `prepend`, `append`, `before`, `after`, `remove`, `none`, `patch`). |
| `mu-target` | CSS selector for the target node in the current page. |
| `mu-source` | CSS selector for the source node in the fetched page. |
| `mu-url` | Override the URL to fetch (instead of `href` / `action`). |
| `mu-prefix` | URL prefix for the fetch request. |
| `mu-title` | Selector for the title node. Supports `selector/attribute` syntax. Empty string to disable. |
| `mu-ghost` | Skip browser history and scroll-to-top. |
| `mu-ghost-redirect` | Skip history for HTTP redirections. |
| `mu-scroll-to-top` | Force (`true`) or prevent (`false`) scrolling to top. |
| `mu-morph` | Disable morphing on this element (`false`). |
| `mu-transition` | Disable view transitions on this element (`false`). |
| `mu-prefetch` | Disable prefetch on hover for this link (`false`). |
| `mu-post` | Force POST method on a link. |
| `mu-confirm` | Show a confirmation dialog before loading. |
| `mu-confirm-quit` | *(Forms)* Prompt before leaving if the form has been modified. |
| `mu-validate` | *(Forms)* Name of a JS validation function. Must return `true`/`false`. |
| `mu-patch-target` | *(Patch fragments)* CSS selector of the target node. |
| `mu-patch-mode` | *(Patch fragments)* Injection mode for this fragment. |
| `mu-patch-ghost` | Set to `false` to add the URL to browser history in patch mode. |


## Configuration reference

Pass an object to `mu.init()` to override defaults:

```javascript
mu.init({
    ghost: true,
    processForms: false,
    morph: false,
    progress: true
});
```

| Option | Type | Default | Description |
|---|---|---|---|
| `processLinks` | bool | `true` | Intercept `<a>` tags. |
| `processForms` | bool | `true` | Intercept `<form>` tags. |
| `ghost` | bool | `false` | Ghost mode for all navigations. |
| `ghostRedirect` | bool | `false` | Ghost mode for HTTP redirections. |
| `mode` | string | `"replace"` | Default injection mode. |
| `target` | string | `"body"` | Default target CSS selector. |
| `source` | string | `"body"` | Default source CSS selector. |
| `title` | string | `"title"` | Title selector (`"selector"` or `"selector/attribute"`). |
| `scrollToTop` | bool\|null | `null` | Scroll behavior. `null` = auto (scroll unless ghost). |
| `urlPrefix` | string\|null | `null` | Prefix added to fetched URLs. |
| `progress` | bool | `true` | Show progress bar during fetch. |
| `prefetch` | bool | `true` | Prefetch pages on link hover. |
| `morph` | bool | `true` | Enable DOM morphing (requires idiomorph or custom morph function). |
| `transition` | bool | `true` | Enable View Transitions API. |
| `confirmQuitText` | string | `"Are you sure you want to leave this page?"` | Quit-page confirmation message. |


## Programmatic API

```javascript
// Load a page programmatically
mu.load("/page", { ghost: true, target: "#content" });

// Get the last URL loaded by µJS
mu.getLastUrl();    // "/about" or null

// Get the previous URL
mu.getPreviousUrl();    // "/" or null

// Enable/disable quit-page confirmation
mu.setConfirmQuit(true);
mu.setConfirmQuit(false);

// Register a custom morph function
mu.setMorph(function(target, html, opts) {
    myMorphLib.morph(target, html, opts);
});
```


## Browser support

µJS works in all modern browsers:

- Chrome / Edge 89+
- Firefox 87+
- Safari 15+

View Transitions require Chrome/Edge 111+. On unsupported browsers, transitions are skipped silently.

DOM morphing requires a separate library (idiomorph recommended). Without it, µJS falls back to direct DOM replacement.

µJS does **not** support Internet Explorer.


## License

[MIT](LICENSE)

---

**µJS** is developed by [Digicreon](https://github.com/Digicreon).
Website: [mujs.org](https://mujs.org)

