" ALE interop

func! s:try_reload(bufnr)
    if a:bufnr == bufnr('%')
        write
    endif
endfunc

func! s:deferred_resolve(...) dict
    let result = a:0 ? a:1 : 0

    if has_key(self, 'result_callback')
        call self.result_callback(result)
    endif

    if self._reload_after_resolve == bufnr('%') && hearth#pref#Get('post_fix_autowrite', 1)
        " NOTE: we can't just `write` here because the changes might not be
        " applied immediately. This is a bit of a hack
        call timer_start(250, { -> s:try_reload(self._reload_after_resolve) })
    endif

    return result
endfunc

func! s:then_reload(bufnr) dict
    let self._reload_after_resolve = a:bufnr
    return self
endfunc

func! hearth#ale#Defer()
    " Create a psuedo Promise-like object that can be returned from
    " fixers, for example, when they must complete asynchronously
    return deepcopy(s:deferred)
endfunc

func! hearth#ale#IsDeferred(obj)
    " Create a psuedo Promise-like object that can be returned from
    " fixers, for example, when they must complete asynchronously
    return type(a:obj) == v:t_dict && has_key(a:obj, '_deferred_job_id')
endfunc

let s:deferred = {
        \ '_deferred_job_id': -42,
        \ '_reload_after_resolve': 0,
        \ 'resolve': function('s:deferred_resolve'),
        \ 'thenReload': function('s:then_reload'),
        \ }
