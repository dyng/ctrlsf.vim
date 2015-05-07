" Data structure storing query result
"
let s:resultset = []

let s:matches = []

func! ctrlsf#db#ParseAckprgResult(result) abort
    let current_file = ""

    if len(ctrlsf#opt#options.path) == 1
        let path = ctrlsf#opt#options.path[0]
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

            " if come across a blank line, end loop and start parsing
            if line =~ '^$'
                break
            " if line doesn't match [lnum:col] pattern, assume it is filename
            elseif line !~ '\v^\d+[-:]\d*'
                let current_file = line
            else
                call add(buffer, result_lines[cur])
            endif
        endwh

        if len(buffer) > 0
            call add(s:resultset, {
                \ 'file' : current_file,
                \ 'olnum' : 0,
                \ 'range' : 0,
                \ })
            for line in buffer
                let matched = matchlist(line, '\v^(\d+)([-:])(\d*)([-:])?(.*)$')

                call add(s:resultset)
            endfo
        endif
    endwh

    for line in split(a:result, '\n')
        " ignore blank line
        if line =~ '^$'
            continue
        endif

        let matched = matchlist(line, '\v^(\d*)([-:])(\d*)([-:])?(.*)$')

        " if line doesn't match, assume it is filename
        if empty(matched)
            let current_file = line
        else
            if matched[2] == ':'
                call add(s:match_list, 0) " insert 0 as placeholder
            endif
            call add(s:ackprg_result[-1]['lines'], {
                \ 'lnum'    : matched[1],
                \ 'symbol'  : matched[2],
                \ 'col'     : matched[3],
                \ 'content' : matched[5],
                \ })
        endif
    endfo
endf
