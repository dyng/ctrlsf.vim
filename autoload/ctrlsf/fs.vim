" ============================================================================
" Description: An ack/ag/pt powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.7.2
" ============================================================================

" Meta folder of several typical version control systems
let s:vcs_folder = ['.git', '.hg', '.svn', '.bzr', '_darcs']

" FindVcsRoot()
"
func! ctrlsf#fs#FindVcsRoot() abort
    let vsc_dir = ''
    for vcs in s:vcs_folder
        let vsc_dir = finddir(vcs, expand('%:p:h').';')
        if !empty(vsc_dir)
            break
        endif
    endfo

    let root = empty(vsc_dir) ? '' : fnamemodify(vsc_dir, ':h')
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
