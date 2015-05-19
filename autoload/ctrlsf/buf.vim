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
    call ctrlsf#buf#ClearUndoHistory()
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
    call ctrlsf#buf#ClearUndoHistory()
    call setbufvar('%', '&modifiable', modifiable_bak)
    call setbufvar('%', '&modified', 0)
endf

" CleareUndoHistory()
"
func! ctrlsf#buf#ClearUndoHistory() abort
    let ul_bak = &undolevels
    set undolevels=-1
    exe "normal a \<BS>\<Esc>"
    let &undolevels = ul_bak
    unlet ul_bak
endf
