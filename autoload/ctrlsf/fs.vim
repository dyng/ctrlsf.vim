" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" Meta folder or file of several typical version control systems
let s:vcs_marker = [
            \ {'name': '.git', 'type': 'f'},
            \ {'name': '.git', 'type': 'd'},
            \ {'name': '.hg', 'type': 'd'},
            \ {'name': '.svn', 'type': 'd'},
            \ {'name': '.bzr', 'type': 'd'},
            \ {'name': '_darcs', 'type': 'd'},
            \ ]

" FindVcsRoot()
"
func! ctrlsf#fs#FindVcsRoot(...) abort
    if a:0 > 0
        let start_dir = a:1
    else
        let start_dir = expand('%:p:h')
    endif

    let marker = ''
    for m in s:vcs_marker
        if m.type ==# 'd'
            let marker = finddir(m.name, start_dir.';')
        else
            let marker = findfile(m.name, start_dir.';')
        endif
        if !empty(marker)
            break
        endif
    endfo

    let root = empty(marker) ? '' : fnamemodify(marker, ':h')
    call ctrlsf#log#Debug("ProjectRoot: %s", root)

    return root
endf

" DetectFileFormat
"
" Determine file's format by <EOL>.
"
" Possilble format is 'dos' and 'unix', 'mac' is NOT supported.
"
func! ctrlsf#fs#DetectFileFormat(path) abort
    let sample = readfile(a:path, 'b', 1)

    if stridx(sample[0], "\r") != -1
        let fmt = "dos"
    else
        let fmt = "unix"
    endif

    call ctrlsf#log#Debug("FileFormat: '%s' for file %s", fmt, a:path)
    return fmt
endf
