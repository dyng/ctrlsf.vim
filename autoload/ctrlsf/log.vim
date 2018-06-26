" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" s:Echo()
"
" Parameters
" {format}  format same as printf()
" {argv}    list of values that will be bound to format
" {hlgroup} highlight group used to print message
" {save}    whether to save this message to history
"
func! s:Echo(format, argv, hlgroup, save) abort
    let echo = a:save ? "echom" : "echo"
    let messages = split(s:Printf(a:format, a:argv), "\n")
    exec 'echohl ' . a:hlgroup
    for mes in messages | exec echo . " mes" | endfo
    echohl None
endf

" s:Printf()
"
func! s:Printf(format, argv) abort
    if len(a:argv) == 0
        return a:format
    else
        let argv = map(copy(a:argv), 'string(v:val)')
        exec 'return printf(a:format,' . join(argv, ',') . ')'
    endif
endf

" Clear()
"
" Clear printed messages.
"
func! ctrlsf#log#Clear() abort
    echo ""
endf

" Notice()
"
func! ctrlsf#log#Notice(format, ...) abort
    call s:Echo(a:format, a:000, 'WarningMsg', 0)
endf

" Debug()
"
func! ctrlsf#log#Debug(format, ...) abort
    if g:ctrlsf_debug_mode
        call s:Echo(a:format, a:000, 'None', 1)
    endif
endf

" Info()
"
func! ctrlsf#log#Info(format, ...) abort
    call s:Echo(a:format, a:000, 'MoreMsg', 1)
endf

" Warn()
"
func! ctrlsf#log#Warn(format, ...) abort
    call s:Echo(a:format, a:000, 'WarningMsg', 1)
endf

" Error()
"
func! ctrlsf#log#Error(format, ...) abort
    call s:Echo(a:format, a:000, 'ErrorMsg', 1)
endf
