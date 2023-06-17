function hearth#util#host#IsBabashka()
    let platform = fireplace#platform()
    if !platform.HasOp('eval')
        " Not connected, so... assume not
        return 0
    endif

    return platform.Query("(try (the-ns 'babashka.fs) true (catch Exception _ false))")
endfunction
