" ALE interop

func! s:areNrsRelated(thisKind, thisArg, otherKind, otherArg) abort
    if a:thisKind ==# 'ns' && a:otherKind =~# 'var\|symbol'
        " a missing var/symbol is related to a missing ns IFF
        " the symbol includes that ns
        return stridx(a:otherArg, a:thisArg) >= 0
    endif
endfunc

func! s:isRelatedTo(context, val) abort
    if a:context == a:val
        return 1
    endif

    if a:context.lnum != a:val.lnum
        return 0
    endif

    if a:val.nr !~# ':'
        " the candidate entry isn't formatted as a hearth lint
        return 0
    endif

    let [thisKind, thisArg] = hearth#lint#errors#Unpack(a:context)
    let [otherKind, otherArg] = hearth#lint#errors#Unpack(a:val)
    return s:areNrsRelated(thisKind, thisArg, otherKind, otherArg)
        \|| s:areNrsRelated(otherKind, otherArg, thisKind, thisArg)
endfunc

func! s:cleanupLintContext(context) abort
    let bufnr = a:context.bufnr
    let resolved = a:context.lint
    let oldLints = ale#engine#GetLoclist(bufnr)
    let newLints = filter(copy(oldLints), '!s:isRelatedTo(resolved, v:val)')
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
