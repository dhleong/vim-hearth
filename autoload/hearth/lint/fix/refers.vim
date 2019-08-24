
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

func! s:insertRefers(ast, ns, mode, args) " {{{
    let ast = a:ast
    let require = ast.FindClause(':require')
    if empty(require)
        " easy case; just add a new form
        call ast.InsertLiteral('(:require '
            \. s:createForm(require, a:ns, a:mode, a:args)
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
        call require.InsertLiteral(s:createForm(require, ns, a:mode, a:args))
        return hearth#util#ns_ast#ToLines(ast)
    endif

    if a:mode ==# 'as'
        if !empty(existingVector.FindKeywordValue(':as'))
            " existing alias already; do nothing
            echom "There's already an alias for that namespace"
            return
        endif

        call existingVector.AddKeyPair(':as', a:args[0])
    elseif a:mode ==# 'refer'
        let refer = existingVector.FindKeywordValue(':refer')
        if empty(refer)
            call existingVector.AddKeyPair(
                \ ':refer',
                \ s:createReferList(require, a:args[0]))
        else
            call refer.InsertLiteral(a:args[0])
        endif
    endif

    return hearth#util#ns_ast#ToLines(ast)
endfunc " }}}

func! hearth#lint#fix#refers#Insert(context, ns, mode, ...)
    let ast = hearth#util#ns_ast#Build(a:context.lines)
    let astLines = ast.lineCount

    let updatedNs = s:insertRefers(ast, a:ns, a:mode, a:000)
    if empty(updatedNs)
        return
    endif

    return updatedNs + a:context.lines[astLines :]
endfunc
