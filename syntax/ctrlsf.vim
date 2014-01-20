" ============================================================================
" File: syntax/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

if exists('b:current_syntax')
    finish
endif

syntax case match
syntax match ctrlsfFilename    /^.*\ze:$/
syntax match ctrlsfLnumMatch   /^\d\+:/
syntax match ctrlsfLnumUnmatch /^\d\+-/

hi def link ctrlsfFilename     Title
hi def link ctrlsfMatch        Search
hi def link ctrlsfLnumMatch    Visual
hi def link ctrlsfLnumUnmatch  Comment
hi def link ctrlsfSelectedLine Visual

let b:current_syntax = 'ctrlsf'
