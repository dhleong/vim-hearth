" ALE interop

func! s:cleanupLintContext(context)
    let bufnr = a:context.bufnr
    let resolved = a:context.lint
    let oldLints = ale#engine#GetLoclist(bufnr)
    let newLints = filter(copy(oldLints), 'v:val != resolved')
    if len(newLints) < len(oldLints)
        call hearth#lint#Notify(bufnr, newLints)
    endif
endfunc

func! s:deferred_resolve(...) dict
    let result = a:0 ? a:1 : 0

    if has_key(self, 'result_callback')
        call self.result_callback(result)
    endif

    if has_key(self, '_dirtyContext')
        call s:cleanupLintContext(self._dirtyContext)
    endif

    return result
endfunc

func! s:deferred_thenCleanup(context) dict
    let self._dirtyContext = a:context
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
        \ 'resolve': function('s:deferred_resolve'),
        \ 'thenCleanup': function('s:deferred_thenCleanup'),
        \ }
