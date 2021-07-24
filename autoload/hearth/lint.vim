func! s:cljErrToLint(err) " {{{
    let m = matchlist(a:err, '(\([a-zA-Z0-9_.\/]*\):\(\d*\):\(\d*\))')
    if empty(m)
        return {}
    endif

    let lines = split(a:err, '\n')

    let [ _, file, line, col; _ ] = m
    let message = lines[len(lines) - 1]

    return {
        \   'text': message,
        \   'lnum': line,
        \   'col': col,
        \   'type': 'E',
        \ }
endfunc " }}}

func! s:figwheelErrToLint(err) "{{{
    let m = matchlist(a:err, 'WARNING: \(.*\) at line \(\d\+\)')
    if empty(m)
        return {}
    endif

    let [ _, message, line; _ ] = m
    return {
        \   'text': message,
        \   'lnum': line,
        \   'col': 1,
        \   'type': 'E',
        \ }
endfunc "}}}

func! s:shadowReplErrorToLint(err) " {{{
    let m = matchlist(a:err, 'The required namespace "\(.*\)" is not available')
    if len(m) > 1
        return {
            \ 'text': m[0],
            \ 'type': 'E',
            \ 'lnum': 1,
            \ 'col': 1,
            \ }
    endif
    return {}
endfunc " }}}

func! s:shadowErrToLint(err) " {{{
    let m = matchlist(a:err, '-- \(ERROR\|WARNING\) ')
    if empty(m)
        return s:shadowReplErrorToLint(a:err)
    endif

    let type = m[1][0]  " IE the E or the W
    let lines = split(a:err, '\n')
    let path = ''
    let linenr = -1
    let col = 1
    let message = []
    for line in lines
        if linenr < 0
            let m = matchlist(line, '^[ ]*\(File\|Resource\): \([^:]\+\):\(\d\+\):\(\d\+\)')
            if empty(m)
                continue
            endif

            " NOTE: I'm not actually sure what the numbers following <eval>
            " mean (they certainly aren't line numbers...)

            let path = m[2]
            let linenr = str2nr(m[3])
            let col = m[4]
            continue
        endif

        " NOTE: trim off the inline source, since we're looking at it
        if line !~# '^---' && line !~# '^.\{0,5\}[ ]*[0-9]\+ |'
            let message = add(message, trim(line))
        endif
    endfor

    if linenr < 0
        return {}
    endif

    let lint = {
        \   'text': join(message, " \n"),
        \   'lnum': linenr,
        \   'col': col,
        \   'type': type,
        \ }
    if path !=# '' && path !=# '<eval>'
        let lint.filename = path
    endif

    echom 'LINT = ' . string(lint)
    return lint
endfunc " }}}

func! s:errToLint(err)
    let lint = s:cljErrToLint(a:err)

    if empty(lint)
        " couldn't parse as a clj error; maybe figwheel?
        let lint = s:figwheelErrToLint(a:err)
    endif

    if empty(lint)
        " maybe shadow-cljs?
        let lint = s:shadowErrToLint(a:err)
    endif

    if empty(lint)
        " if it's still empty, there's nothing more we can do
        return lint
    endif

    return hearth#lint#errors#Expand(lint)
endfunc

func! s:isCleanResponse(state, resp)
    if has_key(a:resp, 'err') || has_key(a:resp, 'ex') || a:state.hasError
        let a:state.hasError = 1
        return 0
    endif

    if !has_key(a:resp, 'status')
        return 0
    endif

    let status = a:resp.status[0]
    return status ==# 'done' && !a:state.hasError
endfunc

func! hearth#lint#CheckResponse(bufnr, state, resp)
    " Check the response of a reload (via ns#TryRequire) for lint
    if s:isCleanResponse(a:state, a:resp)
        " all good!
        call hearth#lint#Notify(a:bufnr, [])
        return
    endif

    if !has_key(a:resp, 'err')
        " the error string is only in the err key
        return
    endif

    let lint = s:errToLint(a:resp.err)
    if !empty(lint)
        if !has_key(lint, 'filename')
            let lint.filename = expand('#' . a:bufnr . ':p')
        endif

        let a:state.lints = add(a:state.lints, lint)
    endif
    call hearth#lint#Notify(a:bufnr, a:state.lints)
endfunc

func! hearth#lint#Notify(bufnr, lints)
    " Notify linters of our current lints
    try
        call ale#other_source#ShowResults(a:bufnr, 'hearth', a:lints)
    catch /E117/
        " no ale
    endtry
endfunc

