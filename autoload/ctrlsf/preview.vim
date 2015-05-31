" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

" preview buffer's name
let s:PREVIEW_BUF_NAME = "__CtrlSFPreview__"

" OpenPreviewWindow()
"
func! ctrlsf#preview#OpenPreviewWindow() abort
    " try to focus an existing preview window
    if (ctrlsf#preview#FocusPreviewWindow() != -1)
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
func! ctrlsf#preview#ClosePreviewWindow() abort
    if ctrlsf#preview#FocusPreviewWindow() == -1
        return
    endif

    close

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

    exec "nnoremap <silent><buffer> " . g:ctrlsf_mapping['pquit']
        \ . " :call ctrlsf#preview#ClosePreviewWindow()<CR>"

    augroup ctrlsfp
        au!
        au BufUnload <buffer> unlet b:ctrlsf_file
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

