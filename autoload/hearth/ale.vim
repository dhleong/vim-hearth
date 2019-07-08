" ALE interop

func! s:deferred_resolve(...) dict
    call self.result_callback(a:0 ? a:1 : 0)
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
        \ 'resolve': function('s:deferred_resolve')
        \ }
