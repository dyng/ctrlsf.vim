" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

" HighlightMatch()
"
func! ctrlsf#hl#HighlightMatch(hlgroup) abort
    if !exists('b:current_syntax') || b:current_syntax !~# 'ctrlsf'
        return -1
    endif

    let regex = printf('/%s/', escape(ctrlsf#opt#GetOpt("_vimhlregex"), '/'))
    call ctrlsf#log#Debug("HighlightRegex: %s", regex)

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
