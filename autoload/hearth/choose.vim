func! s:resolveDeferred(d, Callback, value)
    call a:d.resolve(a:Callback(a:value))
endfunc

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
        return a:OnChosen(a:items[0])
    endif

    " TODO non-FZF options? eg inputlist()
    call fzf#run({
        \ 'source': a:items,
        \ 'sink': Callback,
        \ 'down': '10%',
        \ })

    if a:0 && hearth#ale#IsDeferred(a:1)
        " return the deferred
        return a:1
    endif
endfunc
