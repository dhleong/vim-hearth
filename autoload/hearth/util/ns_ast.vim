
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

func! s:tokStringLiteral() dict " {{{
    let self._lines[0] = self._lines[0][1:]
    let literal = ''
    while !empty(self._lines)
        let line = self._lines[0]
        let i = 0
        let length = len(line)
        while i < length
            if line[i] ==# '"' && (i == 0 || line[i-1] !=# '\')
                let literal .= line[0:i - 1]
                let self._lines[0] = line[len(literal)+1:]
                return ['string', literal]
            endif
            let i += 1
        endwhile

        " couldn't find on this line; perhaps on the next?
        let literal .= line . "\n"
        let self._lines = self._lines[1:]
    endwhile

    throw 'Unterminated string: "' . literal
endfunc " }}}

func! s:tokNext() dict
    if !(type(self._peeked) == type(v:null) && self._peeked == v:null)
        let next = self._peeked
        let self._peeked = v:null
        return next
    endif

    while len(self._lines) && empty(self._lines[0])
        let self._lines = self._lines[1:]
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
            let self._lines[0] = self._lines[0][len(m):]
            return [kind, m]
        endif
    endfor

    throw 'Parse error; unexpected: ' . self._lines
endfunc

func! s:tokPeek() dict
    if type(self._peeked) == type(v:null) && self._peeked == v:null
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
    " TODO we could include some position info
    throw a:message
endfunc

let s:tokenizer = {
            \ '_peeked': v:null,
            \ 'stringLiteral': function('s:tokStringLiteral'),
            \ 'Expect': function('s:tokExpect'),
            \ 'Next': function('s:tokNext'),
            \ 'Peek': function('s:tokPeek'),
            \ 'Throw': function('s:tokThrow'),
            \ }

func! hearth#util#ns_ast#tokenizer(lines)
    let tokenizer = deepcopy(s:tokenizer)
    let tokenizer._lines = a:lines
    return tokenizer
endfunc

" }}}


" ======= AST parsing =====================================

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
    return extend(deepcopy(s:literal), {'kind': kind, 'value': value})
endfunc

" }}}

" FORM {{{

func! s:formFindClause(first) dict
    for child in self.children
        if child.type ==# 'form'
            if child.first ==# a:first
                return child
            endif

            let fromChild = child.FindClause(a:first)
            if !empty(fromChild)
                return fromChild
            endif
        endif
    endfor
    return v:null
endfunc

func! s:formToString() dict
    let children = map(copy(self.children), 'v:val.ToString()')
    return '(' . self.first . join(children, '') . ')'
endfunc

let s:form = {
        \ 'type': 'form',
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

    return extend(deepcopy(s:form), {
        \ 'children': children,
        \ 'first': first,
        \ })
endfunc " }}}

" }}}

" VECTOR {{{

func! s:vectorToString() dict
    let children = map(copy(self.children), 'v:val.ToString()')
    return '[' . join(children, '') . ']'
endfunc

let s:vector = {
        \ 'type': 'vector',
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

    return extend(deepcopy(s:vector), {
        \ 'children': children,
        \ })
endfunc " }}}

" }}}

func! s:parse(tok)
    let [kind, next] = a:tok.Peek()
    if kind ==# '('
        return s:parseForm(a:tok)
    elseif kind ==# '['
        return s:parseVector(a:tok)
    else
        return s:parseLiteral(a:tok)
    endif
endfunc

func! hearth#util#ns_ast#Build(lines)
    let tok = hearth#util#ns_ast#tokenizer(a:lines)
    return s:parseForm(tok)
endfunc
