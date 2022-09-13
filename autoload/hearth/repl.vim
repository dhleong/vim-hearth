func! s:CloseJob(bufnr)
    let l:job_id = getbufvar(a:bufnr, 'babashka_job', 0)
    if l:job_id == 0
        return
    endif

    call setbufvar(a:bufnr, 'babashka_job', 0)

    if has('nvim')
        call jobstop(l:job_id)
    else
        call job_stop(l:job_id)
    endif
endfunc

func! s:Connect(port, root)
    exe 'Connect ' . a:port . ' ' . a:root
endfunc

func! s:EnsureBabashkaNrepl()
    if get(b:, 'babashka_job', 0) != 0
        return
    endif

    let l:cmd = ['bb', 'nrepl-server']
    let l:opts = { 'cwd': expand('%:p:h') }
    let l:bufnr = bufnr('%')

    if has('nvim')
        let b:babashka_job = jobstart(l:cmd, l:opts)
    else
        let b:babashka_job = job_start(l:cmd, l:opts)
    end

    augroup HearthStopBabashkaRepl
        autocmd!
        exe 'autocmd BufUnload <buffer> call <SID>CloseJob(' . l:bufnr . ')'
    augroup END
endfunc

func! hearth#repl#Connect(...)
    " Attempt to auto connect to and configure a fireplace repl session
    " Optional params:
    " - port: The port number to connect on (we will try to guess, otherwise)

    let l:port = a:0 ? a:1 : hearth#path#GuessPort()
    let l:root = hearth#path#GuessRoot()
    let l:extension = expand('%:e')

    if hearth#path#DetectBabashka()
        " A `bb nrepl-server` *may* have been spawned externally; try
        " to connect to it before spawning our own
        try
            call s:Connect(l:port, l:root)
            return
        catch /Fireplace:.*Connection Refused/
            " Doesn't exist; spawn it!
            call s:EnsureBabashkaNrepl()
        endtry
    endif

    try
        call s:Connect(l:port, l:root)

        if l:extension ==# 'cljs' || l:extension ==# 'cljc'
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

