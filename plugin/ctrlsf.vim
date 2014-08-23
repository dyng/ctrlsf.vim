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

" g:CtrlSFGetVisualSelection() {{{2
" Thanks to xolox!
" http://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
func! g:CtrlSFGetVisualSelection()
    " Why is this not a built-in Vim script function?!
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endf
" }}}

" s:SearchCwordCmd() {{{2
func! s:SearchCwordCmd(to_exec)
    let cmd = ":\<C-U>CtrlSF " . expand('<cword>')
    let cmd .= a:to_exec ? "\r" : " "
    return cmd
endf
" }}}

" s:SearchVwordCmd() {{{2
" Within evaluation of a expression typed visual map, we can not get
" current visual selection normally, so I need to workaround it.
func! s:SearchVwordCmd(to_exec)
    let keys = '":\<C-U>CtrlSF " . g:CtrlSFGetVisualSelection()'
    let keys .= a:to_exec ? '."\r"' : '." "'
    let cmd = ":\<C-U>call feedkeys(" . keys . ")\r"
    return cmd
endf
" }}}

" s:SearchPwordCmd() {{{2
func! s:SearchPwordCmd(to_exec)
    let cmd = ":\<C-U>CtrlSF " . @/
    let cmd .= a:to_exec ? "\r" : " "
    return cmd
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

if !exists('g:ctrlsf_leading_space')
    let g:ctrlsf_leading_space = 12
endif
" }}}

" Commands {{{1
com! -n=* -comp=customlist,s:PathnameComp CtrlSF        call ctrlsf#Search(<q-args>)
com! -n=0                                 CtrlSFOpen    call ctrlsf#OpenWindow()
com! -n=0                                 CtrlSFClose   call ctrlsf#CloseWindow()
com! -n=0                                 CtrlSFClearHL call ctrlsf#ClearSelectedLine()
" }}}

" Maps {{{1
nnoremap        <Plug>CtrlSFPrompt    :CtrlSF<Space>
nnoremap <expr> <Plug>CtrlSFCwordPath <SID>SearchCwordCmd(0)
nnoremap <expr> <Plug>CtrlSFCwordExec <SID>SearchCwordCmd(1)
vnoremap <expr> <Plug>CtrlSFVwordPath <SID>SearchVwordCmd(0)
vnoremap <expr> <Plug>CtrlSFVwordExec <SID>SearchVwordCmd(1)
nnoremap <expr> <Plug>CtrlSFPwordPath <SID>SearchPwordCmd(0)
nnoremap <expr> <Plug>CtrlSFPwordExec <SID>SearchPwordCmd(1)
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

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
