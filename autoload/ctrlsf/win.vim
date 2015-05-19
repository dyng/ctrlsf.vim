" ctrlsf buffer's name
let s:MAIN_BUF_NAME = "__CtrlSF__"

" preview buffer's name
let s:PREVIEW_BUF_NAME = "__CtrlSFPreview__"

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

" SwitchMainBuffer()
"
func! ctrlsf#win#SwitchMainBuffer() abort
    exec 'edit! ' . s:MAIN_BUF_NAME
    call s:InitMainWindow()
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

" OpenPreviewWindow()
"
func! ctrlsf#win#OpenPreviewWindow() abort
    " try to focus an existing preview window
    if (ctrlsf#win#FocusPreviewWindow() != -1)
        return
    endif

    if g:ctrlsf_position == "left" || g:ctrlsf_position == "right"
        let ctrlsf_width  = winwidth(0)
        let winsize = min([&columns-ctrlsf_width, ctrlsf_width])
    else
        let ctrlsf_height  = winheight(0)
        let winsize = min([&lines-ctrlsf_height, ctrlsf_height])
    endif

    let openpos = {
            \ 'bottom': 'leftabove',  'right' : 'leftabove vertical',
            \ 'top'   : 'rightbelow',  'left' : 'rightbelow vertical'}
            \[g:ctrlsf_position] . ' '
    exec 'silent keepalt ' . openpos . winsize . 'split ' . '__CtrlSFPreview__'

    call s:InitPreviewWindow()
endf

" ClosePreviewWindow()
"
func! ctrlsf#win#ClosePreviewWindow() abort
    if ctrlsf#win#FocusPreviewWindow() == -1
        return
    endif

    close

    call ctrlsf#win#FocusMainWindow()
endf

" InitMainWindow()
func! s:InitMainWindow() abort
    setl filetype=ctrlsf
    setl noreadonly
    setl buftype=nofile
    setl bufhidden=hide
    setl noswapfile
    setl nobuflisted
    setl nomodifiable
    setl nolist
    setl nonumber
    setl nowrap
    setl winfixwidth
    setl textwidth=0
    setl nospell
    setl nofoldenable

    call ctrlsf#hl#HighlightMatch('ctrlsfMatch')

    nnoremap <silent><buffer> <CR>  :call ctrlsf#JumpTo('o')<CR>
    nnoremap <silent><buffer> o     :call ctrlsf#JumpTo('o')<CR>
    nnoremap <silent><buffer> O     :call ctrlsf#JumpTo('O')<CR>
    nnoremap <silent><buffer> t     :call ctrlsf#JumpTo('t')<CR>
    nnoremap <silent><buffer> T     :call ctrlsf#JumpTo('T')<CR>
    nnoremap <silent><buffer> p     :call ctrlsf#JumpTo('p')<CR>
    nnoremap <silent><buffer> <C-J> :call ctrlsf#NextMatch(1)<CR>
    nnoremap <silent><buffer> <C-K> :call ctrlsf#NextMatch(0)<CR>
    nnoremap <silent><buffer> E     :call ctrlsf#OpenEditMode()<CR>
    nnoremap <silent><buffer> q     :call ctrlsf#Quit()<CR>
endf

" InitPreviewWindow()
func! s:InitPreviewWindow() abort
    setl buftype=nofile
    setl bufhidden=hide
    setl noswapfile
    setl nobuflisted
    setl nomodifiable
    setl winfixwidth

    nnoremap <silent><buffer> q :call ctrlsf#win#ClosePreviewWindow()<CR>
endf


"""""""""""""""""""""""""""""""""
" Find
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

" FindPreviewWindow()
"
func! ctrlsf#win#FindPreviewWindow() abort
    return ctrlsf#win#FindWindow(s:PREVIEW_BUF_NAME)
endf

" FocusPreviewWindow()
"
func! ctrlsf#win#FocusPreviewWindow() abort
    return ctrlsf#win#FocusWindow(s:PREVIEW_BUF_NAME)
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

    let preview_winnr = ctrlsf#win#FindPreviewWindow()
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
