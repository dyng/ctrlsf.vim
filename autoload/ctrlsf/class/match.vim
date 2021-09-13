" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.6.0
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
        \ 'col'      : a:col,
        \ 'vpos'     : {'normal':{'lnum':-1, 'col':-1}, 'compact':{'lnum':-1, 'col':-1}},
        \ 'text'     : a:content,
        \ 'vlnum'    : function('ctrlsf#class#match#Vlnum'),
        \ 'vcol'     : function('ctrlsf#class#match#Vcol'),
        \ 'set_vpos' : function('ctrlsf#class#match#SetViewPosition'),
        \ }
endf

" Vlnum()
"
func! ctrlsf#class#match#Vlnum(...) abort dict
    let vmode = get(a:, 1, 'normal')
    return self.vpos[vmode]['lnum']
endf

" Vcol()
"
func! ctrlsf#class#match#Vcol(...) abort dict
    let vmode = get(a:, 1, 'normal')
    return self.vpos[vmode]['col']
endf

" SetViewPosition()
"
func! ctrlsf#class#match#SetViewPosition(lnum, col, ...) abort dict
    let vmode = get(a:, 1, 'normal')
    let self.vpos[vmode]['lnum'] = a:lnum
    let self.vpos[vmode]['col'] = a:col
endf
