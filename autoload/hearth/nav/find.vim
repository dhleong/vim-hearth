
func! s:findAlt(ext)
    let ext = expand('%:e')
    let fileName = substitute(
                \ expand('%'),
                \ '.' . ext . '$',
                \ '_test.' . a:ext,
                \ '')

    let dir = expand('%:p:h:t')

    try
        exe 'find ' . dir . '/' . fileName
        return 1
    catch /E345/
        " not found
        return 0
    endtry
endfunc

func! hearth#nav#find#Test()
    " Find and open the matching test file for the current ns, if any

    let ext = expand('%:e')
    let found = s:findAlt(ext)
    if found
        return
    elseif !found && ext ==# 'cljc'
        if s:findAlt('cljs')
            return
        elseif s:findAlt('clj')
            return
        endif
    endif

    echom "Couldn't find test companion file for this file"
endfunc
