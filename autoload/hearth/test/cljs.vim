let s:initScriptPath = expand('<sfile>:p:h') . '/cljs-init.cljs'
let s:printReportExpr = '(cljs.test/report {:type :hearth-report})'
let s:retryDelayMs = 100
let s:timeoutRetryCount = 50 " ~5s

func! s:AppendError(bufnr, entries, err) abort " {{{
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
endfunc " }}}

func! s:CheckAsyncTestCompletion(bufnr, id, path, expr, retryCount, _timer) abort
    if a:retryCount > s:timeoutRetryCount
        echom 'Timeout: ' . a:expr
        return
    endif

    call fireplace#cljs().Query(
        \   s:printReportExpr,
        \   function(
        \     's:ReportCljsTestResults',
        \     [ a:bufnr, a:id, a:path, a:expr, a:retryCount + 1 ]
        \   )
        \ )
endfunc

func! s:TriggerCheckAsyncTestCompletion(bufnr, id, path, expr, retryCount) abort
    echom 'Running... ' . a:expr
    call timer_start(s:retryDelayMs, function('s:CheckAsyncTestCompletion', [ a:bufnr, a:id, a:path, a:expr, a:retryCount ]))
endfunc

func! s:ReportCljsTestResults(bufnr, id, path, expr, retryCount, message) abort
    " see usage below for explanation
    if type(a:message) == v:t_dict
        let message = a:message
    else
        let message = {'value': a:message, 'status': 'done'}
    endif

    let str = get(message, 'value', '')
    let lines = split(str, "\r\\=\n", 1)
    let b:last_lines = lines
    let entries = hearth#test#util#ParseResults(a:path, lines)

    let err = get(message, 'err', '')
    if !empty(err)
        call s:AppendError(a:bufnr, entries, err)
    endif

    if get(message, 'status', '') ==# 'done' && a:message == v:null
        call s:TriggerCheckAsyncTestCompletion(a:bufnr, a:id, a:path, a:expr, a:retryCount)
        return
    endif

    if a:id
        call setqflist([], 'a', {'id': a:id, 'items': entries})
    else
        call setqflist(entries, 'a')
    endif

    if has_key(message, 'status')
        try
            call hearth#test#util#PresentTestResults(a:id, a:path, a:expr)
        catch /.*/
            echom "ERROR" .. v:exception
        endtry
    endif
endfunc

func! hearth#test#cljs#CaptureTestRun(expr) abort
    " NOTE: shadow-cljs redirects *out*, so for simplicity we just always
    " take it over and return a string.
    " NOTE: most of this was based on the original code in fireplace, just
    " adapted for use in a clojurescript context
    let runTests = substitute(a:expr, 'run-tests', 'run-tests (cljs.test/empty-env :vim-hearth)', '')

    let expr = join(readfile(s:initScriptPath), "\n")
            \. '(report-test-output'
            \. '  (with-out-str'
            \. '    ' . runTests . '))'
            \. s:printReportExpr
    let expr = '(try ' . expr . ' (catch :default e {:err (str e), :status :err}))'

    " let expr = '(clojure.string/trim'
    "         \. '  (with-out-str '
    "         \. '    (let [base-report cljs.test/report]'
    "         \. '      (binding [cljs.test/report (fn [{:keys [type] :as m}]'
    "         \. '        (case type'
    "         \. '          (:fail :error)'
    "         \. '          (let [env (cljs.test/get-current-env)'
    "         \. '                {:keys [file line] test :name} (meta (last (:testing-vars env)))]'
    "         \. '            (println (clojure.string/join'
    "         \. '                       "\t" [file line (name type) test]))'
    "         \. '            (when (seq (:testing-contexts env))'
    "         \. '              (println (cljs.test/testing-contexts-str)))'
    "         \. '            (when-let [msg (:message m)] (println msg))'
    "         \. '            (println "expected:" (pr-str (:expected m)))'
    "         \. '            (println "  actual:" (pr-str (:actual m))))'
    "         \. '          (base-report m)))]'
    "         \. '        ' . a:expr . '))))'

    call setqflist([], ' ', {'title': a:expr})
    echo 'Started: ' . a:expr

    " NOTE: this older version is, I think, more robust. However, the symbol
    " value seems to get truncated to the first whitespace when returned
    " by the cljs repl (at least with shadow-cljs). Using Query without the
    " symbol-ification seems to work as a reasonable stopgap, but it might
    " be worth checking if the nrepl behavior is a bug in shadow-cljs...
    " call fireplace#cljs().Message({'op':'eval', 'code': '(symbol ' . expr . ')', 'session': 0},

    " echom fireplace#cljs().Message({'op':'eval', 'code': expr}, v:t_dict)
    call fireplace#cljs().Query(expr,
        \ function('s:ReportCljsTestResults', [bufnr('%'), get(getqflist({'id': 0}), 'id'), fireplace#path(), a:expr, 0]))
endfunc

func! hearth#test#cljs#Run(file, ns)
    call fireplace#cljs().Message({
        \ 'op': 'eval',
        \ 'code': '(load-file ' . hearth#util#Stringify(a:file) .')'
        \ }, v:t_list)
    let ns = a:ns
    let testExpr = "(cljs.test/run-tests '" . ns . ')'
    call hearth#test#cljs#CaptureTestRun(testExpr)
endfunc

