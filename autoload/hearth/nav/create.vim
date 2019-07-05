func! s:ensureWritablePath()
    if !filereadable(expand('%:p'))
        if !isdirectory(expand('%:p:h'))
            call mkdir(expand('%:p:h'), 'p')
        endif
    endif
endfunc

func! hearth#nav#create#Test()
    " Create (or open) a new test file for the *current* namespace

    let type = expand('%:e')
    let path = expand('%:p')
    let path = substitute(path, '.' . type . '$', '_test.' . type, '')
    let path = substitute(path, '/src/', '/test/', '')

    exe 'edit ' . path
    call s:ensureWritablePath()
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
