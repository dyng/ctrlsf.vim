" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.20
" ============================================================================

" New()
"
" Notice that some fields are initialized with -1, which will be populated
" in render processing.
"
func! ctrlsf#class#match#New(fname, lnum, col) abort
    return {
        \ 'filename' : a:fname,
        \ 'lnum'     : a:lnum,
        \ 'vlnum'    : -1,
        \ 'col'      : a:col,
        \ 'vcol'     : -1
        \ }
endf
