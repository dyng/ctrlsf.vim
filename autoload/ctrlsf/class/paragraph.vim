" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.20
" ============================================================================

" New()
"
" Create a paragraph object based on parsed lines. Acceptable argument
" 'buffer' is a list of defactorized line [fname, lnum, content].
"
func! ctrlsf#class#paragraph#New(buffer) abort
    let fname = a:buffer[0][0]

    let paragraph = {
        \ 'filename' : fname,
        \ 'lnum'     : function("ctrlsf#class#paragraph#Lnum"),
        \ 'vlnum'    : function("ctrlsf#class#paragraph#Vlnum"),
        \ 'range'    : function("ctrlsf#class#paragraph#Range"),
        \ 'lines'    : [],
        \ 'matches'  : function("ctrlsf#class#paragraph#Matches"),
        \ 'setlnum'  : function("ctrlsf#class#paragraph#SetLnum"),
        \ }

    for [fname, lnum, content] in a:buffer
        call add(paragraph.lines, ctrlsf#class#line#New(fname, lnum, content))
    endfo

    return paragraph
endf

" Lnum()
"
func! ctrlsf#class#paragraph#Lnum() abort dict
    return self.lines[0].lnum
endf

" Vlnum()
"
func! ctrlsf#class#paragraph#Vlnum() abort dict
    return self.lines[0].vlnum
endf

" Range()
"
func! ctrlsf#class#paragraph#Range() abort dict
    return len(self.lines)
endf

" Matches()
"
func! ctrlsf#class#paragraph#Matches() abort dict
    let matches = []
    for line in self.lines
        if line.matched()
            let dict = extend({'file': self.file}, {'text': line.content})
            call add(matches, extend(line.match, dict))
        endif
    endfo
    return matches
endf

" SetLnum()
"
func! ctrlsf#class#paragraph#SetLnum(lnum) abort dict
    let i = 0
    for line in self.lines
        call line.setlnum(a:lnum + i)
        let i += 1
    endfo
endf
