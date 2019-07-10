func! hearth#lint#fix#dup_refer#Fix(bufnr, lines, symbol)
    call hearth#ns#Undef(a:symbol)
endfunc
