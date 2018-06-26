" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" Completion()
"
func! ctrlsf#comp#Completion(arglead, cmdline, cursorpos)
    if a:arglead =~# '^-'
        return s:OptionComp(a:arglead, a:cmdline, a:cursorpos)
    else
        return s:PathComp(a:arglead, a:cmdline, a:cursorpos)
    endif
endf

" OptionComp()
"
func! s:OptionComp(arglead, cmdline, cursorpos)
    let options = ctrlsf#opt#OptionNames()
    return filter(options, "stridx(v:val, a:arglead) == 0")
endf

" PathComp()
"
" We need a custom completion function because if we use '-comp=file' then vim
" regards CtrlSF expecting file arguments and expand '%' to current file, '#'
" to alternate file and so on automatically, which is not what we want.
"
func! s:PathComp(arglead, cmdline, cursorpos)
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

    " escaping
    call map(candidate, 'escape(v:val, " \\")')

    return candidate
endf
