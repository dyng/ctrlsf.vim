" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
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
    exec 'silent 0read ' . fnameescape(a:file)
    silent $delete _ " delete trailing empty line
    call setbufvar('%', '&modifiable', modifiable_bak)
    call setbufvar('%', '&modified', 0)
endf

" SetLine()
"
" Change content of a line in specified buffer.
"
func! ctrlsf#buf#SetLine(buf_name, lnum, content) abort
    let modifiable_bak = getbufvar(a:buf_name, '&modifiable')
    call setbufvar(a:buf_name, '&modifiable', 1)

    call s:setbufline(a:buf_name, a:lnum, a:content)

    call setbufvar(a:buf_name, '&modifiable', modifiable_bak)
    call setbufvar(a:buf_name, '&modified', 0)
endf

" s:setbufline
"
" Use Vim's setbufline or mimic it with NeoVim's nvim_buf_set_lines.
"
func! s:setbufline(buf_name, lnum, content) abort
    if exists('*setbufline')
        call setbufline(a:buf_name, a:lnum, a:content)
        return
    endif

    " Unlike setbufline, nvim_buf_set_lines can only accept a list
    if type(a:content) == type('')
        let l:content = split(a:content, '\v(\r\n)|\n')
    else
        let l:content = a:content
    endif

    let l:buf_num = bufnr(a:buf_name)

    let l:line_count = nvim_buf_line_count(l:buf_num)
    if a:lnum == 1 + l:line_count
        " setbufline, in this case, will append the lines.
        call nvim_buf_set_lines(l:buf_num, a:lnum - 1, a:lnum - 1, v:true, l:content)
    elseif a:lnum > 1 + l:line_count
        " setbufline, in this case, will do nothing.
    elseif a:lnum + len(l:content) - 1 > l:line_count
        " setbufline, in this case, will replace the lines in can, and
        " append the rest of the lines.
        let l:lines_to_replace = l:line_count - a:lnum + 1
        call nvim_buf_set_lines(l:buf_num, a:lnum - 1, a:lnum + l:lines_to_replace - 1, v:true, l:content[: l:lines_to_replace - 1])
        call nvim_buf_set_lines(l:buf_num, l:line_count, l:line_count, v:true, l:content[l:lines_to_replace :])
    else
        " setbufline, in this case, will append the lines.
        call nvim_buf_set_lines(l:buf_num, a:lnum - 1, a:lnum - 1 + len(l:content), v:true, l:content)
    endif
endf

" WarnIfChanged()
"
func! ctrlsf#buf#WarnIfChanged() abort
    if getbufvar('%', '&modified')
        call ctrlsf#log#Warn("Will discard ALL unsaved changes, continue? (y/N)")
        let confirm = nr2char(getchar()) | redraw!
        if !(confirm ==? "y")
            return 0
        endif
    endif
    return 1
endf

" ClearUndoHistory()
"
func! ctrlsf#buf#ClearUndoHistory() abort
    let modified_bak = getbufvar('%', '&modified')
    let modifiable_bak = getbufvar('%', '&modifiable')
    setl modifiable
    let ul_bak = &undolevels
    set undolevels=-1
    exe "normal a \<BS>\<Esc>"
    let &undolevels = ul_bak
    unlet ul_bak
    call setbufvar('%', '&modifiable', modifiable_bak)
    call setbufvar('%', '&modified', modified_bak)
endf

" UndoAllChanges()
"
func! ctrlsf#buf#UndoAllChanges() abort
    if &modified
        silent! earlier 1f
    endif
endf

" ToogleMap()
"
" Enable/disable maps in CtrlSF window.
"
" There are 3 possible values of argument:
"
"   - 0    : disable
"   - 1    : enable
"   - None : toggle
"
func! ctrlsf#buf#ToggleMap(...) abort
    if a:0 > 0
        let enable_map = a:1
    else
        let enable_map = !b:ctrlsf_map_enabled
    endif

    " key 'prevw' is deprecated but remains for backward compatibility
    let act_func_ref = {
        \ "open"    : "ctrlsf#JumpTo('open')",
        \ "openb"   : "ctrlsf#JumpTo('open_background')",
        \ "split"   : "ctrlsf#JumpTo('split')",
        \ "vsplit"  : "ctrlsf#JumpTo('vsplit')",
        \ "tab"     : "ctrlsf#JumpTo('tab')",
        \ "tabb"    : "ctrlsf#JumpTo('tab_background')",
        \ "popen"   : "ctrlsf#JumpTo('preview')",
        \ "popenf"  : "ctrlsf#JumpTo('preview_foreground')",
        \ "quit"    : "ctrlsf#Quit()",
        \ "stop"    : "ctrlsf#StopSearch()",
        \ "next"    : "ctrlsf#NextMatch(1)",
        \ "prev"    : "ctrlsf#NextMatch(0)",
        \ "chgmode" : "ctrlsf#SwitchViewMode()",
        \ "loclist" : "ctrlsf#OpenLocList()",
        \ "prevw"   : "ctrlsf#JumpTo('preview')",
        \ }

    if enable_map
        call ctrlsf#utils#Nmap(g:ctrlsf_mapping, act_func_ref)
    else
        call ctrlsf#utils#Nunmap(g:ctrlsf_mapping, act_func_ref)
    endif

    let b:ctrlsf_map_enabled = enable_map
endf
