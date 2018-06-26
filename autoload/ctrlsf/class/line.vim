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
func! ctrlsf#class#line#New(fname, lnum, content) abort
    let mat_col = match(a:content, ctrlsf#opt#GetOpt("_vimregex")) + 1
    let match = (mat_col > 0)?
        \ ctrlsf#class#match#New(a:fname, a:lnum, mat_col, a:content) : {}

    return {
        \ 'lnum'    : a:lnum,
        \ 'vlnum'   : -1,
        \ 'content' : a:content,
        \ 'match'   : match,
        \ 'matched' : function("ctrlsf#class#line#Matched"),
        \ 'setlnum' : function("ctrlsf#class#line#SetLnum"),
        \ }
endf

" Matched()
"
func! ctrlsf#class#line#Matched() abort dict
    return !empty(self.match)
endf

" SetLnum()
"
func! ctrlsf#class#line#SetLnum(lnum) abort dict
    let self.lnum = a:lnum
    if self.matched()
        call self.match.setlnum(a:lnum)
    endif
endf
