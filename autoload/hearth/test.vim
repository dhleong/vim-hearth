func! s:ReportCljsTestResults(path, expr, results)
    let entries = []
    let lines = split(a:results, "\r\\=\n", 1)
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
            let entry.filename = fireplace#findresource(resource, a:path)
            if empty(entry.filename)
                let entry.lnum = 0
            endif
        else
            let entry = {'text': line}
        endif
        call add(entries, entry)
    endfor

    call setqflist(entries, 'a')

    let list = getqflist()
    if empty(filter(list, 'v:val.valid'))
        cwindow

        redraw
        echo 'Success: ' . a:expr
    else
        let was_qf = &buftype ==# 'quickfix'
        botright copen
        if &buftype ==# 'quickfix' && !was_qf
            wincmd p
        endif

        redraw
        echo 'Failure: ' . a:expr
    endif
endfunc

func! s:RunCljsTests(ns)
    let ns = a:ns
    let testExpr = "(cljs.test/run-tests '" . ns . ')'

    call setqflist([], ' ', {'title': testExpr})

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
            \. '        ' . testExpr . ')))))'
    let result = fireplace#eval(expr)

    call s:ReportCljsTestResults(fireplace#path(), testExpr, result)
endfunc

func! hearth#test#RunForBuffer()
    " Run the appropriate tests for the current buffer. If this is not
    " a test ns, we will run the associated -test ns
    " This will automatically write the file if it's not saved

    if &modified
        w
        redraw!
    endif

    let ns = fireplace#ns()
    if ns !~# '-test$'
        let ns = ns . '-test'
    endif

    silent :Require
    if expand('%:e') ==# 'cljs'
        call s:RunCljsTests(ns)
    else
        exe 'RunTests ' . ns
    endif
endfunc
