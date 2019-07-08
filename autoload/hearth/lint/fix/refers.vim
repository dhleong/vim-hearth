func! s:parseNsForm(lines) " {{{
    let nsStart = -1
    let nsEnd = -1
    let requireStart = -1
    let requireEnd = -1

    let nesting = 0

    for i in range(0, len(a:lines) - 1)
        let line = a:lines[i]
        let nesting += count(line, '(') - count(line, ')')

        if line =~# '(:require '
            let requireStart = i
        endif
        if requireStart >= 0 && line =~# '\])*[ ]*$'
            let requireEnd = i
        endif

        if line =~# '(ns'
            let nsStart = i
        endif
        if nsStart >= 0 && nesting == 0
            let nsEnd = i
            break
        endif
    endfor

    return [nsStart, nsEnd, requireStart, requireEnd]
endfunc " }}}

func! s:chooseInsertIndex(lines, ns, start, end)
    " Choose the index within [start, end] of `lines`
    " in which to insert an entry for `ns`

    for i in range(a:start, a:end)
        " TODO handle nested ns forms (consider only top-level?)
        let m = matchlist(a:lines[i], '\[\([a-zA-Z0-9_.-]*\) ')
        if empty(m)
            continue
        endif

        let ns = m[1]
        if a:ns < ns
            return i - 1
        endif
    endfor

    return a:start
endfunc

func! hearth#lint#fix#refers#Insert(lines, ns, mode, ...)
    " NOTE: this may be simpler to do from clojure...?

    let lines = a:lines

    " TODO add refer to existing form? etc?
    let form = '[' . a:ns

    if a:mode ==# 'as'
        let form .= ' :as ' . a:1
    endif

    let form .= ']'

    echom 'Add: ' . form

    let [nsStart, nsEnd, requireStart, requireEnd] = s:parseNsForm(lines)
    if requireStart < 0
        " no (:require) found; create it
        let lines[nsEnd] = substitute(lines[nsEnd], ')$', '', '')
        return insert(lines, '  (:require ' . form . '))', nsEnd + 1)
    endif

    " pick an appropriate place to insert
    let index = s:chooseInsertIndex(lines, a:ns, requireStart, requireEnd)
    if index < requireStart
        " special case: inserting before the first require'd form
        let lines = insert(lines, '  (:require ' . form, index + 1)
        let lines[index + 2] = substitute(lines[index + 2], '(:require', '         ', '')
        return lines
    endif

    " FIXME compute the indent?
    let indent = '            '
    let form = indent . form

    let line = lines[index]
    let lines = insert(lines, form, index + 1)

    " if it's the last line, transfer the closing parens
    if line =~# ']))[ ]*$'
        let lines[index] = substitute(line, '))$', '', '')
        let lines[index + 1] .= '))'
    endif

    return lines
endfunc
