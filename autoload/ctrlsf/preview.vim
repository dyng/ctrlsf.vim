" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.6.0
" ============================================================================

" preview buffer's name
let s:PREVIEW_BUF_NAME = "__CtrlSFPreview__"

" OpenPreviewWindow()
"
func! ctrlsf#preview#OpenPreviewWindow() abort
    " try to focus an existing preview window
    if ctrlsf#preview#FocusPreviewWindow() != -1
        return
    endif

    " backup width/height of other windows
    " be sure doing this only when *opening new window*
    call ctrlsf#win#BackupAllWinSize()

    let vmode = ctrlsf#CurrentMode()

    if vmode ==# 'normal'
        " normal mode
        if g:ctrlsf_preview_position == 'inside'
            if g:ctrlsf_position == "left" || g:ctrlsf_position == "right" ||
             \ g:ctrlsf_position == 'left_local' || g:ctrlsf_position == 'right_local'
                let winsize = winheight(0) / 2
            else
                let winsize = winwidth(0) / 2
            endif

            let openpos = {
                    \ 'bottom': 'rightbelow vertical',
                    \ 'right' : 'rightbelow',
                    \ 'right_local' : 'rightbelow',
                    \ 'top'   : 'rightbelow vertical',
                    \ 'left' : 'rightbelow',
                    \ 'left_local' : 'rightbelow'}
                    \[g:ctrlsf_position] . ' '
        else
            if g:ctrlsf_position == "left" || g:ctrlsf_position == "right" ||
             \ g:ctrlsf_position == 'left_local' || g:ctrlsf_position == 'right_local'
                let ctrlsf_width  = winwidth(0)
                let winsize = min([&columns-ctrlsf_width, ctrlsf_width])
            else
                let ctrlsf_height  = winheight(0)
                let winsize = min([&lines-ctrlsf_height, ctrlsf_height])
            endif

            let openpos = {
                    \ 'bottom'      : 'leftabove',
                    \ 'right'       : 'leftabove vertical',
                    \ 'right_local' : 'leftabove vertical',
                    \ 'top'         : 'rightbelow',
                    \ 'left'        : 'rightbelow vertical',
                    \ 'left_local'  : 'rightbelow vertical'}
                    \[g:ctrlsf_position] . ' '
        endif
    else
        " compact mode
        let winsize = &lines - winheight(0) - 10
        let openpos = 'leftabove'
    endif

    " open window
    exec 'silent keepalt ' . openpos . winsize . 'split ' . '__CtrlSFPreview__'

    call s:InitPreviewWindow()
endf

" ClosePreviewWindow()
"
func! ctrlsf#preview#ClosePreviewWindow() abort
    if ctrlsf#preview#FocusPreviewWindow() == -1
        return
    endif

    close

    " restore width/height of other windows
    call ctrlsf#win#RestoreAllWinSize()

    call ctrlsf#win#FocusMainWindow()
endf

" InitPreviewWindow()
func! s:InitPreviewWindow() abort
    setl buftype=nofile
    setl bufhidden=unload
    setl noswapfile
    setl nobuflisted
    setl nomodifiable
    setl winfixwidth
    setl winfixheight

    let act_func_ref = {
        \ "pquit": "ctrlsf#preview#ClosePreviewWindow()"
        \ }
    call ctrlsf#utils#Nmap(g:ctrlsf_mapping, act_func_ref)

    augroup ctrlsfp
        au!
        au BufUnload <buffer> call setbufvar(s:PREVIEW_BUF_NAME, "ctrlsf_file", "")
    augroup END
endf

" FindPreviewWindow()
"
func! ctrlsf#preview#FindPreviewWindow() abort
    return ctrlsf#win#FindWindow(s:PREVIEW_BUF_NAME)
endf

" FocusPreviewWindow()
"
func! ctrlsf#preview#FocusPreviewWindow() abort
    return ctrlsf#win#FocusWindow(s:PREVIEW_BUF_NAME)
endf

