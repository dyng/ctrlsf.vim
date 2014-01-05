" ============================================================================
" File: syntax/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

let g:ctrlsf_ackprg = 'ag'
if exists('b:current_syntax')
    finish
endif

syntax case match
syntax match ctrlsfFilename    /^.*\ze:$/
syntax match ctrlsfLnumMatch   /^\d\+:/
syntax match ctrlsfLnumUnmatch /^\d\+-/

hi link ctrlsfFilename    Title
hi link ctrlsfMatch       Search
hi link ctrlsfLnumMatch   Visual
hi link ctrlsfLnumUnmatch Comment

let b:current_syntax = 'ctrlsf'
