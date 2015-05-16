" ============================================================================
" File: autoload/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

" Public Functions {{{1
" ctrlsf#Search() {{{2
func! ctrlsf#Search(args) abort
    call s:Search(a:args)
endf
" }}}

" ctrlsf#OpenWindow() {{{2
func! ctrlsf#OpenWindow() abort
    call ctrlsf#win#OpenWindow()
    call ctrlsf#hl#HighlightMatch()
endf
" }}}

" ctrlsf#CloseWindow() {{{2
func! ctrlsf#CloseWindow() abort
    call ctrlsf#win#CloseWindow()
endf
" }}}

" ctrlsf#ClearSelectedLine() {{{2
func! ctrlsf#ClearSelectedLine() abort
    call s:ClearSelectedLine()
endf
" }}}
" }}}

" Actions {{{1
" s:Search() {{{2
func! s:Search(args) abort
    let args = a:args

    " If no pattern is given, use word under the cursor
    if empty(args)
        let args = expand('<cword>')
    endif

    try
        call ctrlsf#opt#ParseOptions(args)
    catch /ParseOptionsException/
        return -1
    endtry

    if ctrlsf#backend#SelfCheck() < 0
        return -1
    endif

    let command = ctrlsf#backend#BuildCommand(args)

    " A windows user report CtrlSF doesn't work well when 'shelltemp' is
    " turned off. Although I can't reproduce it, I think forcing 'shelltemp'
    " would not do something really bad.
    let stmp_bak = &shelltemp
    set shelltemp
    let ackprg_output = system(command)
    let &shelltemp = stmp_bak

    if v:shell_error && !empty(ackprg_output)
        call ctrlsf#log#Error('Failed to execute command: %s. Output from backend: %s', command, ackprg_output)
        return -1
    endif

    call ctrlsf#db#ParseAckprgResult(ackprg_output)

    call ctrlsf#win#OpenWindow()

    call ctrlsf#hl#HighlightMatch()

    setl modifiable
    silent %delete _
    silent 0put =ctrlsf#view#Render()
    silent $delete _ " delete trailing empty line
    setl nomodifiable
    call cursor(1, 1)
endf
" }}}

" s:JumpTo() {{{2
func! ctrlsf#JumpTo(mode) abort
    let [file, line, match] = ctrlsf#view#Reflect(line('.'))

    if empty(file) || empty(line)
        return
    endif

    let lnum = line.lnum
    let col  = empty(match)? 0 : match.col

    if a:mode ==# 'o'
        call s:OpenFileInWindow(file, lnum, col, 1)
    elseif a:mode ==# 'O'
        call s:OpenFileInWindow(file, lnum, col, 2)
    elseif a:mode ==# 't'
        call s:OpenFileInTab(file, lnum, col, 1)
    elseif a:mode ==# 'T'
        call s:OpenFileInTab(file, lnum, col, 2)
    elseif a:mode ==# 'p'
        call s:PreviewFile(file, lnum, col)
    endif
endf
" }}}

" s:NextMatch() {{{2
func! ctrlsf#NextMatch(forward) abort
    let [vlnum, vcol] = ctrlsf#view#FindNextMatch(line('.'), a:forward)
    call cursor(vlnum, vcol)
endf
" }}}

" s:OpenFileInWindow() {{{2
" s:OpenFileInWindow has 2 modes:
"
" 1. Open file in a window (usually the window where CtrlSF was launched), then
" close CtrlSF window depending on the value of 'g:ctrlsf_auto_close'.
"
" 2. Open file in a window like mode 1, but don't close CtrlSF no matter what
" 'g:ctrlsf_auto_close' is.
"
func! s:OpenFileInWindow(file, lnum, col, mode) abort
    let target_winnr = ctrlsf#win#FindTargetWindow(a:file)

    if a:mode == 1 && g:ctrlsf_auto_close
        let ctrlsf_winnr = ctrlsf#win#FindMainWindow()
        if ctrlsf_winnr <= target_winnr
            let target_winnr -= 1
        endif
        call ctrlsf#win#CloseWindow()
    endif

    if target_winnr == 0
        exec 'silent split ' . a:file
    else
        exec target_winnr . 'wincmd w'

        if bufname('%') !~# a:file
            if &modified
                exec 'silent split ' . a:file
            else
                exec 'edit ' . a:file
            endif
        endif
    endif

    call s:MoveCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call ctrlsf#hl#HighlightSelectedLine()
    endif
endf
" }}}

" s:OpenFileInTab() {{{2
" s:OpenFileInTab has 2 modes:
"
" 1. Open file in a new tab, close or leave CtrlSF window depending on value
" of 'g:ctrlsf_auto_close', and place cursor in the new tab.
"
" 2. Open file in a new tab like mode 1, but focus CtrlSF window instead,
" and never close CtrlSF window.
"
func! s:OpenFileInTab(file, lnum, col, mode) abort
    if a:mode == 1 && g:ctrlsf_auto_close
        call ctrlsf#win#CloseWindow()
    endif

    exec 'tabedit ' . a:file

    call s:MoveCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call ctrlsf#hl#HighlightSelectedLine()
    endif

    if a:mode == 2
        tabprevious
    endif
endf
" }}}

" s:PreviewFile() {{{2
func! s:PreviewFile(file, lnum, col) abort
    if (ctrlsf#win#FocusPreviewWindow() == -1)
        call ctrlsf#win#OpenPreviewWindow()
    endif

    if !exists('b:ctrlsf_file') || b:ctrlsf_file !=# a:file
        setl modifiable
        silent %delete _
        exec 'silent 0read ' . a:file
        setl nomodifiable

        " trigger filetypedetect (syntax highlight)
        exec 'doau filetypedetect BufRead ' . a:file

        let b:ctrlsf_file = a:file
    endif

    call s:MoveCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'p'
        call ctrlsf#hl#HighlightSelectedLine()
    endif

    call ctrlsf#win#FocusMainWindow()
endf
" }}}

" s:MoveCursor() {{{2
func! s:MoveCursor(lnum, col) abort
    " Move cursor to matched line
    exec 'normal ' . a:lnum . 'z.'
    call cursor(a:lnum, a:col)

    " Open fold
    normal zv
endf
" }}}

" s:ClearSelectedLine() {{{2
func! s:ClearSelectedLine() abort
    silent! call matchdelete(b:ctrlsf_highlight_id)
endf
" }}}
" }}}

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
