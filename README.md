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
- [x] ALE fixer for missing `:require` forms (WIP, but usable!)

[1]: https://github.com/tpope/vim-fireplace
[2]: https://github.com/w0rp/ale
[3]: https://github.com/dhleong/vim-mantel
[4]: https://github.com/borkdude/clj-kondo
[5]: https://github.com/clojure-emacs/refactor-nrepl
