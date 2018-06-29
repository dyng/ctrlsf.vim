" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
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
    else
        " compact mode
        let winsize = &lines - 20
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

