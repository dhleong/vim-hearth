
func! s:createReferList(require, symbol)
    " infer refer style
    " TODO user preference for default?
    let style = '[]'
    if !empty(a:require)
        for form in a:require.children
            if form.type !=# 'vector'
                continue
            endif

            let refer = form.FindKeywordValue(':refer')
            if !empty(refer)
                if refer.type ==# 'form'
                    let style = '()'
                endif
                break
            endif
        endfor
    endif

    return style[0] . a:symbol . style[1]
endfunc

func! s:createForm(require, ns, mode, args)
    let form = '[' . a:ns

    if a:mode ==# 'as'
        let form .= ' :as ' . a:args[0]
    elseif a:mode ==# 'refer'
        let form .= ' :refer ' . s:createReferList(a:require, a:args[0])
    endif

    return form . ']'
endfunc

func! hearth#lint#fix#refers#Insert(context, ns, mode, ...)
    let ast = hearth#util#ns_ast#Build(a:context.lines)
    let require = ast.FindClause(':require')
    if empty(require)
        " easy case; just add a new form
        call ast.SortedInsertLiteral('(:require '
            \. s:createForm(require, a:ns, a:mode, a:000)
            \. ')')
        return hearth#util#ns_ast#ToLines(ast)
    endif

    let existingVector = require.FindClause(a:ns)
    let ns = a:ns
    if empty(existingVector)
        " try a nested insert?
        let lastDot = strridx(ns, '.')
        if lastDot > 0
            let parentNs = ns[:lastDot-1]
            let parent = require.FindClause(parentNs)
            if !empty(parent)
                let require = parent
                let ns = ns[lastDot+1:]
            endif
        endif
    endif

    if empty(existingVector)
        " new reference; also pretty easy
        call require.SortedInsertLiteral(s:createForm(require, ns, a:mode, a:000))
        return hearth#util#ns_ast#ToLines(ast)
    endif

    if a:mode ==# 'as'
        if !empty(existingVector.FindKeywordValue(':as'))
            " existing alias already; do nothing
            echom "There's already an alias for that namespace"
            return
        endif

        call existingVector.SortedAddKeyPair(':as', a:1)
    elseif a:mode ==# 'refer'
        let refer = existingVector.FindKeywordValue(':refer')
        if empty(refer)
            call existingVector.SortedAddKeyPair(
                \ ':refer',
                \ s:createReferList(require, a:1))
        else
            call refer.SortedInsertLiteral(a:1)
        endif
    endif

    return hearth#util#ns_ast#ToLines(ast)
endfunc
