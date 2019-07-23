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

func! s:chooseInsert(lines, ns, start, end) "{{{
    " Choose the index within [start, end] of `lines`
    " in which to insert an entry for `ns`

    let depth = 0
    let targetDepth = 0
    let ns = a:ns

    let insertAt = a:end
    let indent = '            '  " default for top level of (:require)
    let suffix = ''
    let exists = 0

    for i in range(a:start, a:end)
        let line = a:lines[i]
        let depth += count(line, '[') - count(line, ']')

        let m = matchlist(line, '\[\([a-zA-Z0-9_.-]*\)\>')
        if empty(m)
            continue
        endif

        let currentNs = m[1]

        if ns == currentNs
            let insertAt = i
            let exists = 1
            break
        elseif ns < currentNs
            let insertAt = i - 1
            break
        endif

        if depth > targetDepth && stridx(ns, currentNs) == 0
            " nested ns
            let ns = ns[len(currentNs) + 1:]
            let targetDepth = depth
            continue
        elseif depth > targetDepth
            " unrelated nested ns form
            continue
        elseif depth < targetDepth
            " only possible if we wanted a nested ns and ours belongs
            " at the end of the list
            " TODO this doesn't seem general enough
            let a:lines[i] = substitute(a:lines[i], '\]\]\(\s*\|)*\)$', ']\1', '')
            let suffix = ']'
            let insertAt = i
            break
        endif
    endfor

    " TODO is this always correct?
    let indent .= repeat(' ', targetDepth)
    return {
        \ 'exists': exists,
        \ 'indent': indent,
        \ 'index': insertAt,
        \ 'ns': ns,
        \ 'suffix': suffix
        \ }
endfunc"}}}

func! s:createForm(ns, mode, args)
    let form = '[' . a:ns

    if a:mode ==# 'as'
        let form .= ' :as ' . a:args[0]
    elseif a:mode ==# 'refer'
        let form .= ' :refer [' . a:args[0] . ']'
    endif

    return form . ']'
endfunc

func! s:insertAs(line, alias)
    if a:line =~# ' :as '
        echom "There's already an alias for that namespace"
        return
    endif

    let referIdx = stridx(a:line, ' :refer')
    if referIdx != -1
        return a:line[:referIdx] . ':as ' . a:alias . a:line[referIdx :]
    endif

    " presumably, the :refer is on the next line
    return a:line . ' :as ' . a:alias
endfunc

func! s:insertRefer(line, symbol)
    let m = matchlist(a:line, ':refer \[\([^\]]*\)')
    if !empty(m)
        " easy case; add to an existing refer
        let items = split(m[1], '\s\+')
        let newItems = sort(insert(items, a:symbol))
        return substitute(a:line, m[1], join(newItems, ' '), '')
    endif

    " TODO the :refer could be on another line...

    " insert the :refer after an :as, probably
    let end = stridx(a:line, ']')
    if end == -1
        return a:line . ' :refer [' . a:symbol . ']'
    endif

    return a:line[:end-1] . ' :refer [' . a:symbol . ']' . a:line[end :]
endfunc

func! s:tryInsert(line, mode, args)
    if a:mode ==# 'refer'
        " insert a new refer for an existing ns
        return s:insertRefer(a:line, a:args[0])

    elseif a:mode ==# 'as'
        " add :as to an existing :refer
        return s:insertAs(a:line, a:args[0])
    endif
endfunc

func! hearth#lint#fix#refers#Insert(context, ns, mode, ...)
    " NOTE: this may be simpler to do from clojure...?

    let lines = a:context.lines

    let [nsStart, nsEnd, requireStart, requireEnd] = s:parseNsForm(lines)
    if requireStart < 0
        " no (:require) found; create it
        let lines[nsEnd] = substitute(lines[nsEnd], ')$', '', '')
        let form = s:createForm(a:ns, a:mode, a:000)
        return insert(lines, '  (:require ' . form . '))', nsEnd + 1)
    endif

    " pick an appropriate place to insert
    let insert = s:chooseInsert(lines, a:ns, requireStart, requireEnd)
    let index = insert.index
    if insert.exists
        let inserted = s:tryInsert(lines[index], a:mode, a:000)
        if type(inserted) == v:t_string
            let lines[index] = inserted
            return lines
        endif

        " already refer'd?
        return
    endif

    let form = s:createForm(insert.ns, a:mode, a:000)

    if index < requireStart
        " special case: inserting before the first require'd form
        let lines = insert(lines, '  (:require ' . form, index + 1)
        let lines[index + 2] = substitute(lines[index + 2], '(:require', '         ', '')
        return lines
    endif

    let line = lines[index]
    let lines = insert(lines, insert.indent . form . insert.suffix, index + 1)

    " if it's the last line, transfer the closing parens
    if line =~# ']))[ ]*$'
        let lines[index] = substitute(line, '))$', '', '')
        let lines[index + 1] .= '))'
    endif

    return lines
endfunc
