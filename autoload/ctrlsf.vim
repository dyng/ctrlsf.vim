" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.10
" ============================================================================

"""""""""""""""""""""""""""""""""
" Main
"""""""""""""""""""""""""""""""""

" remember what user is searching
let s:current_query = ''

" s:ExecSearch()
"
" Basic process: query, parse, render and display.
"
func! s:ExecSearch(args) abort
    try
        call ctrlsf#opt#ParseOptions(a:args)
    catch /ParseOptionsException/
        return -1
    endtry

    if ctrlsf#backend#SelfCheck() < 0
        return -1
    endif

    let [success, output] = ctrlsf#backend#Run(a:args)
    if !success
        call ctrlsf#log#Error('Failed to call backend. Error messages: %s',
            \ output)
        return -1
    endif

    call ctrlsf#db#ParseAckprgResult(output)
    call ctrlsf#win#OpenMainWindow()
    call ctrlsf#win#Draw()
    call ctrlsf#buf#ClearUndoHistory()
    call cursor(1, 1)
endf

" Search()
"
func! ctrlsf#Search(args) abort
    let args = a:args

    " If no pattern is given, use word under the cursor
    if empty(args)
        let args = expand('<cword>')
    endif

    let s:current_query = args

    call s:ExecSearch(s:current_query)
endf

" Update()
"
func! ctrlsf#Update() abort
    if empty(s:current_query)
        return -1
    endif
    call s:ExecSearch(s:current_query)
endf

" Open()
"
func! ctrlsf#Open() abort
    call ctrlsf#win#OpenMainWindow()
endf

" Redraw()
"
func! ctrlsf#Redraw() abort
    let [wlnum, lnum, col] = [line('w0'), line('.'), col('.')]
    call ctrlsf#win#Draw()
    call ctrlsf#win#MoveCursor(wlnum, lnum, col)
endf

" Save()
"
func! ctrlsf#Save()
    if !&l:modified
        return
    endif

    let changed  = ctrlsf#edit#Save()

    if changed > 0
        " DO NOT redraw if it is an undo (then seq_last != seq_cur)
        let undotree = undotree()
        if undotree.seq_last == undotree.seq_cur
            call ctrlsf#Redraw()
        endif

        " reset 'modified' flag
        setl nomodified

        " reload modified files
        checktime
    endif
endf

" Quit()
"
func! ctrlsf#Quit() abort
    call ctrlsf#preview#ClosePreviewWindow()
    call ctrlsf#win#CloseMainWindow()
endf

" Toggle()
"
func! ctrlsf#Toggle() abort
    if ctrlsf#win#FindMainWindow() != -1
        call ctrlsf#Quit()
    else
        call ctrlsf#Open()
    endif
endf

" JumpTo()
"
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

" s:NextMatch()
"
func! ctrlsf#NextMatch(forward) abort
    let cur_vlnum     = line('.')
    let [vlnum, vcol] = ctrlsf#view#FindNextMatch(cur_vlnum, a:forward)

    if vlnum > 0
        if a:forward && vlnum <= cur_vlnum
            redraw!
            call ctrlsf#log#Notice("search hit BOTTOM, continuing at TOP")
        elseif !a:forward && vlnum >= cur_vlnum
            redraw!
            call ctrlsf#log#Notice("search hit TOP, continuing at BOTTOM")
        else
            call ctrlsf#log#Clear()
        endif

        call cursor(vlnum, vcol)
    endif
endf

" OpenFileInWindow()
"
" OpenFileInWindow() has 2 modes:
"
" 1. Open file in a window (usually the window where CtrlSF was launched), then
" close CtrlSF window depending on the value of 'g:ctrlsf_auto_close'.
"
" 2. Open file in a window like mode 1, but don't close CtrlSF no matter what
" 'g:ctrlsf_auto_close' is.
"
func! s:OpenFileInWindow(file, lnum, col, mode) abort
    if a:mode == 1 && g:ctrlsf_auto_close
        call ctrlsf#Quit()
    endif

    let target_winnr = ctrlsf#win#FindTargetWindow(a:file)
    if target_winnr == 0
        exec 'silent split ' . a:file
    else
        exec target_winnr . 'wincmd w'

        if bufname('%') !~# a:file
            if &modified && !&hidden
                exec 'silent split ' . a:file
            else
                exec 'silent edit ' . a:file
            endif
        endif
    endif

    call ctrlsf#win#MoveCentralCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call ctrlsf#hl#HighlightSelectedLine()
    endif
endf

" OpenFileInTab()
" OpenFileInTab() has 2 modes:
"
" 1. Open file in a new tab, close or leave CtrlSF window depending on value
" of 'g:ctrlsf_auto_close', and place cursor in the new tab.
"
" 2. Open file in a new tab like mode 1, but focus CtrlSF window instead,
" and never close CtrlSF window.
"
func! s:OpenFileInTab(file, lnum, col, mode) abort
    if a:mode == 1 && g:ctrlsf_auto_close
        call ctrlsf#Quit()
    endif

    exec 'silen tabedit ' . a:file

    call ctrlsf#win#MoveCentralCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call ctrlsf#hl#HighlightSelectedLine()
    endif

    if a:mode == 2
        tabprevious
    endif
endf

" s:PreviewFile()
"
func! s:PreviewFile(file, lnum, col) abort
    call ctrlsf#preview#OpenPreviewWindow()

    if !exists('b:ctrlsf_file') || b:ctrlsf_file !=# a:file
        let b:ctrlsf_file = a:file

        call ctrlsf#buf#WriteFile(a:file)

        " trigger filetypedetect (syntax highlight)
        exec 'doau filetypedetect BufRead ' . a:file
    endif

    call ctrlsf#win#MoveCentralCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'p'
        call ctrlsf#hl#HighlightSelectedLine()
    endif

    call ctrlsf#win#FocusMainWindow()
endf

" ClearSelectedLine()
"
func! ctrlsf#ClearSelectedLine() abort
    call ctrlsf#hl#ClearSelectedLine()
endf
