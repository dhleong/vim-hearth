
func! s:MaybeRequire()
    if get(g:, 'hearth_auto_require', 1)
        call hearth#ns#TryRequire()
    endif
endfunc

augroup HearthAuto
    autocmd!
    autocmd BufNewFile *.clj,*.clj[cs] call hearth#tpl#Fill()

    " NOTE we don't auto-Require for cljs because it's quite slow
    " TODO we should probably make an option for it, though
    autocmd BufWritePost *.clj,*.clj[cs] call <SID>MaybeRequire()
augroup END

