try
    call ale#fix#registry#Add(
        \ 'hearth',
        \ 'hearth#lint#fix#Fix',
        \ ['clojure'],
        \ 'Fireplace-powered clojure fixes',
        \ )
catch /E117/
    " ale not available
endtry
