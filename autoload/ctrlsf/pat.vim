" Regex()
"
func! ctrlsf#pat#Regex(...) abort
    " ignore case
    let case_sensitive = ctrlsf#opt#GetCaseSensitive()
    let case = ''
    if case_sensitive ==# 'ignorecase'
        let case = '\c'
    elseif case_sensitive ==# 'matchcase'
        let case = '\C'
    else "smartcase
        let pat  = ctrlsf#opt#GetOpt('pattern')
        let case = (pat =~# '\u') ? '\C' : '\c'
    endif

    " magic
    let magic = ctrlsf#opt#GetOpt('regex') ? '\v' : '\V'

    " literal
    let pattern = ''
    if ctrlsf#opt#GetOpt('regex')
        let pattern = ctrlsf#opt#GetOpt('pattern')
    else
        let pattern = escape(ctrlsf#opt#GetOpt('pattern'), '\/')
    endif

    let regex = printf('%s%s%s', magic, case, pattern)
    call ctrlsf#log#Debug("Pattern: %s", regex)

    return regex
endf

" HighlightRegex()
"
func! ctrlsf#pat#HighlightRegex() abort
    let base = ctrlsf#pat#Regex()

    let magic   = strpart(base, 0, 2)
    let case    = strpart(base, 2, 2)
    let pattern = strpart(base, 4)

    " sign (to prevent matching out of file body)
    let sign = ''
    if magic ==# '\v'
        let sign = '(^\d+:.*)@<='
    else
        let sign = '\(\^\d\+:\.\*\)\@<='
    endif

    let regex = printf('/%s%s%s%s/', magic, case, sign, pattern)
    call ctrlsf#log#Debug("Highlighting: %s", regex)

    return regex
endf
