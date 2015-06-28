" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.10
" ============================================================================

" WriteString()
"
" Write {content} to current buffer.
"
func! ctrlsf#buf#WriteString(content) abort
    let modifiable_bak = getbufvar('%', '&modifiable')
    setl modifiable
    silent %delete _
    silent 0put =a:content
    silent $delete _ " delete trailing empty line
    call setbufvar('%', '&modifiable', modifiable_bak)
    call setbufvar('%', '&modified', 0)
endf

" WriteFile()
"
" Write (or read?) {file} to current buffer.
"
func! ctrlsf#buf#WriteFile(file) abort
    let modifiable_bak = getbufvar('%', '&modifiable')
    setl modifiable
    silent %delete _
    exec 'silent 0read ' . a:file
    silent $delete _ " delete trailing empty line
    call setbufvar('%', '&modifiable', modifiable_bak)
    call setbufvar('%', '&modified', 0)
endf

" ClearUndoHistory()
"
func! ctrlsf#buf#ClearUndoHistory() abort
    let modified_bak = getbufvar('%', '&modified')
    let ul_bak = &undolevels
    set undolevels=-1
    exe "normal a \<BS>\<Esc>"
    let &undolevels = ul_bak
    unlet ul_bak
    call setbufvar('%', '&modified', modified_bak)
endf

" UndoAllChanges()
"
func! ctrlsf#buf#UndoAllChanges() abort
    if &modified
        earlier 1f
    endif
endf

