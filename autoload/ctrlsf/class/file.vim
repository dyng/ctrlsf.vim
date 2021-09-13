" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.6.0
" ============================================================================
" New()
"
" Create a file object which has filename and paragraphs. Caller should make
" sure that all paragraphs are contained in given file.
"
func! ctrlsf#class#file#New(fname, paragraphs) abort
    return {
        \ 'filename'    : a:fname,
        \ 'paragraphs'  : a:paragraphs,
        \ 'add'         : function("ctrlsf#class#file#Add"),
        \ 'start_vlnum' : function("ctrlsf#class#file#StartVlnum"),
        \ 'end_vlnum'   : function("ctrlsf#class#file#EndVlnum"),
        \ 'first_match' : function("ctrlsf#class#file#FirstMatch"),
        \ }
endf

" Add()
"
func! ctrlsf#class#file#Add(paragraph) abort dict
    call add(self.paragraphs, a:paragraph)
endf

" StartVlnum()
"
func! ctrlsf#class#file#StartVlnum(...) abort dict
    let vmode = get(a:, 1, 'normal')
    if vmode ==# 'normal'
        " line number of filename
        return self.paragraphs[0].vlnum('normal') - 1
    else
        return self.paragraphs[0].matches()[0].vlnum('compact')
    endif
endf

" EndVlnum()
"
func! ctrlsf#class#file#EndVlnum(...) abort dict
    let vmode = get(a:, 1, 'normal')
    if vmode ==# 'normal'
        " line number of last blank line
        let last_par = self.paragraphs[-1]
        return last_par.vlnum(vmode) + last_par.range()
    else
        return self.paragraphs[0].matches()[-1].vlnum('compact')
    endif
endf

" FirstMatch()
"
func! ctrlsf#class#file#FirstMatch() abort dict
    return self.paragraphs[0].matches()[0]
endf
