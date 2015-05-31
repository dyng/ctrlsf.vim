" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

"""""""""""""""""""""""""""""""""
" Misc Functions
"""""""""""""""""""""""""""""""""
" Mirror()
"
" Make {dicta} as an exact shallow copy of {dictb}
"
func! ctrlsf#utils#Mirror(dicta, dictb) abort
    for key in keys(a:dicta)
        if has_key(a:dictb, key)
            let a:dicta[key] = a:dictb[key]
        else
            call remove(a:dicta, key)
        endif
    endfo

    return a:dicta
endf

"""""""""""""""""""""""""""""""""
" Airline Support
"""""""""""""""""""""""""""""""""

" SectionB()
"
" Show current search pattern
"
func! ctrlsf#utils#SectionB()
    return 'Pattern: ' . ctrlsf#opt#GetOpt('pattern')
endf

" SectionC()
"
" Show filename of which cursor is currently placed in
"
func! ctrlsf#utils#SectionC()
    let [file, _, _] = ctrlsf#view#Reflect(line('.'))
    return empty(file) ? '' : file
endf

" SectionX()
"
" Show total number of matches and current matching
"
func! ctrlsf#utils#SectionX()
    let [file, line, match] = ctrlsf#view#Reflect(line('.'))
    if !empty(match)
        let matchlist = ctrlsf#db#MatchList()
        let total     = len(matchlist)
        let current   = index(matchlist, match) + 1
        return current . '/' . total
    else
        return ''
    endif
endf

" PreviewSectionC()
"
" Show previewing file's name
"
func! ctrlsf#utils#PreviewSectionC()
    return get(b:, 'ctrlsf_file', '')
endf
