let s:EDIT_BUF_NAME = '__CtrlSFEdit__'

" OpenEditMode()
"
func! ctrlsf#edit#win#OpenEditMode() abort
    " only open edit mode in CtrlSF window
    if ctrlsf#win#FocusMainWindow() == -1
        return
    endif

    call ctrlsf#win#ClosePreviewWindow()

    call s:SwithEditBuffer()
endf

" QuitEditMode()
"
func! ctrlsf#edit#win#QuitEditMode() abort
    " only open edit mode in CtrlSF window
    if s:FocusEditWindow() == -1
        return
    endif

    call ctrlsf#win#SwitchMainBuffer()
endf

" FocusEditWindow()
"
func! s:FocusEditWindow() abort
    return ctrlsf#win#FocusWindow(s:EDIT_BUF_NAME)
endf

" SwithEditBuffer()
"
func! s:SwithEditBuffer() abort
    exec 'edit! ' . s:EDIT_BUF_NAME
    call s:InitEditWindow()
endf

" InitEditWindow()
func! s:InitEditWindow() abort
    setl filetype=ctrlsfe
    setl noreadonly
    setl buftype=acwrite
    setl bufhidden=unload
    setl noswapfile
    setl nobuflisted
    setl modifiable
    setl nolist
    setl nonumber
    setl nowrap
    setl winfixwidth
    setl textwidth=0
    setl nospell
    setl nofoldenable

    call ctrlsf#hl#HighlightMatch('ctrlsfeMatch')

    com! -n=0 CtrlSFQuitEditMode call ctrlsf#edit#win#QuitEditMode()

    nnoremap Q :CtrlSFQuitEditMode<CR>

    aug ctrlsfEditMode
        au!
        au BufWriteCmd <buffer> call ctrlsf#Save()
    aug END
endf
