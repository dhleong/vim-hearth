func! s:resolveDeferred(d, Callback, value)
    return a:d.resolve(a:Callback(a:value))
endfunc

func! s:promptViaFzf(items, Callback) "{{{
    call fzf#run({
        \ 'source': a:items,
        \ 'sink': a:Callback,
        \ 'down': '20%',
        \ })
endfunc "}}}

func! s:promptViaInputList(items, Callback) " {{{
    let items = a:items
    let maxOptions = &lines - 4
    if len(items) >= maxOptions
        let items = items[:maxOptions]
    endif

    let selections = ['Choose one:'] +
        \ map(items, '(v:key + 1) . ". " . v:val')
    let index = inputlist(selections)
    if index <= 0
        " cancelled
        return -1
    endif

    return a:Callback(a:items[index - 1])
endfunc " }}}

func! s:prompt(items, Callback) "{{{
    " prefer FZF if available
    try
        return s:promptViaFzf(a:items, a:Callback)
    catch /E117/
        " fzf unavailable
    endtry

    " fallback to inputlist()
    return s:promptViaInputList(a:items, a:Callback)
endfunc "}}}

func! hearth#choose#OneOf(items, OnChosen, ...)
    " Given a list of string items, prompt the to user choose one of them,
    " calling OnChosen with the selection.
    "
    " You may optionally provide a hearth#ale#Defer() instance which, if
    " provided, will be resolved with the result of OnChosen, and returned
    " from this fn if appropriate.

    if len(a:items) == 0
        " no items? nothing to do; even if we were provided a Deferred,
        " there's no possible value to resolve, so drop it
        return
    endif

    let Callback = a:OnChosen
    if a:0 && hearth#ale#IsDeferred(a:1)
        let Callback = function('s:resolveDeferred', [a:1, a:OnChosen])
    endif

    if len(a:items) == 1
        " single candidate? shortcut and apply immediately
        " (without the deferred!)
        return Callback(a:items[0])
    endif

    let result = s:prompt(a:items, Callback)
    if type(result) == v:t_number && result == -1
        " cancelled
        return
    elseif type(result) != v:t_number || result != 0
        " result selected inline
        return result
    endif

    if a:0 && hearth#ale#IsDeferred(a:1)
        " return the deferred
        return a:1
    endif
endfunc
