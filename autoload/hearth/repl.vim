
func! hearth#repl#Connect(...)
    " Attempt to auto connect to and configure a fireplace repl session
    " Optional params:
    " - port: The port number to connect on (we will try to guess, otherwise)

    let l:port = a:0 ? a:1 : hearth#path#GuessPort()
    let l:root = hearth#path#GuessRoot()

    try
        exe 'Connect ' . l:port . ' ' . l:root

        if 'cljs' ==# expand('%:e')
            " prepare piggieback
            if hearth#path#DetectShadowJs()
                call hearth#shadow#SelectBuild(l:port)
            else
                Piggieback (figwheel-sidecar.repl-api/repl-env)
            endif
        endif
        return ''
    catch /Fireplace:.*/
        " echo the error (probably connection refused)
        echohl ErrorMsg | echom v:exception . ' (connecting @' . l:port . ')' | echohl None
    endtry

endfunc

