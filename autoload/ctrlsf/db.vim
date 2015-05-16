" Data structure storing parsed query result
let s:resultset = []

func! ctrlsf#db#ResultSet() abort
    return s:resultset
endf

func! ctrlsf#db#FileSet() abort
    let fileset  = []
    let cur_file = ''
    for par in s:resultset
        if cur_file !=# par.file
            let cur_file = par.file
            call add(fileset, {
                \ "file": cur_file,
                \ "paragraphs": [],
                \ })
        endif
        call add(fileset[-1].paragraphs, par)
    endfo
    return fileset
endf

func! ctrlsf#db#MatchList() abort
    let matchlist = []
    for par in s:resultset
        call extend(matchlist, par.matches)
    endfo
    return matchlist
endf

" s:ParseParagraph()
"
" Notice that some fields are initialized with -1, which will be populated
" in render processing.
func! s:ParseParagraph(buffer, file) abort
    let paragraph = {
        \ 'file'    : a:file,
        \ 'lnum'    : -1,
        \ 'vlnum'   : -1,
        \ 'range'   : len(a:buffer),
        \ 'lines'   : [],
        \ 'matches' : [],
        \ }

    " parse first line for starting line number
    let paragraph.lnum = matchlist(a:buffer[0], '\v^(\d+)([-:])(\d*)')[1]

    for line in a:buffer
        let matched = matchlist(line, '\v^(\d+)([-:])(\d*)([-:])?(.*)$')

        " add matched line to match list
        let match = {}
        if matched[2] == ':'
            let match = {
                \ 'lnum'  : matched[1],
                \ 'vlnum' : -1,
                \ 'col'   : matched[3],
                \ 'vcol'  : -1
                \ }
            call add(paragraph.matches, match)
        endif

        " add line content
        call add(paragraph.lines, {
            \ 'matched' : !empty(match),
            \ 'match'   : match,
            \ 'lnum'    : matched[1],
            \ 'vlnum'   : -1,
            \ 'content' : matched[5],
            \ })
    endfo

    return paragraph
endf

" ParseAckprgOutput()
"
func! ctrlsf#db#ParseAckprgResult(result) abort
    " reset resultset
    let s:resultset = []

    let current_file = ""
    let next_file    = ""

    if len(ctrlsf#opt#GetOpt("path")) == 1
        let path = ctrlsf#opt#GetOpt("path")[0]
        if getftype(path) == 'file'
            let current_file = path
        endif
    endif

    let result_lines = split(a:result, '\n')

    let cur = 0
    while cur < len(result_lines)
        let buffer = []

        while cur < len(result_lines)
            let line = result_lines[cur]
            let cur += 1

            " if come across a division line, end loop and start parsing
            if line =~ '^--$'
                break
            " if line doesn't match [lnum:col] pattern, assume it is filename
            elseif line !~ '\v^\d+[-:]\d*'
                let next_file = line
                break
            else
                call add(buffer, line)
            endif
        endwh

        if len(buffer) > 0
            let paragraph = s:ParseParagraph(buffer, current_file)
            call add(s:resultset, paragraph)
        endif

        let current_file = next_file
    endwh
endf
