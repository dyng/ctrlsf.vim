" HighlightMatch()
func! ctrlsf#hl#HighlightMatch() abort
    if !exists('b:current_syntax') || b:current_syntax != 'ctrlsf'
        return -1
    endif

    let case = ''
    if (g:ctrlsf_ackprg =~# 'ag' || ctrlsf#opt#GetOpt('ignorecase'))
        let case = '\c'
    endif
    let pattern = printf('/\v%s%s/', case, escape(ctrlsf#opt#GetOpt('pattern'), '/'))

    exec 'match ctrlsfMatch ' . pattern
endf

" HighlightSelectedLine()
func! ctrlsf#hl#HighlightSelectedLine() abort
    " Clear previous highlight
    silent! call matchdelete(b:ctrlsf_highlight_id)

    let pattern = '\%' . line('.') . 'l.*'
    let b:ctrlsf_highlight_id = matchadd('ctrlsfSelectedLine', pattern, -1)
endf
