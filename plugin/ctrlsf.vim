" ============================================================================
" File: plugin/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

if !exists('g:ctrlsf_debug') && exists('g:ctrlsf_loaded')
    finish
endif
let g:ctrlsf_loaded = 1

com! -n=+ -comp=customlist,s:PathnameComp CtrlSF      call CtrlSF#Search(<q-args>)
com! -n=0                                 CtrlSFOpen  call CtrlSF#OpenWindow()
com! -n=0                                 CtrlSFClose call CtrlSF#CloseWindow()

" We need a custom completion function because if we use '-comp=file' then vim
" regards CtrlSF expecting file arguments and expand '%' to current file, '#'
" to alternate file and so on automatically, which is not what we want.
func! s:PathnameComp(arglead, cmdline, cursorpos)
    let path     = a:arglead
    let expanded = expand(path)
    let is_glob  = (expanded == a:arglead) ? 0 : 1

    if is_glob
        if expanded =~ '\n'
            let candidate = split(expanded, '\n')
        else
            let candidate = [ expanded ]
        endif
        call map(candidate, 'fnamemodify(v:val, ":p:.")')
    else
        if isdirectory(path) && path !~ '/$'
            let candidate = [ path . '/' ]
        else
            let candidate = split(glob(path . '*'), '\n')
            call map(candidate, 'fnamemodify(v:val, ":.")')
        endif
    endif

    return candidate
endf
