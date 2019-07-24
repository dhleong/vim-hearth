vim-hearth
==========

*A nice place to call home*

## What?

hearth is a collection of utilities for Vim-based Clojure development that
originated in my dot files. It's still highly in flux, and as a result some
assumptions may not hold for all users, but feel free to submit a PR if you
find something that leans too hard on my own vimrc.

Required dependencies:

 - [vim-fireplace][1]

Optional (encouraged) dependencies:

- [ale][2]: we provide some extra async linting and fixits
- [vim-mantel][3]: for async semantic highlighting
- [fzf][4]: for choosing between candidates for auto-import
- [refactor-nrepl][5]: can improve auto import

Features:

- [x] Auto-require namespaces, asynchronously
- [x] Auto template filling for new files
- [x] Add indication for syntax errors that [clj-kondo][4] doesn't catch
- [x] Improved test-running tools (including support for Clojurescript)
- [x] Simplified Fireplace REPL connection
- [x] ALE fixer for missing `:require` forms
- [x] ALE fixer for `symbol already refers to something` errors

## How?

Install with your favorite plugin manager. I like [Plug][6]:

```vim
Plug 'dhleong/vim-hearth'
Plug 'tpope/vim-fireplace'
```

### Linting

To get linting and fixits, you'll need [ale][2]. Linting should come for free
when you save the file, as long as you don't disable auto-reloading. To fix
the issues we find, you'll need to enable the `hearth` fixer:

```vim
let g:ale_fixers = {
    \   'clojure': ['hearth'],
    \ }
```

### Improved test-running

hearth creates a `cpt` mapping that runs the associated test for the current
namespace, and works for both clojure and clojurescript tests, handling
both [Figwheel][7] and [shadow-cljs][8].

### Simpler REPL connection

hearth creates a `glc` mapping ("go lein connect") that attempts to determine
the repl port, etc. using a handful of different strategies to support
[Figwheel][7] and [shadow-cljs][8], as necessary.


[1]: https://github.com/tpope/vim-fireplace
[2]: https://github.com/w0rp/ale
[3]: https://github.com/dhleong/vim-mantel
[4]: https://github.com/borkdude/clj-kondo
[5]: https://github.com/clojure-emacs/refactor-nrepl
[6]: https://github.com/junegunn/vim-plug
[7]: https://github.com/bhauman/lein-figwheel
[8]: https://github.com/thheller/shadow-cljs
