" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" Loading Guard {{{1
if exists('g:ctrlsf_loaded') && !get(g:, 'ctrlsf_debug_mode', 0)
    finish
endif
let g:ctrlsf_loaded = 1
" }}}

" Utils {{{1
" s:VisualSelection() {{{
" Thanks to xolox!
" http://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
func! s:VisualSelection() abort
    " Why is this not a built-in Vim script function?!
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endf
" }}}

" g:CtrlSFGetVisualSelection() {{{2
func! g:CtrlSFGetVisualSelection()
    let selection = s:VisualSelection()

    " A conditional process is needed because string("'") will return ''''
    " but our option parser can't parse it properly
    "
    " Isn't the else clause unnecessary? Yes, but I prefer plain text :)
    if selection =~# "'"
        return '"' . escape(selection, ' \"') . '"'
    elseif selection =~# '[ \"]'
        return string(selection)
    else
        return selection
    endif
endf
" }}}

" s:SearchCwordCmd() {{{2
func! s:SearchCwordCmd(type, word_boundary, to_exec)
    let cmd = ":\<C-U>" . a:type
    if a:word_boundary
        let cmd .= ' -R \b' . expand('<cword>') . '\b'
    else
        let cmd .= " " . expand('<cword>')
    endif
    let cmd .= a:to_exec ? "\<CR>" : " "
    return cmd
endf
" }}}

" s:SearchVwordCmd() {{{2
" Within evaluation of a expression typed visual map, we can not get
" current visual selection normally, so I need to workaround it.
func! s:SearchVwordCmd(type, to_exec)
    let keys = '":\<C-U>'. a:type .' " . g:CtrlSFGetVisualSelection()'
    let keys .= a:to_exec ? '."\<CR>"' : '." "'
    let cmd = ":\<C-U>call feedkeys(" . keys . ", 'n')\<CR>"
    return cmd
endf
" }}}

" s:SearchPwordCmd() {{{2
func! s:SearchPwordCmd(type, to_exec)
    let cmd = ":\<C-U>" . a:type . " " . @/
    let cmd .= a:to_exec ? "\<CR>" : " "
    return cmd
endf
" }}}
" }}}

" Options {{{1
" g:ctrlsf_absolute_file_path {{{2
if !exists('g:ctrlsf_absolute_file_path')
    let g:ctrlsf_absolute_file_path = 0
endif
" }}}

" g:ctrlsf_ackprg {{{2
if !exists('g:ctrlsf_ackprg')
    let g:ctrlsf_ackprg = ctrlsf#backend#Detect()
endif
" }}}

" g:ctrlsf_auto_close {{{2
if !exists('g:ctrlsf_auto_close')
    let g:ctrlsf_auto_close = {
        \ "normal" : 1,
        \ "compact": 0
        \ }
endif
" }}}

" g:ctrlsf_auto_focus {{{2
if !exists('g:ctrlsf_auto_focus')
    let g:ctrlsf_auto_focus = {
        \ "at" : "none",
        \ }
else
    " set default 'duration_less_than': 1000 milliseconds
    if g:ctrlsf_auto_focus['at'] ==# 'done'
        \ && !has_key(g:ctrlsf_auto_focus, 'duration_less_than')
        let g:ctrlsf_auto_focus['duration_less_than'] = 1000
    endif
endif
" }}}

" g:ctrlsf_case_sensitive {{{2
if !exists('g:ctrlsf_case_sensitive')
    let g:ctrlsf_case_sensitive = 'smart'
endif
" }}}

" g:ctrlsf_confirm_save {{{2
if !exists('g:ctrlsf_confirm_save')
    let g:ctrlsf_confirm_save = 1
endif
" }}}

" g:ctrlsf_confirm_unsaving_quit {{{2
if !exists('g:ctrlsf_confirm_unsaving_quit')
    let g:ctrlsf_confirm_unsaving_quit = 1
endif
" }}}

" g:ctrlsf_context {{{2
if !exists('g:ctrlsf_context')
    let g:ctrlsf_context = '-C 3'
endif
" }}}

" g:ctrlsf_debug_mode {{{2
if !exists('g:ctrlsf_debug_mode')
    let g:ctrlsf_debug_mode = 0
endif
" }}}

" g:ctrlsf_default_root {{{2
if !exists('g:ctrlsf_default_root')
    let g:ctrlsf_default_root = 'cwd'
endif
" }}}

" g:ctrlsf_default_view_mode {{{2
if !exists('g:ctrlsf_default_view_mode')
    let g:ctrlsf_default_view_mode = 'normal'
endif
" }}}

" g:ctrlsf_extra_backend_args {{{2
if !exists('g:ctrlsf_extra_backend_args')
    let g:ctrlsf_extra_backend_args = {}
endif
" }}}

" g:ctrlsf_extra_root_markers {{{2
if !exists('g:ctrlsf_extra_root_markers')
    let g:ctrlsf_extra_root_markers = []
endif
" }}}

" g:ctrlsf_follow_symlinks {{{2
if !exists('g:ctrlsf_follow_symlinks')
    let g:ctrlsf_follow_symlinks = 1
endif
" }}}

" g:ctrlsf_ignore_dir {{{2
if !exists('g:ctrlsf_ignore_dir')
    let g:ctrlsf_ignore_dir = []
endif
" }}}

" g:ctrlsf_indent {{{2
if !exists('g:ctrlsf_indent')
    let g:ctrlsf_indent = 4
endif
" }}}

" g:ctrlsf_mapping {{{
let s:default_mapping = {
    \ "open"    : ["<CR>", "o", "<2-LeftMouse>"],
    \ "openb"   : "O",
    \ "split"   : "<C-O>",
    \ "vsplit"  : "",
    \ "tab"     : "t",
    \ "tabb"    : "T",
    \ "popen"   : "p",
    \ "popenf"  : "P",
    \ "quit"    : "q",
    \ "stop"    : "<C-C>",
    \ "next"    : "<C-J>",
    \ "prev"    : "<C-K>",
    \ "chgmode" : "M",
    \ "pquit"   : "q",
    \ "loclist" : "",
    \ }

if !exists('g:ctrlsf_mapping')
    let g:ctrlsf_mapping = s:default_mapping
else
    for key in keys(s:default_mapping)
        let g:ctrlsf_mapping[key] = get(g:ctrlsf_mapping, key,
            \ s:default_mapping[key])
    endfo
endif
" }}}

" g:ctrlsf_parse_speed {{{
if !exists('g:ctrlsf_parse_speed')
    let g:ctrlsf_parse_speed = 300
endif
" }}}

" g:ctrlsf_populate_qflist {{{
if !exists('g:ctrlsf_populate_qflist')
    let g:ctrlsf_populate_qflist = 0
endif
" }}}

" g:ctrlsf_position {{{2
if !exists('g:ctrlsf_position')
    " [left], right, top, bottom
    if exists('g:ctrlsf_open_left')
        if g:ctrlsf_open_left
            let g:ctrlsf_position = 'left'
        else
            let g:ctrlsf_position = 'right'
        endif
    else
        let g:ctrlsf_position = 'left'
    endif
endif
" }}}

" g:ctrlsf_regex_pattern {{{2
if !exists('g:ctrlsf_regex_pattern')
    let g:ctrlsf_regex_pattern = 0
endif
" }}}

" g:ctrlsf_selected_line_hl {{{2
if !exists('g:ctrlsf_selected_line_hl')
    let g:ctrlsf_selected_line_hl = 'p'
endif
" }}}

" g:ctrlsf_search_mode {{{2
if !exists('g:ctrlsf_search_mode')
    if !has('nvim') && (v:version < 800 || (v:version == 800 && !has('patch1039')))
        let g:ctrlsf_search_mode = 'sync'
    else
        let g:ctrlsf_search_mode = 'async'
    endif
endif
" }}}

" g:ctrlsf_toggle_map_key {{{2
if !exists('g:ctrlsf_toggle_map_key')
    let g:ctrlsf_toggle_map_key = ''
endif
" }}}

" g:ctrlsf_winsize {{{2
if !exists('g:ctrlsf_winsize')
    if exists('g:ctrlsf_width')
        let g:ctrlsf_winsize = g:ctrlsf_width
    endif
    let g:ctrlsf_winsize = 'auto'
endif
" }}}
" }}}

" Commands {{{1
com! -n=* -comp=customlist,ctrlsf#comp#Completion CtrlSF         call ctrlsf#Search(<q-args>)
com! -n=* -comp=customlist,ctrlsf#comp#Completion CtrlSFQuickfix call ctrlsf#Quickfix(<q-args>)
com! -n=0                                         CtrlSFOpen     call ctrlsf#Open()
com! -n=0                                         CtrlSFUpdate   call ctrlsf#Update()
com! -n=0                                         CtrlSFClose    call ctrlsf#Quit()
com! -n=0                                         CtrlSFClearHL  call ctrlsf#ClearSelectedLine()
com! -n=0                                         CtrlSFToggle   call ctrlsf#Toggle()
com! -n=0                                         CtrlSFStop     call ctrlsf#StopSearch()
com! -n=0                                         CtrlSFFocus    call ctrlsf#Focus()
" }}}

" Maps {{{1
nnoremap                 <Plug>CtrlSFPrompt     :CtrlSF<Space>
nnoremap          <expr> <Plug>CtrlSFCwordPath  <SID>SearchCwordCmd('CtrlSF', 0, 0)
nnoremap <silent> <expr> <Plug>CtrlSFCwordExec  <SID>SearchCwordCmd('CtrlSF', 0, 1)
nnoremap          <expr> <Plug>CtrlSFCCwordPath <SID>SearchCwordCmd('CtrlSF', 1, 0)
nnoremap <silent> <expr> <Plug>CtrlSFCCwordExec <SID>SearchCwordCmd('CtrlSF', 1, 1)
vnoremap          <expr> <Plug>CtrlSFVwordPath  <SID>SearchVwordCmd('CtrlSF', 0)
vnoremap <silent> <expr> <Plug>CtrlSFVwordExec  <SID>SearchVwordCmd('CtrlSF', 1)
nnoremap          <expr> <Plug>CtrlSFPwordPath  <SID>SearchPwordCmd('CtrlSF', 0)
nnoremap <silent> <expr> <Plug>CtrlSFPwordExec  <SID>SearchPwordCmd('CtrlSF', 1)

nnoremap                 <Plug>CtrlSFQuickfixPrompt     :CtrlSFQuickfix<Space>
nnoremap          <expr> <Plug>CtrlSFQuickfixCwordPath  <SID>SearchCwordCmd('CtrlSFQuickfix', 0, 0)
nnoremap <silent> <expr> <Plug>CtrlSFQuickfixCwordExec  <SID>SearchCwordCmd('CtrlSFQuickfix', 0, 1)
nnoremap          <expr> <Plug>CtrlSFQuickfixCCwordPath <SID>SearchCwordCmd('CtrlSFQuickfix', 1, 0)
nnoremap <silent> <expr> <Plug>CtrlSFQuickfixCCwordExec <SID>SearchCwordCmd('CtrlSFQuickfix', 1, 1)
vnoremap          <expr> <Plug>CtrlSFQuickfixVwordPath  <SID>SearchVwordCmd('CtrlSFQuickfix', 0)
vnoremap <silent> <expr> <Plug>CtrlSFQuickfixVwordExec  <SID>SearchVwordCmd('CtrlSFQuickfix', 1)
nnoremap          <expr> <Plug>CtrlSFQuickfixPwordPath  <SID>SearchPwordCmd('CtrlSFQuickfix', 0)
nnoremap <silent> <expr> <Plug>CtrlSFQuickfixPwordExec  <SID>SearchPwordCmd('CtrlSFQuickfix', 1)
" }}}

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
