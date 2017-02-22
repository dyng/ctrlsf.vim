" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.9.0
" ============================================================================

let vmode = ctrlsf#CurrentMode()

if exists('b:current_syntax')
            \ && exists('b:current_view_mode')
            \ && b:current_view_mode ==# vmode
    finish
endif

" clear previous syntax
syntax clear

if vmode ==# 'normal'
    syntax case match
    syntax match ctrlsfFilename    /^.*\ze:$/
    syntax match ctrlsfLnumMatch   /^\d\+:/
    syntax match ctrlsfLnumUnmatch /^\d\+-/
    syntax match ctrlsfCuttingLine /^\.\+$/
else
    syntax case match
    syntax match qfLineNr     /[^|]*/  contained contains=qfError
    syntax match qfSeparator  /|/  contained nextgroup=qfLineNr
    syntax match qfFileName   /^[^|]*/  nextgroup=qfSeparator
    syntax match qfError      /error/  contained
endif

" highlightment group can be shared between different syntaxes
hi def link ctrlsfFilename     Title
hi def link ctrlsfLnumMatch    SignColumn
hi def link ctrlsfLnumUnmatch  LineNr
hi def link ctrlsfSelectedLine Visual
hi def link ctrlsfMatch        MatchParen
hi def link qfFileName         Directory
hi def link qfError            Error

let b:current_view_mode = vmode
let b:current_syntax = 'ctrlsf'
