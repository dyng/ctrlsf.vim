" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.32
" ============================================================================

if exists('b:current_syntax')
    finish
endif

syntax case match
syntax match ctrlsfFilename    /^.*\ze:$/
syntax match ctrlsfLnumMatch   /^\d\+:/
syntax match ctrlsfLnumUnmatch /^\d\+-/
syntax match ctrlsfCuttingLine /^\.\+$/

hi def link ctrlsfFilename     Title
hi def link ctrlsfMatch        MatchParen
hi def link ctrlsfLnumMatch    SignColumn
hi def link ctrlsfLnumUnmatch  LineNr
hi def link ctrlsfSelectedLine Visual

let b:current_syntax = 'ctrlsf'
