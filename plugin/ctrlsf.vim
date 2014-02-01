" ============================================================================
" File: plugin/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

" Loading {{{1
if !exists('g:ctrlsf_debug') && exists('g:ctrlsf_loaded')
    finish
endif
let g:ctrlsf_loaded = 1
" }}}

" Utils {{{1
" s:DetectAckprg() {{{2
func! s:DetectAckprg()
    if executable('ag')
        return 'ag'
    endif

    if executable('ack-grep')
        return 'ack-grep'
    endif

    if executable('ack')
        return 'ack'
    endif

    return ''
endf
" }}}
" }}}

" Options {{{1
if !exists('g:ctrlsf_open_left')
    let g:ctrlsf_open_left = 1
endif

if !exists('g:ctrlsf_ackprg')
    let g:ctrlsf_ackprg = s:DetectAckprg()
endif

if !exists('g:ctrlsf_auto_close')
    let g:ctrlsf_auto_close = 1
endif

if !exists('g:ctrlsf_context')
    let g:ctrlsf_context = '-C 3'
endif

if !exists('g:ctrlsf_width')
    let g:ctrlsf_width = 'auto'
endif

if !exists('g:ctrlsf_selected_line_hl')
    let g:ctrlsf_selected_line_hl = 'p'
endif
" }}}

" Commands {{{1
com! -n=* -comp=customlist,s:PathnameComp CtrlSF        call ctrlsf#Search(<q-args>)
com! -n=0                                 CtrlSFOpen    call ctrlsf#OpenWindow()
com! -n=0                                 CtrlSFClose   call ctrlsf#CloseWindow()
com! -n=0                                 CtrlSFClearHL call ctrlsf#ClearSelectedLine()
" }}}

" Completion Func {{{1
" We need a custom completion function because if we use '-comp=file' then vim
" regards CtrlSF expecting file arguments and expand '%' to current file, '#'
" to alternate file and so on automatically, which is not what we want.
func! s:PathnameComp(arglead, cmdline, cursorpos)
    let path     = a:arglead
    let expanded = expand(path)
    let is_glob  = (expanded == a:arglead) ? 0 : 1

    if is_glob
        if expanded =~ '\n'
            let candidate = split(expanded, '\n')
        else
            let candidate = [ expanded ]
        endif
        call map(candidate, 'fnamemodify(v:val, ":p:.")')
    else
        if isdirectory(path) && path !~ '/$'
            let candidate = [ path . '/' ]
        else
            let candidate = split(glob(path . '*'), '\n')
            call map(candidate, 'fnamemodify(v:val, ":.")')
        endif
    endif

    return candidate
endf
" }}}

" Airline support {{{1
if exists('*airline#add_statusline_func')
    call airline#add_statusline_func('ctrlsf#StatusLine')
    call airline#add_statusline_func('ctrlsf#PreviewStatusLine')
endif
" }}}

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
