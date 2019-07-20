func! hearth#pref#Get(key, default)
    let fullKey = 'hearth_' . a:key
    if has_key(b:, fullKey)
        return get(b:, fullKey)
    endif
    return get(g:, fullKey, a:default)
endfunc
