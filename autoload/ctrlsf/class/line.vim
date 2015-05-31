" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

" Matched()
"
func! ctrlsf#class#line#Matched() abort dict
    return !empty(self.match)
endf
