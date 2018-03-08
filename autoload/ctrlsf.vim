" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.9.0
" ============================================================================

"""""""""""""""""""""""""""""""""
" Main
"""""""""""""""""""""""""""""""""

" remember what user is searching
let s:current_mode = ''
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

    " Print error messages from backend (Debug Mode)
    call ctrlsf#log#Debug("Errors reported by backend:\n%s",
                \ ctrlsf#backend#LastErrors())

    " Parsing
    call ctrlsf#db#ParseAckprgResult(output)

    " Open and draw contents
    call s:OpenAndDraw()

    " populate quickfix and location list
    if g:ctrlsf_populate_qflist
        call setqflist(ctrlsf#db#MatchListQF())
    endif
    call setloclist(0, ctrlsf#db#MatchListQF())
endf

" Search()
"
func! ctrlsf#Search(args, ...) abort
    let args = a:args

    " If no pattern is given, use word under the cursor
    if empty(args)
        let args = expand('<cword>')
    endif

    let s:current_query = args

    " if view mode is not specified, use 'g:ctrlsf_default_view_mode'
    let s:current_mode  = empty(a:000) ?
                \ g:ctrlsf_default_view_mode :
                \ a:1

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
    call ctrlsf#hl#HighlightMatch()
    call ctrlsf#win#MoveCursorCurrentLineMatch()
endf

" Redraw()
"
func! ctrlsf#Redraw() abort
    let [wlnum, lnum, col] = [line('w0'), line('.'), col('.')]
    call ctrlsf#win#Draw()
    call ctrlsf#win#MoveCursor(wlnum, lnum, col)
endf

" SwitchViewMode()
"
func! ctrlsf#SwitchViewMode() abort
    let next = ctrlsf#CurrentMode() ==# 'normal' ? 'compact' : 'normal'

    " set current view mode
    let s:current_mode = next

    call ctrlsf#Quit()
    call s:OpenAndDraw()
endf

" Quickfix()
"
" This is DEPRECATED method which is used only for backward-compatible
"
func! ctrlsf#Quickfix(args) abort
    call ctrlsf#log#Notice("CtrlSFQuickfix is DEPRECATED! Invoking CtrlSF's compact view instead.")
    sleep 1
    call ctrlsf#Search(a:args, 'compact')
endf

" Save()
"
func! ctrlsf#Save()
    if ctrlsf#CurrentMode() !=# 'normal'
        ctrlsf#log#Notice("Edit mode is disabled in compact view.")
    endif

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
    if g:ctrlsf_confirm_unsaving_quit &&
                \ !ctrlsf#buf#WarnIfChanged()
        return
    endif

    call s:Quit()
endf

" OpenLocList()
"
func! ctrlsf#OpenLocList() abort
    lopen
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

" ClearSelectedLine()
"
func! ctrlsf#ClearSelectedLine() abort
    call ctrlsf#hl#ClearSelectedLine()
endf

" ToggleMap()
"
func! ctrlsf#ToggleMap() abort
    call ctrlsf#buf#ToggleMap()

    if b:ctrlsf_map_enabled
        echo "Maps enabled."
    else
        echo "Maps disabled."
    endif
endf

" JumpTo()
"
func! ctrlsf#JumpTo(mode) abort
    let [file, line, match] = ctrlsf#view#Locate(line('.'))

    if empty(file) || empty(line)
        return
    endif

    if (a:mode ==# "open"
                \ || a:mode ==# "split"
                \ || a:mode ==# "vsplit"
                \ || a:mode ==# "tab") &&
                \ g:ctrlsf_confirm_unsaving_quit &&
                \ !ctrlsf#buf#WarnIfChanged()
        return
    endif

    let lnum = line.lnum
    let col  = empty(match)? 0 : match.col

    if a:mode ==# 'open'
        call s:OpenFileInWindow(file, lnum, col, 1, 0)
    elseif a:mode ==# 'open_background'
        call s:OpenFileInWindow(file, lnum, col, 2, 0)
    elseif a:mode ==# 'split'
        call s:OpenFileInWindow(file, lnum, col, 1, 1)
    elseif a:mode ==# 'vsplit'
        call s:OpenFileInWindow(file, lnum, col, 1, 2)
    elseif a:mode ==# 'tab'
        call s:OpenFileInTab(file, lnum, col, 1)
    elseif a:mode ==# 'tab_background'
        call s:OpenFileInTab(file, lnum, col, 2)
    elseif a:mode ==# 'preview'
        call s:PreviewFile(file, lnum, col, 0)
    elseif a:mode ==# 'preview_foreground'
        call s:PreviewFile(file, lnum, col, 1)
    endif
endf

" s:NextMatch()
"
" Move cursor to the next match after current cursor position.
"
func! ctrlsf#NextMatch(forward) abort
    let [_, cur_vlnum, cur_vcol, _] = getpos('.')
    let [vlnum, vcol] = ctrlsf#view#FindNextMatch(a:forward, &wrapscan)

    if vlnum > 0
        if a:forward && (vlnum < cur_vlnum || (vlnum == cur_vlnum && vcol < cur_vcol))
            redraw!
            call ctrlsf#log#Notice("search hit BOTTOM, continuing at TOP")
        elseif !a:forward && (vlnum > cur_vlnum || (vlnum == cur_vlnum && vcol > cur_vcol))
            redraw!
            call ctrlsf#log#Notice("search hit TOP, continuing at BOTTOM")
        else
            call ctrlsf#log#Clear()
        endif

        call cursor(vlnum, vcol)
    endif
endf

" CurrentMode()
"
func! ctrlsf#CurrentMode()
    let vmode = empty(s:current_mode) ? 'normal' : s:current_mode
    call ctrlsf#log#Debug("Current Mode: %s", vmode)
    return vmode
endf

" OpenFileInWindow()
"
" OpenFileInWindow() has 2 modes:
"
" 1. Open file in a window (usually the window where CtrlSF is launched), then
" close CtrlSF window or not, depending on value of 'g:ctrlsf_auto_close'.
"
" 2. Open file in a window like mode 1, but don't close CtrlSF no matter what
" 'g:ctrlsf_auto_close' is.
"
" About split:
"
" '0' means don't split by default unless there exists unsaved changes.
" '1' means split horizontally.
" '2' means split vertically
"
func! s:OpenFileInWindow(file, lnum, col, mode, split) abort
    if a:mode == 1 && g:ctrlsf_auto_close[ctrlsf#CurrentMode()]
        call s:Quit()
    endif

    let target_winnr = ctrlsf#win#FindTargetWindow(a:file)
    if target_winnr == 0
        exec 'silent split ' . fnameescape(a:file)
    else
        exec target_winnr . 'wincmd w'

        if bufname('%') !=# a:file
            if a:split || (&modified && !&hidden)
                if a:split == 2
                    exec 'silent vertical split ' . fnameescape(a:file)
                else
                    exec 'silent split ' . fnameescape(a:file)
                endif
            else
                exec 'silent edit ' . fnameescape(a:file)
            endif
        endif
    endif

    call ctrlsf#win#MoveCursorCentral(a:lnum, a:col)

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
    if a:mode == 1 && g:ctrlsf_auto_close[ctrlsf#CurrentMode()]
        call s:Quit()
    endif

    exec 'silen tabedit ' . fnameescape(a:file)

    call ctrlsf#win#MoveCursorCentral(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call ctrlsf#hl#HighlightSelectedLine()
    endif

    if a:mode == 2
        tabprevious
    endif
endf

" s:PreviewFile()
"
func! s:PreviewFile(file, lnum, col, follow) abort
    call ctrlsf#preview#OpenPreviewWindow()

    if !exists('b:ctrlsf_file') || b:ctrlsf_file !=# a:file
        let b:ctrlsf_file = a:file

        call ctrlsf#buf#WriteFile(a:file)

        " trigger filetypedetect (syntax highlight)
        exec 'doau filetypedetect BufRead ' . fnameescape(a:file)
    endif

    call ctrlsf#win#MoveCursorCentral(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'p'
        call ctrlsf#hl#HighlightSelectedLine()
    endif

    if !a:follow
        call ctrlsf#win#FocusMainWindow()
    endif
endf

" s:OpenAndDraw()
"
func! s:OpenAndDraw() abort
    call ctrlsf#win#OpenMainWindow()
    call ctrlsf#win#Draw()
    call ctrlsf#buf#ClearUndoHistory()
    call ctrlsf#hl#ReloadSyntax()
    call ctrlsf#hl#HighlightMatch()

    " scroll up to top line
    1normal z<CR>
    call ctrlsf#NextMatch(1)
endf

" s:Quit()
"
func! s:Quit() abort
    call ctrlsf#preview#ClosePreviewWindow()
    call ctrlsf#win#CloseMainWindow()
endf
