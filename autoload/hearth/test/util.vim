func! s:IsValidErrorEntry(entry)
    let entry = a:entry
    if entry.valid || entry.text =~ "\tfail\t"
        return 1
    endif

    if entry.type ==# 'W' && entry.text ==# ''
        return 1
    endif

    return 0
endfunc

func! hearth#test#util#ParseResults(path, lines) abort " {{{
    let entries = []
    for line in a:lines
        if line =~# '\t.*\t.*\t'
            let entry = {'text': line}
            let [resource, lnum, type, name] = split(line, "\t", 1)
            let entry.lnum = lnum
            let entry.type = (type ==# 'fail' ? 'W' : 'E')
            let entry.text = name
            if resource ==# 'NO_SOURCE_FILE'
                let resource = ''
                let entry.lnum = 0
            endif
            let entry.filename = resource
            if !filereadable(entry.filename)
                let entry.filename = fireplace#findresource(resource, a:path)
            endif
            if empty(entry.filename)
                let entry.lnum = 0
            endif
        else
            let entry = {'text': line}
        endif
        call add(entries, entry)
    endfor
    return entries
endfunc " }}}

func! hearth#test#util#PresentTestResults(id, path, expr)
    let list = a:id ? getqflist({'id': a:id, 'items': 1}).items : getqflist()
    let noneValid = empty(filter(list, 's:IsValidErrorEntry(v:val)'))
    if noneValid
        cwindow

        redraw

        if empty(a:path)
            echo 'No failures, but also no path; is this file in the right place?'
        else
            echo 'Success: ' . a:expr
        endif
    else
        if get(getqflist({'id': 0}), 'id') ==# a:id
            let was_qf = &buftype ==# 'quickfix'
            botright copen
            if &buftype ==# 'quickfix' && !was_qf
                wincmd p
            endif

            redraw
            echo 'Failure: ' . a:expr
        endif
    endif
endfunc
