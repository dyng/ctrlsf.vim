" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

" s:Echo(format, argv, hlgroup, save)
"
" Parameters
" {format}  format same as printf()
" {argv}    list of values that will be bound to format
" {hlgroup} highlight group used to print message
" {save}    if save this message to history
"
func! s:Echo(format, argv, hlgroup, save) abort
    let message = s:Printf(a:format, a:argv)
    exec 'echohl ' . a:hlgroup
    exec a:save ? "echom message" : "echo message"
    echohl None
endf

" s:Printf(format, argv)
"
func! s:Printf(format, argv) abort
    if len(a:argv) == 0
        return a:format
    else
        let argv = map(copy(a:argv), 'string(v:val)')
        exec 'return printf(a:format,' . join(argv, ',') . ')'
    endif
endf

" Notice(format, ...)
"
func! ctrlsf#log#Notice(format, ...) abort
    call s:Echo(a:format, a:000, 'None', 0)
endf

" Debug(format, ...)
"
func! ctrlsf#log#Debug(format, ...) abort
    if g:ctrlsf_debug_mode
        call s:Echo(a:format, a:000, 'None', 1)
    endif
endf

" Info(format, ...)
"
func! ctrlsf#log#Info(format, ...) abort
    call s:Echo(a:format, a:000, 'MoreMsg', 1)
endf

" Warn(format, ...)
"
func! ctrlsf#log#Warn(format, ...) abort
    call s:Echo(a:format, a:000, 'WarningMsg', 1)
endf

" Error(format, ...)
"
func! ctrlsf#log#Error(format, ...) abort
    call s:Echo(a:format, a:000, 'ErrorMsg', 1)
endf
