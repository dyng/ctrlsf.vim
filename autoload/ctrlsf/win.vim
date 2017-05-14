" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.9.0
" ============================================================================

" ctrlsf buffer's name
let s:MAIN_BUF_NAME = "__CtrlSF__"

" window which brings up ctrlsf window
let s:caller_win = {
    \ 'bufnr' : -1,
    \ 'winnr' : -1,
    \ }

"""""""""""""""""""""""""""""""""
" Open & Close
"""""""""""""""""""""""""""""""""

" OpenMainWindow()
"
func! ctrlsf#win#OpenMainWindow() abort
    " backup current bufnr and winnr
    let s:caller_win = {
        \ 'bufnr' : bufnr('%'),
        \ 'winnr' : winnr(),
        \ }

    " try to focus an existing ctrlsf window, initialize a new one if failed
    if ctrlsf#win#FocusMainWindow() != -1
        return
    endif

    " backup width/height of other windows
    " be sure doing this only when *opening new window*
    call ctrlsf#win#BackupAllWinSize()

    let vmode = ctrlsf#CurrentMode()

    if vmode ==# 'normal'
        " normal mode
        if g:ctrlsf_winsize =~ '\d\{1,2}%'
            if g:ctrlsf_position == "left" || g:ctrlsf_position == "right"
                let winsize = &columns * str2nr(g:ctrlsf_winsize) / 100
            else
                let winsize = &lines * str2nr(g:ctrlsf_winsize) / 100
            endif
        elseif g:ctrlsf_winsize =~ '\d\+'
            let winsize = str2nr(g:ctrlsf_winsize)
        else
            if g:ctrlsf_position == "left" || g:ctrlsf_position == "right"
                let winsize = &columns / 2
            else
                let winsize = &lines / 2
            endif
        endif

        let openpos = {
              \ 'top'    : 'topleft',  'left'  : 'topleft vertical',
              \ 'bottom' : 'botright', 'right' : 'botright vertical'}
              \[g:ctrlsf_position] . ' '
    else
        " compact mode: fixed window size and position
        let winsize = 10
        let openpos = 'botright'
    endif


    " open window
    exec 'silent keepalt ' . openpos . winsize . 'split ' .
                \ (bufnr('__CtrlSF__') != -1 ? '+b'.bufnr('__CtrlSF__') : '__CtrlSF__')

    call s:InitMainWindow()

    " set 'modifiable' flag depending on current view mode
    if ctrlsf#CurrentMode() ==# 'normal'
        setl modifiable
    else
        setl nomodifiable
    endif

    " resize other windows
    call s:ResizeNeighborWins()
endf

" Draw()
"
func! ctrlsf#win#Draw() abort
    let content = ctrlsf#view#Render()
    silent! undojoin | keepjumps call ctrlsf#buf#WriteString(content)
endf

" CloseMainWindow()
"
func! ctrlsf#win#CloseMainWindow() abort
    if ctrlsf#win#FocusMainWindow() == -1
        return
    endif

    " Surely we are in CtrlSF window
    try
      close

      " restore width/height of other windows
      call ctrlsf#win#RestoreAllWinSize()

      call ctrlsf#win#FocusCallerWindow()
    catch /^Vim\%((\a\+)\)\=:E444/
      " This is the last window, simply delete the buffer
      bdelete
    endtry
endf

" ResizeNeighborWins()
"
func! s:ResizeNeighborWins() abort
    setl winfixwidth
    setl winfixheight
    wincmd =
endf

" InitMainWindow()
func! s:InitMainWindow() abort
    if exists("b:ctrlsf_initialized")
        return
    endif

    " option
    setl filetype=ctrlsf
    setl fileformat=unix
    setl fileencoding=utf-8
    setl iskeyword=@,48-57,_
    setl noreadonly
    setl buftype=acwrite
    setl bufhidden=hide
    setl noswapfile
    setl nobuflisted
    setl nolist
    setl nonumber
    setl nowrap
    setl winfixwidth
    setl winfixheight
    setl textwidth=0
    setl nospell
    setl nofoldenable

    " map
    call ctrlsf#buf#ToggleMap(1)

    if !empty(g:ctrlsf_toggle_map_key)
        exec 'nnoremap <silent><buffer> ' . g:ctrlsf_toggle_map_key
            \ ' :CtrlSFToggleMap<CR>'
    endif

    " cmd
    command! -buffer CtrlSFToggleMap      call ctrlsf#ToggleMap()
    command! -buffer CtrlSFSwitchViewMode call ctrlsf#SwitchViewMode()

    " autocmd
    augroup ctrlsf
        au!
        au BufWriteCmd         <buffer> call ctrlsf#Save()
        au BufHidden,BufUnload <buffer> call ctrlsf#buf#UndoAllChanges()
    augroup END

    " hook for user customization
    if exists("*g:CtrlSFAfterMainWindowInit")
        silent! call g:CtrlSFAfterMainWindowInit()
    end

    let b:ctrlsf_initialized = 1
endf

"""""""""""""""""""""""""""""""""
" Window Navigation
"""""""""""""""""""""""""""""""""

" FindWindow()
"
func! ctrlsf#win#FindWindow(buf_name) abort
    return bufwinnr(a:buf_name)
endf

" FocusWindow()
"
" Parameters
" {exp} buffer name OR window number
"
func! ctrlsf#win#FocusWindow(exp) abort
    if type(a:exp) == 0
        let winnr = a:exp
    else
        let winnr = ctrlsf#win#FindWindow(a:exp)
    endif

    if winnr < 0
        return -1
    endif

    exec winnr . 'wincmd w'
    return winnr
endf

" FindMainWindow()
"
func! ctrlsf#win#FindMainWindow() abort
    return ctrlsf#win#FindWindow(s:MAIN_BUF_NAME)
endf

" FocusMainWindow()
"
func! ctrlsf#win#FocusMainWindow() abort
    return ctrlsf#win#FocusWindow(s:MAIN_BUF_NAME)
endf

" FindCallerWindow()
"
func! ctrlsf#win#FindCallerWindow() abort
    let ctrlsf_winnr = ctrlsf#win#FindMainWindow()
    if ctrlsf_winnr > 0 && ctrlsf_winnr <= s:caller_win.winnr
        return s:caller_win.winnr + 1
    else
        return s:caller_win.winnr
    endif
endf

" FocusCallerWindow()
"
func! ctrlsf#win#FocusCallerWindow() abort
    let caller_winnr = ctrlsf#win#FindCallerWindow()
    if ctrlsf#win#FocusWindow(caller_winnr) == -1
        wincmd p
    endif
endf

" FindTargetWindow()
"
func! ctrlsf#win#FindTargetWindow(file) abort
    let target_winnr = bufwinnr(a:file)

    " case: there is a window containing the target file
    if target_winnr > 0
        return target_winnr
    endif

    " case: previous window where ctrlsf was triggered
    let target_winnr = s:caller_win.winnr

    let ctrlsf_winnr = ctrlsf#win#FindMainWindow()
    if ctrlsf_winnr > 0 && ctrlsf_winnr <= target_winnr
        let target_winnr += 1
    endif

    let preview_winnr = ctrlsf#preview#FindPreviewWindow()
    if preview_winnr > 0 && preview_winnr <= target_winnr
        let target_winnr += 1
    endif

    if winbufnr(target_winnr) == s:caller_win.bufnr
        \ && empty(getwinvar(target_winnr, '&buftype'))
        return target_winnr
    endif

    " case: pick up the first window containing regular file
    let nr = 1
    while nr <= winnr('$')
        if empty(getwinvar(nr, '&buftype'))
            return nr
        endif
        let nr += 1
    endwh

    " case: can't find any valid window, tell front to open a new window
    return 0
endf

"""""""""""""""""""""""""""""""""
" Cursor
"""""""""""""""""""""""""""""""""
" MoveCursor()
"
" Redraw, let {wlnum} be the top of window and place cursor at {lnum}, {col}.
"
" {wlnum} number of the top line in window
" {lnum}  line number of cursor
" {col}   column number of cursor
"
func! ctrlsf#win#MoveCursor(wlnum, lnum, col) abort
    " Move cursor to specific position, and window stops at {wlnum} line
    exec 'keepjumps normal ' . a:wlnum . "z\r"
    call cursor(a:lnum, a:col)

    " Open fold
    normal zv
endf

" MoveCursorCentral()
"
func! ctrlsf#win#MoveCursorCentral(lnum, col) abort
    " Move cursor to specific position
    exec 'keepjumps normal ' . a:lnum . ' z.'
    call cursor(a:lnum, a:col)

    " Open fold
    normal zv
endf

" MoveCursorCurrentLineMatch()
"
" This method is used to work around a weird behavior of vim.
" If user reopens ctrlsf window, cursor is in the same line when window
" exitting, but this is not true for column, which is always in column 1
"
func! ctrlsf#win#MoveCursorCurrentLineMatch() abort
    let cur_vlnum = line('.')
    let [vlnum, vcol] = ctrlsf#view#FindNextMatch(1, 0)
    if cur_vlnum == vlnum
        call cursor(vlnum, vcol)
    endif
endf

"""""""""""""""""""""""""""""""""
" Backup & Restore Window Size
"""""""""""""""""""""""""""""""""
" BackupAllWinSize()
"
" Purpose of BackupAllWinSize() and RestoreAllWinSize() is to restore
" width/height of fixed sized windows such like NERDTree's. As a result, we only
" backup width/height of fixed window's to keep least side effects.
"
func! ctrlsf#win#BackupAllWinSize()
    let nr = 1
    while winbufnr(nr) != -1
        if getwinvar(nr, '&winfixwidth') || getwinvar(nr, '&winfixheight')
            if type(getwinvar(nr, 'ctrlsf_winwidth_bak')) != 3
                call setwinvar(nr, 'ctrlsf_winwidth_bak', [])
            endif
            call add(getwinvar(nr, 'ctrlsf_winwidth_bak'), winwidth(nr))

            if type(getwinvar(nr, 'ctrlsf_winheight_bak')) != 3
                call setwinvar(nr, 'ctrlsf_winheight_bak', [])
            endif
            call add(getwinvar(nr, 'ctrlsf_winheight_bak'), winheight(nr))
        endif
        let nr += 1
    endwh
endf

" RestoreAllWinSize()
"
func! ctrlsf#win#RestoreAllWinSize()
    let nr = 1
    while winbufnr(nr) != -1
        if getwinvar(nr, '&winfixwidth') || getwinvar(nr, '&winfixheight')
            exec nr . 'wincmd w'

            let width_stack = getwinvar(nr, 'ctrlsf_winwidth_bak')
            if type(width_stack) == 3 && !empty(width_stack)
                exec "vertical resize " . remove(width_stack, -1)
            endif

            let height_stack = getwinvar(nr, 'ctrlsf_winheight_bak')
            if type(height_stack) == 3 && !empty(height_stack)
                exec "resize " . remove(height_stack, -1)
            endif
        endif
        let nr += 1
    endwh
endf
