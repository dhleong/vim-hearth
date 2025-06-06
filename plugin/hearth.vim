
func! s:MaybeRequire()
    if hearth#pref#Get('auto_require', 1)
        call hearth#ns#TryRequire()
    endif
endfunc

augroup HearthAuto
    autocmd!
    autocmd FileType clojure,fennel call hearth#Activate()
    autocmd BufNewFile *.clj,*.clj[cs] call hearth#tpl#Fill()
    autocmd BufReadPost *.clj,*.clj[cs] call hearth#tpl#MaybeFill()
    autocmd BufWritePost *.clj,*.clj[cs],*.fnl call <SID>MaybeRequire()
augroup END

