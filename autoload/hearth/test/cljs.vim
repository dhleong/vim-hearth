func! s:AppendError(bufnr, entries, err) abort
    let lines = split(a:err, "\r\\=\n", 1)
    let entries = a:entries
    call add(entries, {
        \ 'text': 'ERROR',
        \ 'filename': expand('#' . a:bufnr . ':p'),
        \ 'lnum': 1
        \ })

    for line in lines
        let entry = {'text': line}
        call add(entries, entry)
    endfor
    call add(entries, entry)
endfunc

func! s:ReportCljsTestResults(bufnr, id, path, expr, message) abort
    let str = get(a:message, 'value', '')
    let lines = split(str, "\r\\=\n", 1)
    let entries = []
    for line in lines
        if line =~# '\t.*\t.*\t'
            let entry = {'text': line}
            let [resource, lnum, type, name] = split(line, "\t", 1)
            let entry.lnum = lnum
            let entry.type = (type ==# 'fail' ? 'W' : 'E')
            let entry.text = name
            if resource ==# 'NO_SOURCE_FILE'
                let resource = ''
                let entry.lnum = 0
            endif
            let entry.filename = resource
            if !filereadable(entry.filename)
                let entry.filename = fireplace#findresource(resource, a:path)
            endif
            if empty(entry.filename)
                let entry.lnum = 0
            endif
        else
            let entry = {'text': line}
        endif
        call add(entries, entry)
    endfor

    let err = get(a:message, 'err', '')
    if !empty(err)
        call s:AppendError(a:bufnr, entries, err)
    endif

    if a:id
        call setqflist([], 'a', {'id': a:id, 'items': entries})
    else
        call setqflist(entries, 'a')
    endif

    if has_key(a:message, 'status')
        let list = a:id ? getqflist({'id': a:id, 'items': 1}).items : getqflist()
        if empty(filter(list, 'v:val.valid'))
            cwindow

            redraw
            echo 'Success: ' . a:expr
        else
            if get(getqflist({'id': 0}), 'id') ==# a:id
                let was_qf = &buftype ==# 'quickfix'
                botright copen
                if &buftype ==# 'quickfix' && !was_qf
                    wincmd p
                endif

                redraw
                echo 'Failure: ' . a:expr
            endif
        endif
    endif
endfunc

func! hearth#test#cljs#CaptureTestRun(expr) abort
    " NOTE: shadow-cljs redirects *out*, so for simplicity we just always
    " take it over and return a string.
    " NOTE: most of this was based on the original code in fireplace, just
    " adapted for use in a clojurescript context
    let expr = '(symbol (clojure.string/trim'
            \. '  (with-out-str '
            \. '    (let [base-report cljs.test/report]'
            \. '      (binding [cljs.test/report (fn [{:keys [type] :as m}]'
            \. '        (case type'
            \. '          (:fail :error)'
            \. '          (let [env (cljs.test/get-current-env)'
            \. '                {:keys [file line] test :name} (meta (last (:testing-vars env)))]'
            \. '            (println (clojure.string/join'
            \. '                       "\t" [file line (name type) test]))'
            \. '            (when (seq (:testing-contexts env))'
            \. '              (println (cljs.test/testing-contexts-str)))'
            \. '            (when-let [msg (:message m)] (println msg))'
            \. '            (println "expected:" (pr-str (:expected m)))'
            \. '            (println "  actual:" (pr-str (:actual m))))'
            \. '          (base-report m)))]'
            \. '        ' . a:expr . ')))))'

    call setqflist([], ' ', {'title': a:expr})
    echo 'Started: ' . a:expr
    call fireplace#cljs().Message({'op': 'eval', 'code': expr},
        \ function('s:ReportCljsTestResults', [bufnr('%'), get(getqflist({'id': 0}), 'id'), fireplace#path(), a:expr]))
endfunc

func! hearth#test#cljs#Run(ns)
    let ns = a:ns
    let testExpr = "(cljs.test/run-tests '" . ns . ')'
    call hearth#test#cljs#CaptureTestRun(testExpr)
endfunc

