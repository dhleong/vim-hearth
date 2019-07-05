
augroup HearthAuto
    autocmd!
    autocmd BufNewFile *.clj,*.clj[cs] call hearth#tpl#Fill()
augroup END

