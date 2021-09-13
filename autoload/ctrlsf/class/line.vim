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
func! ctrlsf#class#line#New(fname, lnum, content) abort
    let mat_col = match(a:content, ctrlsf#opt#GetOpt("_vimregex")) + 1
    let match = (mat_col > 0)?
        \ ctrlsf#class#match#New(a:fname, a:lnum, mat_col, a:content) : {}

    return {
        \ 'lnum'      : a:lnum,
        \ 'vpos'      : {'normal':{'lnum':-1}},
        \ 'content'   : a:content,
        \ 'match'     : match,
        \ 'matched'   : function("ctrlsf#class#line#Matched"),
        \ 'vlnum'     : function('ctrlsf#class#line#Vlnum'),
        \ 'set_vlnum' : function('ctrlsf#class#line#SetViewLnum'),
        \ }
endf

" Matched()
"
func! ctrlsf#class#line#Matched() abort dict
    return !empty(self.match)
endf

" Vlnum()
"
func! ctrlsf#class#line#Vlnum(...) abort dict
    let vmode = get(a:, 1, 'normal')
    if vmode ==# 'normal'
        return self.vpos['normal']['lnum']
    else
        if self.matched()
            return self.match.vlnum('compact')
        else
            return -1
        endif
    endif
endf

" SetViewLnum()
"
func! ctrlsf#class#line#SetViewLnum(lnum) abort dict
    let self.vpos['normal']['lnum'] = a:lnum
endf
