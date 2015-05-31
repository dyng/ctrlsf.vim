" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
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
    if ctrlsf#win#FocusMainWindow() == -1
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
        exec 'silent keepalt ' . openpos . winsize . 'split ' . '__CtrlSF__'

        call s:InitMainWindow()
    endif

    " resize other windows
    wincmd =
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
    close

    call ctrlsf#win#FocusCallerWindow()
endf

" InitMainWindow()
func! s:InitMainWindow() abort
    setl filetype=ctrlsf
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

    call ctrlsf#hl#HighlightMatch('ctrlsfMatch')

    " map
    let act_func_ref = {
        \ "open"  : "ctrlsf#JumpTo('o')",
        \ "openb" : "ctrlsf#JumpTo('O')",
        \ "tab"   : "ctrlsf#JumpTo('t')",
        \ "tabb"  : "ctrlsf#JumpTo('T')",
        \ "prevw" : "ctrlsf#JumpTo('p')",
        \ "quit"  : "ctrlsf#Quit()",
        \ "next"  : "ctrlsf#NextMatch(1)",
        \ "prev"  : "ctrlsf#NextMatch(0)",
        \ }

    for act in keys(act_func_ref)
        if !empty(g:ctrlsf_mapping[act])
            exec "nnoremap <silent><buffer> " . g:ctrlsf_mapping[act]
                \ . " :call " . act_func_ref[act] . "<CR>"
        endif
    endfo

    " autocmd
    augroup ctrlsf
        au!
        au BufWriteCmd         <buffer> call ctrlsf#Save()
        au BufHidden,BufUnload <buffer> call ctrlsf#buf#UndoAllChanges()
    augroup END
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

" MoveCentralCursor()
"
func! ctrlsf#win#MoveCentralCursor(lnum, col) abort
    " Move cursor to specific position
    exec 'keepjumps normal ' . a:lnum . 'z.'
    call cursor(a:lnum, a:col)

    " Open fold
    normal zv
endf
