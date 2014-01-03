if !exists('g:ctrlsf_left')
    let g:ctrlsf_left = 1
endif

if !exists('g:ctrlsf_ackprg')
    let g:ctrlsf_ackprg = 'ack'
endif

if !exists('g:ctrlsf_highlight')
    let g:ctrlsf_highlight = 1
endif

if !exists('g:ctrlsf_auto_close')
    let g:ctrlsf_auto_close = 1
endif

func! CtrlSF#CtrlSF(args)
    call s:OpenWindow()
    call s:CallAck(a:args)
endf

func! s:OpenWindow()
    let openpos = g:ctrlsf_left ? 'topleft vertical ' : 'botright vertical '
    exec 'silent keepalt ' . openpos . 'split ' . '__CtrlSF__'

    call s:InitWindow()
endf

func! s:InitWindow()
    setl filetype=ctrlsf
    setl noreadonly
    setl buftype=nofile
    setl bufhidden=hide
    setl noswapfile
    setl nobuflisted
    setl nomodifiable
    setl nolist
    setl nonumber
    setl nowrap
    setl winfixwidth
    setl textwidth=0
    setl nospell

    let &winwidth = exists('g:ctrlsf_width') ? g:ctrlsf_width : &columns/2
    wincmd =

    call s:SetDefaultMap()
endf

func! s:SetDefaultMap()
    map <silent><buffer> <CR> :call <SID>JumpTo()<CR>
    map <silent><buffer> q    :quit<CR>
endf

func! s:JumpTo()
    let [file, lnum, col] = s:jump_table[line('.') - 1]

    if g:ctrlsf_auto_close
        quit
    else
        wincmd p
    endif

    if &modified
        exec 'silent split ' . file
    else
        exec 'edit ' . file
    endif

    call cursor(lnum, col)
endf

func! s:ParseSearchOutput(raw_output)
    let s:parsed_result = []

    for line in split(a:raw_output, '\n')
        let matched = matchlist(line, '^\(\d*\)\([-:]\)\(\d*\)\([-:]\)\(.*\)$')

        " if line doesn't match, consider it as filename
        if empty(matched)
            call add(s:parsed_result, {
                \ 'filename' : line,
                \ 'lines'    : [],
                \ })
        else
            call add(s:parsed_result[-1]['lines'], {
                \ 'lnum'    : matched[1],
                \ 'col'     : matched[3],
                \ 'matched' : matched[4],
                \ 'content' : matched[5],
                \ })
        endif
    endfo
endf

func! s:RenderContent()
    let s:jump_table = []

    let output = ''
    for file in s:parsed_result
        let output .= s:FormatLine('filename', file.filename)
        call s:SetJmp('', '', '')
        for line in file.lines
            if !empty(line.lnum)
                let output .= s:FormatLine('normal', line)
                call s:SetJmp(file.filename, line.lnum, line.col)
            else
                let output .= s:FormatLine('empty', line)
                call s:SetJmp('', '', '')
            endif
        endfo
    endfo

    return output
endf

func! s:FormatLine(type, line)
    if a:type == 'filename'
        return a:line . ":\n"
    elseif a:type == 'normal'
        return a:line.lnum . a:line.matched . repeat(' ', 8) . a:line.content . "\n"
    elseif a:type == 'empty'
        return repeat('.', 4) . "\n"
    else
        " TODO // Log this as an error
        return ''
    endif
endf

func! s:SetJmp(file, line, col)
    call add(s:jump_table, [a:file, a:line, a:col])
endf

func! s:HighlightContent()
    syntax case match
    syntax match ctrlsfFilename /^.*:$/
    syntax match ctrlsfLnumMatch /^\d\+:/
    syntax match ctrlsfLnumUnmatch /^\d\+-/

    hi link ctrlsfFilename Title
    hi link ctrlsfLnumMatch Visual
    hi link ctrlsfLnumUnmatch Comment
endf

func! s:CallAck(args)
    setl modifiable

    silent %delete _

    let default_args = ' -H --heading --nocolor --column -C 3 '
    let raw_output = system(g:ctrlsf_ackprg . default_args . a:args . ' 2>/dev/null')

    call s:ParseSearchOutput(raw_output)

    silent 0put =s:RenderContent()
    call cursor(1, 1)

    if g:ctrlsf_highlight
        call s:HighlightContent()
    endif

    setl nomodifiable
endf
