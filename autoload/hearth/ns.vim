func! s:onFileLoaded(bufnr, resp) abort
    " file has been loaded

    " check for lint
    call hearth#lint#CheckResponse(a:bufnr, a:resp)

    if bufnr('%') == a:bufnr
        " if we have mantel, kick off a highlight proc after the
        try
            call mantel#Highlight()
        catch /E117/
            " not installed; ignore
        endtry
    endif
endfunc

func! hearth#ns#Undef(symbol)
    " Un-define the given symbol in the current ns

    if !fireplace#op_available('undef')
        echom 'hearth: refactor-nrepl middleware is required'
        return
    endif

    let resp = fireplace#message({
        \ 'op': 'undef',
        \ 'symbol': a:symbol,
        \ })
    if empty(resp) || has_key(resp[0], 'err')
        echom resp[0].err
    endif
endfunc

func! hearth#ns#TryRequire(...)
    " :Require the current ns, but only if there's an active session

    let bufnr = a:0 ? a:1 : bufnr('%')
    let ext = expand('#' . bufnr . ':e')

    if !hearth#util#SessionExists()
        return
    endif

    if &autowrite || &autowriteall
        silent! wall
    endif

    try
        let Callback = function('s:onFileLoaded', [bufnr])
        if ext ==# 'cljs' && fireplace#op_available('load-file')
            call fireplace#message({
                \ 'op': 'load-file',
                \ 'file-path': expand('#' . bufnr . ':p'),
                \ }, Callback)
        else
            " adapted from fireplace
            let ns = fireplace#ns()
            if ext ==# 'cljs'
                let path = hearth#path#FromNs(ns, ext)
                let code = '(load-file ' . hearth#util#Stringify(path) . ')'
            else
                let sym = hearth#util#Symbolify(ns)
                let code = '(clojure.core/require ' . sym . ' :reload)'
            endif

            call fireplace#message({
                \ 'op': 'eval',
                \ 'code': code,
                \ }, Callback)
        endif
    catch /Fireplace:.*REPL/
        redraw! | echohl Error | echo 'No REPL found' | echohl None
    catch /nREPL/
        redraw! | echohl Error | echo 'No REPL found' | echohl None
    endtry
endfunc
