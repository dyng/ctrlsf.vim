" HighlightMatch()
"
func! ctrlsf#hl#HighlightMatch(hlgroup) abort
    if !exists('b:current_syntax') || b:current_syntax !~# 'ctrlsf'
        return -1
    endif

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

    " sign (to prevent matching out of file body)
    let sign = ''
    if magic ==# '\v'
        let sign = '(^\d+:.*)@<='
    else
        let sign = '\(\^\d\+:\.\*\)\@<='
    endif

    let regex = printf('/%s%s%s%s/', magic, case, sign, pattern)
    call ctrlsf#log#Debug("Hightlight: %s", regex)

    exec printf('2match none | 2match %s %s', a:hlgroup, regex)
endf

" HighlightSelectedLine()
"
func! ctrlsf#hl#HighlightSelectedLine() abort
    " Clear previous highlight
    silent! call matchdelete(b:ctrlsf_highlight_id)

    let pattern = '\%' . line('.') . 'l.*'
    let b:ctrlsf_highlight_id = matchadd('ctrlsfSelectedLine', pattern, -1)
endf

" ClearSelectedLine()
"
func! ctrlsf#hl#ClearSelectedLine() abort
    silent! call matchdelete(b:ctrlsf_highlight_id)
endf
