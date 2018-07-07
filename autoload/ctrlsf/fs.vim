" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" Meta folder or file of several typical version control systems
let s:vcs_marker = ['.git', '.svn', '.bzr', '_darcs']

" FindProjectRoot()
"
func! ctrlsf#fs#FindProjectRoot(...) abort
    if a:0 > 0
        let start_dir = a:1
    else
        let start_dir = expand('%:p:h')
    endif

    let markers = g:ctrlsf_extra_root_markers + s:vcs_marker

    let marker = s:FindMarker(start_dir, markers)
    let root = empty(marker) ? '' : fnamemodify(marker, ':h')
    call ctrlsf#log#Debug("ProjectRoot: %s", root)

    return root
endf

" s:FindMarker()
"
" Find root marker recursively.
"
func! s:FindMarker(dir, markers) abort
    for m in a:markers
        let marker = globpath(a:dir, m, 1)
        if !empty(marker)
            return marker
        endif
    endfor

    let parent = fnamemodify(a:dir, ':h')

    " hit the root
    if parent ==# a:dir
        return ''
    else
        return s:FindMarker(parent, a:markers)
    endif
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
