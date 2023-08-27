func! s:ReportCljsTestResults(bufnr, id, path, expr, out) abort
    let lines = split(a:out, "\r\\=\n", 1)

    let entries = hearth#test#util#ParseResults(a:path, lines)

    if a:id
        call setqflist([], 'a', {'id': a:id, 'items': entries})
    else
        call setqflist(entries, 'a')
    endif

    call hearth#test#util#PresentTestResults(a:id, a:path, a:expr)
endfunc

func! hearth#test#bb#CaptureTestRun(expr, pre) abort
    " Borrowed almost completely from fireplace, but adapted to
    " support babashka's runtime
    let expr = '(try'
            \ . ' ' . a:pre
            \ . ' (clojure.core/require ''clojure.test)'
            \ . ' (clojure.core/let [base-report clojure.test/report]'
            \ . ' (clojure.core/binding [clojure.test/report (fn [m]'
            \ .  ' (clojure.core/case (:type m)'
            \ .    ' (:fail :error)'
            \ .    ' (clojure.core/let [{file :file line :line test :name} (clojure.core/meta (clojure.core/last clojure.test/*testing-vars*))]'
            \ .      ' (clojure.test/with-test-out'
            \ .        ' (clojure.test/inc-report-counter (:type m))'
            \ .        ' (clojure.core/println (clojure.string/join "\t" [file line (clojure.core/name (:type m)) test]))'
            \ .        ' (clojure.core/when (clojure.core/seq clojure.test/*testing-contexts*) (clojure.core/println (clojure.test/testing-contexts-str)))'
            \ .        ' (clojure.core/when-let [message (:message m)] (clojure.core/println message))'
            \ .        ' (clojure.core/println "expected:" (clojure.core/pr-str (:expected m)))'
            \ .        ' (clojure.core/println "  actual:" (clojure.core/pr-str (:actual m)))))'
            \ .    ' (base-report m)))]'
            \ . ' ' . a:expr . '))'
            \ . ' (catch Exception e'
            \ . '   (clojure.core/println (clojure.core/str e))'
            \ . '   (clojure.core/println (clojure.string/join "\n" (.getStackTrace e)))))'

    call setqflist([], ' ', {'title': a:expr})
    echo 'Started: ' . a:expr

    " NOTE: Test output in babashka seems to go straight to the CLI, so
    " we have to redirect it to a string
    let expr = '(with-out-str '
                \. ' (binding [clojure.test/*test-out* *out*]'
                \. expr . '))'

    call fireplace#clj().Query(expr,
        \ function('s:ReportCljsTestResults', [bufnr('%'), get(getqflist({'id': 0}), 'id'), fireplace#path(), a:expr]))
endfunc

func! hearth#test#bb#Run(ns)
    let testExpr = "(clojure.test/run-tests '" . a:ns . ')'
    let pre = "(clojure.core/require '" . a:ns . ' :reload)'
    call hearth#test#bb#CaptureTestRun(testExpr, pre)
endfunc
