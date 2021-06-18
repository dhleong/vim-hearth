func! s:ensureWritablePath()
    if !filereadable(expand('%:p'))
        if !isdirectory(expand('%:p:h'))
            call mkdir(expand('%:p:h'), 'p')
        endif
    endif
endfunc

func! s:projectNameUnderSrc(path)
    let srcIdx = stridx(a:path, '/src/')
    if srcIdx == -1
        return ''
    endif

    let maybeProjectIdx = srcIdx + len('/src')
    let maybeProjectEnd = stridx(a:path, '/', maybeProjectIdx + 1)
    if maybeProjectEnd == -1
        return ''
    endif

    if isdirectory(a:path[0:maybeProjectIdx] . 'test')
        return a:path[maybeProjectIdx : maybeProjectEnd-1]
    endif

    return ''
endfunc

func! hearth#nav#create#Test()
    " Create (or open) a new test file for the *current* namespace

    let type = expand('%:e')
    let path = expand('%:p')
    let path = substitute(path, '.' . type . '$', '_test.' . type, '')
    if path =~# '/main/'
        " eg: src/main/ns
        "     src/test/ns
        let path = substitute(path, '/main/', '/test/', '')
    else
        let projectName = s:projectNameUnderSrc(path)
        if projectName !=# ''
            " eg: src/project1/ns
            "     src/project2/ns
            "     src/test/ns
            let path = substitute(path, '/' . projectName . '/', '/test/', '')
        else
            " eg: src/ns
            "     test/ns
            let path = substitute(path, '/src/', '/test/', '')
        endif
    endif

    exe 'edit ' . path
    " call s:ensureWritablePath()
endfunc

func! hearth#nav#create#RelativeNs(method, relativeNs)
    " Create a new file whose ns is relative to the ns of the current file

    let type = expand('%:e')
    let newNsPath = substitute(a:relativeNs, '-', '_', 'g')
    let newNsPath = substitute(newNsPath, '\.', '/', 'g')
    let path = expand('%:p:h') . '/' . newNsPath . '.' . type

    exe a:method . ' ' . path
    call s:ensureWritablePath()
endfunc

func! hearth#nav#create#Prompt(method)
    " Prompt for a ns and create the file

    let newNs = input('New NS: ')
    if newNs ==# ''
        echo 'Canceled'
        return
    endif

    call hearth#nav#create#RelativeNs(a:method, newNs)
endfunc
