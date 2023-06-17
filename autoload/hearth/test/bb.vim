func! hearth#test#bb#CaptureTestRun(testExpr) abort
    " TODO: Async test running + quickfix filling
    let expr = '(with-out-str '
            \. ' (binding [clojure.test/*test-out* *out*]'
            \. a:testExpr . '))'
    echo fireplace#clj().Query(expr)
endfunc

func! hearth#test#bb#Run(ns)
    let testExpr = "(clojure.test/run-tests '" . a:ns . ')'
    call hearth#test#bb#CaptureTestRun(testExpr)
endfunc
