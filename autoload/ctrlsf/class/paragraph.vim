" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.10
" ============================================================================

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
            call add(matches, line.match)
        endif
    endfo
    return matches
endf
