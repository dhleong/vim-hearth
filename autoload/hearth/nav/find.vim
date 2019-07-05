
func! hearth#nav#find#Test()
    " Find and open the matching test file for the current ns, if any

    let ext = expand('%:e')
    let fileName = substitute(
                \ expand('%'),
                \ '.' . ext . '$',
                \ '_test.' . ext,
                \ '')

    let dir = expand('%:p:h:t')

    exe 'find ' . dir . '/' . fileName
endfunc
