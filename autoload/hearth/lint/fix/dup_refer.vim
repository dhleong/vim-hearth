func! hearth#lint#fix#dup_refer#Fix(bufnr, lines, symbol)
    call hearth#ns#Undef(a:symbol)
    call hearth#ns#TryReload(a:bufnr)
endfunc
