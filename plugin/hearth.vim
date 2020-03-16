
func! s:MaybeRequire()
    if hearth#pref#Get('auto_require', 1)
        call timer_start(750, { -> hearth#ns#TryRequire() })
        " call hearth#ns#TryRequire()
    endif
endfunc

augroup HearthAuto
    autocmd!
    autocmd FileType clojure call hearth#Activate()
    autocmd BufNewFile *.clj,*.clj[cs] call hearth#tpl#Fill()
    autocmd BufWritePost *.clj,*.clj[cs] call <SID>MaybeRequire()
augroup END

