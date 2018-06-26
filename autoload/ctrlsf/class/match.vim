" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" New()
"
" Notice that some fields are initialized with -1, which will be populated
" in render processing.
"
" This structure is designed to be suitable for argument of setqflist().
"
func! ctrlsf#class#match#New(fname, lnum, col, content) abort
    return {
        \ 'filename' : a:fname,
        \ 'lnum'     : a:lnum,
        \ 'vlnum'    : -1,
        \ 'col'      : a:col,
        \ 'vcol'     : -1,
        \ 'text'     : a:content,
        \ 'setlnum'  : function("ctrlsf#class#match#SetLnum"),
        \ }
endf

" SetLnum()
"
func! ctrlsf#class#match#SetLnum(lnum) abort dict
    let self.lnum = a:lnum
endf
