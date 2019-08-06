
func! s:isTest(ns)
    return a:ns =~# '-test$'
endfunc

func! s:generateTest(type, testNs, baseNs)
    let import = []
    if a:type ==# 'cljs'
        let import = ['  (:require [cljs.test :refer-macros [deftest testing is]]',
                    \ '            [cljs.nodejs :as node]',
                    \ '            [' . a:baseNs . ' :refer []]))']
    else

        let import = ['  (:require [clojure.test :refer :all]',
                    \ '            [' . a:baseNs . ' :refer :all]))']
    endif

    " was definitely new
    return ['(ns ' . a:testNs] +
        \  import +
        \  ['',
        \   '(deftest a-test',
        \   '  (testing "FIXME new test"',
        \   '    (is (= 0 1))))']
endfunc

func! s:generateSimple(ns)
    let author = hearth#pref#Get('tpl_author', '(Author)')
    return ['(ns ^{:author "' . author . '"',
        \   '      :doc "' . a:ns . '"}', 
        \   '  ' . a:ns . ')',
        \   '']
endfunc

func! hearth#tpl#Generate(type, ns)
    " Given the file type (extension) and a namespace,
    " generate a nice template.
    " Returns a list of strings

    if s:isTest(a:ns)
        let baseNs = substitute(a:ns, '-test$', '', '')
        return s:generateTest(a:type, a:ns, baseNs)
    else
        return s:generateSimple(a:ns)
    endif

endfunc

func! hearth#tpl#Fill()
    " Fill the current buffer with an appropriate template

    let type = expand('%:e')
    let ns = ''
    if hearth#util#SessionExists()
        let ns = fireplace#ns()
        if ns ==# 'user'
            let ns = ''
        endif
    else
        " TODO
    endif

    if ns ==# ''
        " couldn't figure out the ns
        return
    endif

    let tpl = hearth#tpl#Generate(type, ns)
    call append(0, tpl)

    if !s:isTest(ns)
        " FIXME this is terribly magic
        call cursor(2, 12) " prepare to update the :doc
    endif
endfunc
