
" ======= Tokenizer ======================================= {{{

let s:tokens = [
    \ ['ws', '^\s\+'],
    \ ['meta', '^\^'],
    \ ['(', '^('], [')', '^)'],
    \ ['{', '^{'], ['}', '^}'],
    \ ['[', '^\['], [']', '^\]'],
    \ ['kw', '^:[^ )\]}]\+'],
    \ ['sym', '^[^ )\]}]\+'],
    \ ]

func! s:tokHasPeek() dict
    return type(self._peeked) != type(v:null) || self._peeked != v:null
endfunc

func! s:tokStringLiteral() dict " {{{
    let self._lines[0] = self._lines[0][1:]
    let self.col += 1
    let literal = ''

    while !empty(self._lines)
        let line = self._lines[0]
        let i = 0
        let length = len(line)
        while i < length
            if line[i] ==# '"' && (i == 0 || line[i-1] !=# '\')
                let literal .= line[0:i - 1]
                let self.col += i + 1
                let self._lines[0] = line[len(literal)+1:]
                return ['string', literal]
            endif
            let i += 1
        endwhile

        " couldn't find on this line; perhaps on the next?
        let literal .= line . "\n"
        let self._lines = self._lines[1:]
        let self.col = 0
    endwhile

    throw 'Unterminated string: "' . literal
endfunc " }}}

func! s:tokNext() dict
    if self.hasPeek()
        let next = self._peeked
        let self._peeked = v:null
        let self._peekCol = -1
        return next
    endif

    while len(self._lines) && empty(self._lines[0])
        let self._lines = self._lines[1:]
        let self.col = 0
        if !empty(self._lines)
            return ['ws', "\n"]
        endif
    endwhile
    if empty(self._lines)
        return ['end', '']
    endif

    let line = self._lines[0]
    if line[0] ==# '"'
        return self.stringLiteral()
    endif

    for [kind, regex] in s:tokens
        let m = matchstr(line, regex)
        if !empty(m)
            let self.col += len(m)
            let self._lines[0] = self._lines[0][len(m):]
            return [kind, m]
        endif
    endfor

    throw 'Parse error; unexpected: ' . self._lines
endfunc

func! s:tokCol() dict
    if self.hasPeek()
        return self._peekCol
    endif
    return self.col
endfunc

func! s:tokPeek() dict
    if !self.hasPeek()
        let self._peekCol = self.col
        let self._peeked = self.Next()
    endif
    return self._peeked
endfunc

func! s:tokExpect(kind) dict
    let next = self.Next()
    if next[0] !=# a:kind
        throw 'Expected ' . a:kind . ' but was: ' . string(next)
    endif
    return next
endfunc

func! s:tokThrow(message) dict
    let line = '(empty)'
    if !empty(self.lines)
        let line = self.lines[0]
    endif
    throw 'ERROR: ' . a:message
        \. "\nAt col " . self.Col() . ': ' . line
endfunc

let s:tokenizer = {
    \ '_peeked': v:null,
    \ 'col': 0,
    \ 'hasPeek': function('s:tokHasPeek'),
    \ 'stringLiteral': function('s:tokStringLiteral'),
    \ 'Col': function('s:tokCol'),
    \ 'Expect': function('s:tokExpect'),
    \ 'Next': function('s:tokNext'),
    \ 'Peek': function('s:tokPeek'),
    \ 'Throw': function('s:tokThrow'),
    \ }

func! hearth#util#ns_ast#tokenizer(lines)
    let tokenizer = deepcopy(s:tokenizer)
    let tokenizer._lines = copy(a:lines)
    return tokenizer
endfunc

" }}}


" ======= AST parsing =====================================

func! s:findClauseInChildren(self, clause) " {{{
    for child in a:self.children
        if has_key(child, 'FindClause')
            let fromChild = child.FindClause(a:clause)
            if !empty(fromChild)
                return fromChild
            endif
        endif
    endfor
    return v:null
endfunc " }}}

func! s:isWhitespace(node) " {{{
    return a:node.type ==# 'literal' && a:node.kind ==# 'ws'
endfunc " }}}

func! s:withChildren(node, children) " {{{
    let a:node.children = a:children
    return a:node
endfunc " }}}

func! s:compare(literal, node) " {{{
    let expected = 'literal'
    let lhs = a:literal
    if a:literal[0] ==# '['
        let expected = 'vector'
        let lhs = a:literal[1:]
    elseif a:literal[0] ==# '('
        let expected = 'form'
        let lhs = a:literal[1:]
    endif

    if a:node.type !=# expected
        return 0
    endif

    if a:node.type ==# 'literal'
        let rhs = a:node.value
    elseif a:node.type ==# 'vector'
        let rhsNode = a:node.children[0]
        if rhsNode.type !=# 'literal'
            return 0
        endif
        let rhs = rhsNode.value
    elseif rhsNode.type ==# 'form'
        let rhs = rhsNode.first
    endif

    return lhs < rhs
endfunc " }}}

" LITERAL {{{

func! s:literalToString() dict
    return self.value
endfunc

let s:literal = {
    \ 'type': 'literal',
    \ 'ToString': function('s:literalToString'),
    \ }

func! s:parseLiteral(tok)
    let [kind, value] = a:tok.Next()
    return s:createLiteral(value, kind)
endfunc

func! s:createLiteral(value, ...)
    let kind = a:0 ? a:1 : 'literal'
    return extend(deepcopy(s:literal), {'kind': kind, 'value': a:value})
endfunc

" }}}

" FORM {{{

func! s:formInsertLiteral(literal) dict " {{{
    let newIndentCols = self.col + 2
    let length = len(self.children)
    if length < 2 || self.children[1].type ==# 'vector'
        let newIndentCols += len(self.first)
    endif

    let index = 0
    if self.first ==# 'ns'
        " special case; skip past the ns symbol
        while index < length && self.children[index].type !=# 'vector'
            let index += 1
        endwhile
    endif

    " find the index to insert
    while index < length
        let node = self.children[index]
        if !s:isWhitespace(node) && s:compare(a:literal, node)
            break
        endif
        let index += 1
    endwhile

    let indent = repeat(' ', newIndentCols)
    let toAdd = [
        \ s:createLiteral(a:literal),
        \ ]

    let indentIndex = 0
    if index < length
        " indent after *unless* we're appending to the end
        let indentIndex = len(toAdd)
    endif
    let toAdd = extend(toAdd, [
        \ s:createLiteral("\n", 'ws'),
        \ s:createLiteral(indent, 'ws'),
        \ ], indentIndex)

    let self.children = extend(self.children, toAdd, index)
endfunc " }}}

func! s:formFindClause(clause) dict " {{{
    if self.first ==# a:clause
        return self
    endif

    return s:findClauseInChildren(self, a:clause)
endfunc " }}}

func! s:formToString() dict " {{{
    let children = map(copy(self.children), 'v:val.ToString()')
    return '(' . self.first . join(children, '') . ')'
endfunc " }}}

let s:form = {
    \ 'type': 'form',
    \ 'InsertLiteral': function('s:formInsertLiteral'),
    \ 'FindClause': function('s:formFindClause'),
    \ 'ToString': function('s:formToString'),
    \ }

func! s:parseForm(tok) " {{{
    call a:tok.Expect('(')

    let [kind, first] = a:tok.Next()
    if kind !=# 'sym' && kind !=# 'kw'
        cal a:tok.Throw('Unexpected form first: ' . kind)
    endif

    let children = []
    while 1
        let [kind, next] = a:tok.Peek()
        if kind ==# ')'
            call a:tok.Next()
            break
        else
            let children = add(children, s:parse(a:tok))
        endif
    endwhile

    return s:withChildren(extend(deepcopy(s:form), {
        \ 'first': first,
        \ }), children)
endfunc " }}}

" }}}

" VECTOR {{{

func! s:vectorFindClause(clause) dict " {{{
    if empty(self.children)
        return v:null
    endif

    let first = self.children[0]
    if first.type ==# 'literal' && first.value ==# a:clause
        return self
    endif

    return s:findClauseInChildren(self, a:clause)
endfunc " }}}

func! s:vectorFindKeywordValue(keyword) dict " {{{
    let i = 0
    let length = len(self.children)

    while i < length
        let node = self.children[i]
        if node.type !=# 'literal' || node.kind !=# 'kw' || node.value !=# a:keyword
            let i += 1
            continue
        endif

        let valueIndex = i + 1
        while valueIndex < length && get(self.children[valueIndex], 'kind', '') ==# 'ws'
            let valueIndex += 1
        endwhile

        if valueIndex >= length
            break
        endif
        return self.children[valueIndex]
    endwhile

    return v:null
endfunc " }}}

func! s:vectorAddKeyPair(key, value) dict " {{{
    " find sorted insert index
    let index = 1  " assume there's an initial clause already
    let length = len(self.children)
    while index < length
        let node = self.children[index]
        if node.type ==# 'literal' && node.value[0] ==# ':' && node.value > a:key
            break
        endif
        let index += 1
    endwhile

    " TODO should we insert newlines?

    let toInsert = [
        \ s:createLiteral(a:key),
        \ s:createLiteral(' ', 'ws'),
        \ s:createLiteral(a:value),
        \ ]

    " insert or append whitespace if necessary
    if index == length
        let toInsert = insert(toInsert, s:createLiteral(' ', 'ws'), 0)
    elseif index < length
        let toInsert = add(toInsert, s:createLiteral(' ', 'ws'))
    endif

    let self.children = extend(self.children, toInsert, index)
endfunc " }}}

func! s:vectorInsertLiteral(literal) dict " {{{
    " find sorted insert index
    let index = 0
    let length = len(self.children)
    while index < length
        let node = self.children[index]
        if !s:isWhitespace(node) && s:compare(a:literal, node)
            break
        endif
        let index += 1
    endwhile

    let toInsert = [s:createLiteral(a:literal)]

    " insert whitespace before or after, as appropriate
    if a:literal[0] =~# '[\[(]'
        let indent = repeat(' ', self.col + 1)
        let indentIndex = 0
        if index < length
            " indent after *unless* we're appending to the end
            let indentIndex = len(toInsert)
        endif

        let toInsert = extend(toInsert, [
            \ s:createLiteral("\n", 'ws'),
            \ s:createLiteral(indent, 'ws'),
            \ ], indentIndex)
    elseif !empty(self.children) && index > 0
        let toInsert = insert(toInsert, s:createLiteral(' ', 'ws'), 0)
    elseif !empty(self.children)
        let toInsert = add(toInsert, s:createLiteral(' ', 'ws'))
    endif

    let self.children = extend(self.children, toInsert, index)
endfunc " }}}

func! s:vectorToString() dict " {{{
    let children = map(copy(self.children), 'v:val.ToString()')
    return '[' . join(children, '') . ']'
endfunc " }}}

let s:vector = {
    \ 'type': 'vector',
    \ 'FindKeywordValue': function('s:vectorFindKeywordValue'),
    \ 'FindClause': function('s:vectorFindClause'),
    \ 'InsertLiteral': function('s:vectorInsertLiteral'),
    \ 'AddKeyPair': function('s:vectorAddKeyPair'),
    \ 'ToString': function('s:vectorToString'),
    \ }

func! s:parseVector(tok) " {{{
    call a:tok.Expect('[')

    let children = []
    while 1
        let [kind, next] = a:tok.Peek()
        if kind ==# ']'
            call a:tok.Next()
            break
        else
            let children = add(children, s:parse(a:tok))
        endif
    endwhile

    return s:withChildren(deepcopy(s:vector), children)
endfunc " }}}

" }}}

func! s:parse(tok) " {{{
    let col = a:tok.Col()
    let [kind, next] = a:tok.Peek()
    if kind ==# '('
        let result = s:parseForm(a:tok)
    elseif kind ==# '['
        let result = s:parseVector(a:tok)
    else
        let result = s:parseLiteral(a:tok)
    endif
    let result.col = col
    return result
endfunc " }}}

" ======= Public interface ================================

func! hearth#util#ns_ast#Build(lines)
    let tok = hearth#util#ns_ast#tokenizer(a:lines)
    return s:parse(tok)
endfunc

func! hearth#util#ns_ast#ToLines(ast)
    return split(a:ast.ToString(), "\n", 1)
endfunc
