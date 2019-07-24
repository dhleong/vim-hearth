
func! s:createMaps() " {{{
    nnoremap <buffer> cpt :call hearth#test#RunForBuffer()<cr>

    " 'new file'
    nnoremap <buffer> <leader>nf :call hearth#nav#create#Prompt("e")<cr>
    " 'tab new file'
    nnoremap <buffer> <leader>tf :call hearth#nav#create#Prompt("tabe")<cr>
    " 'split new file'
    nnoremap <buffer> <leader>snf :call hearth#nav#create#Prompt("vsplit")<cr>

    " 'new test'
    nnoremap <buffer> <leader>nt :call hearth#nav#create#Test()<cr>
    " 'open test'
    nnoremap <buffer> <leader>ot :call hearth#nav#find#Test()<cr>

    " connect to a running repl
    nnoremap <buffer> glc :call hearth#repl#Connect()<cr>
endfunc " }}}

func! hearth#Activate()
    if hearth#pref#Get('create_maps', 1)
        call s:createMaps()
    endif

    if exists('#User#HearthActivate')
        doautocmd <nomodeline> User HearthActivate
    endif
endfunc
