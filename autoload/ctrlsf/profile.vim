" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" sample container
let s:samples = []

" Sample()
"
" Take a sample.
"
func! ctrlsf#profile#Sample(name) abort
    call add(s:samples, {
                \ "name": a:name,
                \ "time": reltime()
                \ })
endf

" Report()
"
func! ctrlsf#profile#Report() abort
    let prev = {}
    for sam in s:samples
        if empty(prev)
            call ctrlsf#log#Info("Point: '%s'", sam.name)
        else
            call ctrlsf#log#Info("Point: '%s', ElapsedTime: %s",
                        \ sam.name, reltimestr(reltime(prev.time, sam.time)))
        endif
        let prev = sam
    endfo
endf

" Reset()
"
func! ctrlsf#profile#Reset() abort
    let s:samples = []
endf
