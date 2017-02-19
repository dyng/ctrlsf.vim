" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.8.3
" ============================================================================

let mode = ctrlsf#CurrentMode()

if exists('b:current_syntax')
            \ && exists('b:current_view_mode')
            \ && b:current_view_mode ==# mode
    finish
endif

" clear previous syntax
syntax clear

if mode ==# 'normal'
    syntax case match
    syntax match ctrlsfFilename    /^.*\ze:$/
    syntax match ctrlsfLnumMatch   /^\d\+:/
    syntax match ctrlsfLnumUnmatch /^\d\+-/
    syntax match ctrlsfCuttingLine /^\.\+$/

    hi def link ctrlsfFilename     Title
    hi def link ctrlsfLnumMatch    SignColumn
    hi def link ctrlsfLnumUnmatch  LineNr
    hi def link ctrlsfSelectedLine Visual
    hi def link ctrlsfMatch        MatchParen
else
    syntax case match
    syntax match qfLineNr     /[^|]*/  contained contains=qfError
    syntax match qfSeparator  /|/  contained nextgroup=qfLineNr
    syntax match qfFileName   /^[^|]*/  nextgroup=qfSeparator
    syntax match qfError      /error/  contained

    hi def link qfFileName    Directory
    hi def link qfError       Error
    hi def link ctrlsfMatch   MatchParen
endif

let b:current_view_mode = mode
let b:current_syntax = 'ctrlsf'
