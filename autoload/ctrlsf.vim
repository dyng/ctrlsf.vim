" ============================================================================
" File: autoload/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

" Global Variables {{{1
let s:ackprg_result  = []
let s:match_list     = []
let s:jump_table     = []
let s:ackprg_options = {}
let s:launch_win     = {}
" }}}

" Static Constants {{{1
let s:ACK_ARGLIST = {
    \ '-A' : { 'argt': 'space',  'argc': 1, 'alias': '--after-context' },
    \ '-B' : { 'argt': 'space',  'argc': 1, 'alias': '--before-context' },
    \ '-C' : { 'argt': 'space',  'argc': 1, 'alias': '--context' },
    \ '-g' : { 'argt': 'space',  'argc': 1 },
    \ '-i' : { 'argt': 'none',   'argc': 0, 'alias': '--ignore-case' },
    \ '-m' : { 'argt': 'equals', 'argc': 1, 'alias': '--max-count' },
    \ '--ignore-case'    : { 'argt': 'none',   'argc': 0 },
    \ '--match'          : { 'argt': 'space',  'argc': 1 },
    \ '--max-count'      : { 'argt': 'equals', 'argc': 1 },
    \ '--pager'          : { 'argt': 'equals', 'argc': 1 },
    \ '--context'        : { 'argt': 'equals', 'argc': 1 },
    \ '--after-context'  : { 'argt': 'equals', 'argc': 1 },
    \ '--before-context' : { 'argt': 'equals', 'argc': 1 },
    \ '--file-from'      : { 'argt': 'equals', 'argc': 1 },
    \ }
let s:AG_ARGLIST = {
    \ '-A' : { 'argt': 'space', 'argc': 1, 'alias': '--after' },
    \ '-B' : { 'argt': 'space', 'argc': 1, 'alias': '--before' },
    \ '-C' : { 'argt': 'space', 'argc': 1, 'alias': '--context' },
    \ '-g' : { 'argt': 'space', 'argc': 1 },
    \ '-G' : { 'argt': 'space', 'argc': 1, 'alias': '--file-search-regex' },
    \ '-i' : { 'argt': 'none',  'argc': 0, 'alias': '--ignore-case' },
    \ '-m' : { 'argt': 'space', 'argc': 1, 'alias': '--max-count' },
    \ '-p' : { 'argt': 'space', 'argc': 1, 'alias': '--path-to-agignore' },
    \ '--after'       : { 'argt': 'space', 'argc': 1 },
    \ '--before'      : { 'argt': 'space', 'argc': 1 },
    \ '--context'     : { 'argt': 'space', 'argc': 1 },
    \ '--depth'       : { 'argt': 'space', 'argc': 1 },
    \ '--file-from'   : { 'argt': 'space', 'argc': 1 },
    \ '--ignore'      : { 'argt': 'space', 'argc': 1 },
    \ '--ignore-case' : { 'argt': 'none',  'argc': 0 },
    \ '--ignore-dir'  : { 'argt': 'space', 'argc': 1 },
    \ '--max-count'   : { 'argt': 'space', 'argc': 1 },
    \ '--pager'       : { 'argt': 'space', 'argc': 1 },
    \ '--file-search-regex' : { 'argt': 'space', 'argc': 1 },
    \ '--path-to-agignore'  : { 'argt': 'space', 'argc': 1 },
    \ }
let s:ARGLIST = {
    \ 'ag'       : s:AG_ARGLIST,
    \ 'ack-grep' : s:ACK_ARGLIST,
    \ 'ack'      : s:ACK_ARGLIST,
    \ }
" }}}

" Public Functions {{{1
" ctrlsf#Search() {{{2
func! ctrlsf#Search(args) abort
    call s:Search(a:args)
endf
" }}}

" ctrlsf#OpenWindow() {{{2
func! ctrlsf#OpenWindow() abort
    call s:OpenWindow()
endf
" }}}

" ctrlsf#CloseWindow() {{{2
func! ctrlsf#CloseWindow() abort
    call s:CloseWindow()
endf
" }}}

" ctrlsf#ClearSelectedLine() {{{2
func! ctrlsf#ClearSelectedLine() abort
    call s:ClearSelectedLine()
endf
" }}}

" Airline Support {{{2
" ctrlsf#SectionB() {{{3
func! ctrlsf#SectionB()
    return 'Search: ' . get(s:ackprg_options, 'pattern', '')
endf
" }}}

" ctrlsf#SectionC() {{{3
func! ctrlsf#SectionC()
    return get(get(s:jump_table, line('.')-1, {}), 'filename', '')
endf
" }}}

" ctrlsf#SectionX() {{{3
func! ctrlsf#SectionX()
     let total_matches = len(s:match_list)
     let passed_matches = 1 + s:BinarySearch(s:match_list, 0, total_matches-1, line('.'))
     return passed_matches . '/' . total_matches
endf
" }}}

" ctrlsf#PreviewSectionC() {{{3
func! ctrlsf#PreviewSectionC()
    return get(b:, 'ctrlsf_file', '')
endf
" }}}
" }}}
" }}}

" Actions {{{1
" s:Search() {{{2
func! s:Search(args) abort
    let args = a:args

    " If no pattern is given, use word under the cursor
    if empty(args)
        let args = expand('<cword>')
    endif

    call s:ParseAckprgOptions(args)

    if s:CheckAckprg() < 0
        return -1
    endif

    let command = s:BuildCommand(args)

    " A windows user report CtrlSF doesn't work well when 'shelltemp' is
    " turned off. Although I can't reproduce it, I think forcing 'shelltemp'
    " would not do something really bad.
    let stmp_bak = &shelltemp
    set shelltemp
    let ackprg_output = system(command)
    let &shelltemp = stmp_bak

    if v:shell_error && !empty(ackprg_output)
        echoerr printf('CtrlSF: Some error occurs in %s execution!', g:ctrlsf_ackprg)
        echomsg printf('Executed command: "%s".', command)
        echomsg 'Command output:'
        for line in split(ackprg_output, '\n')
            echomsg line
        endfo
        return -1
    endif

    call s:ParseAckprgOutput(ackprg_output)

    call s:OpenWindow()

    setl modifiable
    silent %delete _
    silent 0put =s:RenderContent()
    silent $delete _ " delete trailing empty line
    setl nomodifiable
    call cursor(1, 1)
endf
" }}}

" s:JumpTo() {{{2
func! s:JumpTo(mode) abort
    let [file, lnum, col] = s:jump_table[line('.') - 1]

    if empty(file) || empty(lnum)
        return
    endif

    if a:mode ==# 'o'
        call s:OpenFileInWindow(file, lnum, col, 1)
    elseif a:mode ==# 'O'
        call s:OpenFileInWindow(file, lnum, col, 2)
    elseif a:mode ==# 't'
        call s:OpenFileInTab(file, lnum, col, 1)
    elseif a:mode ==# 'T'
        call s:OpenFileInTab(file, lnum, col, 2)
    elseif a:mode ==# 'p'
        call s:PreviewFile(file, lnum, col)
    endif
endf
" }}}

" s:NextMatch() {{{2
func! s:NextMatch(forward) abort
    let current = line('.')
    let next = s:FindNextMatchLnum(current, a:forward)
    call cursor(next, g:ctrlsf_leading_space + s:jump_table[next-1][2])
endf
" }}}

" s:OpenWindow() {{{2
func! s:OpenWindow() abort
    " backup current bufnr and winnr
    let s:launch_win = {
        \ 'bufnr' : bufnr('%'),
        \ 'winnr' : winnr(),
        \ }

    " focus an existing ctrlsf window
    " if failed, initialize a new one
    if s:FocusCtrlsfWindow() == -1
        if g:ctrlsf_width =~ '\d\{1,2}%'
            let width = &columns * str2nr(g:ctrlsf_width) / 100
        elseif g:ctrlsf_width =~ '\d\+'
            let width = str2nr(g:ctrlsf_width)
        else
            let width = &columns / 2
        endif

        let openpos = g:ctrlsf_open_left ? 'topleft vertical ' : 'botright vertical '
        exec 'silent keepalt ' . openpos . width . 'split ' . '__CtrlSF__'

        call s:InitWindow()
    endif

    " resize other windows
    wincmd =

    call s:HighlightMatch()
endf
" }}}

" s:CloseWindow() {{{2
func! s:CloseWindow() abort
    if s:FocusCtrlsfWindow() == -1
        return
    endif

    call s:ClosePreviewWindow()

    " Surely we are in CtrlSF window
    close

    call s:FocusPreviousWindow()
endf
" }}}

" s:OpenFileInWindow() {{{2
" s:OpenFileInWindow has 2 modes:
"
" 1. Open file in a window (usually the window where CtrlSF was launched), then
" close CtrlSF window depending on the value of 'g:ctrlsf_auto_close'.
"
" 2. Open file in a window like mode 1, but don't close CtrlSF no matter what
" 'g:ctrlsf_auto_close' is.
"
func! s:OpenFileInWindow(file, lnum, col, mode) abort
    let target_winnr = s:FindTargetWindow(a:file)

    if a:mode == 1 && g:ctrlsf_auto_close
        let ctrlsf_winnr = s:FindCtrlsfWindow()
        if ctrlsf_winnr <= target_winnr
            let target_winnr -= 1
        endif
        call s:CloseWindow()
    endif

    if target_winnr == 0
        exec 'silent split ' . a:file
    else
        exec target_winnr . 'wincmd w'

        if bufname('%') !~# a:file
            if &modified
                exec 'silent split ' . a:file
            else
                exec 'edit ' . a:file
            endif
        endif
    endif

    call s:MoveCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call s:HighlightSelectedLine()
    endif
endf
" }}}

" s:OpenFileInTab() {{{2
" s:OpenFileInTab has 2 modes:
"
" 1. Open file in a new tab, close or leave CtrlSF window depending on value
" of 'g:ctrlsf_auto_close', and place cursor in the new tab.
"
" 2. Open file in a new tab like mode 1, but focus CtrlSF window instead,
" and never close CtrlSF window.
"
func! s:OpenFileInTab(file, lnum, col, mode) abort
    if a:mode == 1 && g:ctrlsf_auto_close
        call s:CloseWindow()
    endif

    exec 'tabedit ' . a:file

    call s:MoveCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'o'
        call s:HighlightSelectedLine()
    endif

    if a:mode == 2
        tabprevious
    endif
endf
" }}}

" s:PreviewFile() {{{2
func! s:PreviewFile(file, lnum, col) abort
    if (s:FocusPreviewWindow() == -1)
        call s:OpenPreviewWindow()
    endif

    if !exists('b:ctrlsf_file') || b:ctrlsf_file !=# a:file
        setl modifiable
        silent %delete _
        exec 'silent 0read ' . a:file
        setl nomodifiable

        " trigger filetypedetect (syntax highlight)
        exec 'doau filetypedetect BufRead ' . a:file

        let b:ctrlsf_file = a:file
    endif

    call s:MoveCursor(a:lnum, a:col)

    if g:ctrlsf_selected_line_hl =~ 'p'
        call s:HighlightSelectedLine()
    endif

    call s:FocusCtrlsfWindow()
endf
" }}}

" s:OpenPreviewWindow() {{{2
func! s:OpenPreviewWindow() abort
    let ctrlsf_width  = winwidth(0)
    let width = min([&columns-ctrlsf_width, ctrlsf_width])

    let openpos = g:ctrlsf_open_left ? 'rightbelow vertical ' : 'leftabove vertical '
    exec 'silent keepalt ' . openpos . width . 'split ' . '__CtrlSFPreview__'

    setl buftype=nofile
    setl bufhidden=hide
    setl noswapfile
    setl nobuflisted
    setl nomodifiable
    setl winfixwidth

    map q :call <SID>ClosePreviewWindow()<CR>
endf
" }}}

" s:ClosePreviewWindow() {{{2
func! s:ClosePreviewWindow() abort
    if s:FocusPreviewWindow() == -1
        return
    endif

    close

    call s:FocusCtrlsfWindow()
endf
" }}}

" s:MoveCursor() {{{2
func! s:MoveCursor(lnum, col) abort
    " Move cursor to matched line
    exec 'normal ' . a:lnum . 'z.'
    call cursor(a:lnum, a:col)

    " Open fold
    normal zv
endf
" }}}

" s:ClearSelectedLine() {{{2
func! s:ClearSelectedLine() abort
    silent! call matchdelete(b:ctrlsf_highlight_id)
endf
" }}}
" }}}

" Window Operations {{{1
" s:InitWindow() {{{2
func! s:InitWindow() abort
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
    setl nofoldenable

    " default map
    nnoremap <silent><buffer> <CR>  :call <SID>JumpTo('o')<CR>
    nnoremap <silent><buffer> o     :call <SID>JumpTo('o')<CR>
    nnoremap <silent><buffer> O     :call <SID>JumpTo('O')<CR>
    nnoremap <silent><buffer> t     :call <SID>JumpTo('t')<CR>
    nnoremap <silent><buffer> T     :call <SID>JumpTo('T')<CR>
    nnoremap <silent><buffer> p     :call <SID>JumpTo('p')<CR>
    nnoremap <silent><buffer> <C-J> :call <SID>NextMatch(1)<CR>
    nnoremap <silent><buffer> <C-K> :call <SID>NextMatch(0)<CR>
    nnoremap <silent><buffer> q     :call <SID>CloseWindow()<CR>
endf
" }}}

" s:FindCtrlsfWindow() {{{2
func! s:FindCtrlsfWindow() abort
    return bufwinnr('__CtrlSF__')
endf
" }}}

" s:FindPreviewWindow() {{{2
func! s:FindPreviewWindow() abort
    return bufwinnr('__CtrlSFPreview__')
endf
" }}}

" s:FocusCtrlsfWindow() {{{2
func! s:FocusCtrlsfWindow() abort
    let ctrlsf_winnr = s:FindCtrlsfWindow()
    if ctrlsf_winnr == -1
        return -1
    else
        exec ctrlsf_winnr . 'wincmd w'
        return ctrlsf_winnr
    endif
endf
" }}}

" s:FocusPreviewWindow() {{{2
func! s:FocusPreviewWindow() abort
    let preview_winnr = s:FindPreviewWindow()
    if preview_winnr == -1
        return -1
    else
        exec preview_winnr . 'wincmd w'
        return preview_winnr
    endif
endf
" }}}

" s:FindTargetWindow() {{{2
func! s:FindTargetWindow(file) abort
    let target_winnr = bufwinnr(a:file)

    " case: there is a window containing the target file
    if target_winnr > 0
        return target_winnr
    endif

    " case: previous window where ctrlsf was triggered
    let ctrlsf_winnr = s:FindCtrlsfWindow()
    if ctrlsf_winnr > 0 && ctrlsf_winnr <= s:launch_win.winnr
        let target_winnr = s:launch_win.winnr + 1
    else
        let target_winnr = s:launch_win.winnr
    endif

    if winbufnr(target_winnr) == s:launch_win.bufnr && empty(getwinvar(target_winnr, '&buftype'))
        return target_winnr
    endif

    " case: pick up the first window containing regular file
    let nr = 1
    while nr <= winnr('$')
        if empty(getwinvar(nr, '&buftype'))
            return nr
        endif
        let nr += 1
    endwh

    " case: can't find any valid window, tell front to open a new window
    return 0
endf
" }}}

" s:FocusPreviousWindow() {{{2
func! s:FocusPreviousWindow() abort
    let ctrlsf_winnr = s:FindCtrlsfWindow()
    if ctrlsf_winnr > 0 && ctrlsf_winnr <= s:launch_win.winnr
        let pre_winnr = s:launch_win.winnr + 1
    else
        let pre_winnr = s:launch_win.winnr
    endif

    if winbufnr(pre_winnr) != -1
        exec pre_winnr . 'wincmd w'
    else
        wincmd p
    endif
endf
" }}}

" s:HighlightMatch() {{{2
func! s:HighlightMatch() abort
    if !exists('b:current_syntax') || b:current_syntax != 'ctrlsf'
        return -1
    endif

    if !has_key(s:ackprg_options, 'pattern')
        return -2
    endif

    let case    = get(s:ackprg_options, 'ignorecase') ? '\c' : ''
    let pattern = printf('/\v%s%s/', case, escape(s:ackprg_options['pattern'], '/'))
    exec 'match ctrlsfMatch ' . pattern
endf
" }}}

" s:HighlightSelectedLine() {{{2
func! s:HighlightSelectedLine() abort
    " Clear previous highlight
    call s:ClearSelectedLine()

    let pattern = '\%' . line('.') . 'l.*'
    let b:ctrlsf_highlight_id = matchadd('ctrlsfSelectedLine', pattern, -1)
endf
" }}}

" s:FindNextMatchLnum() {{{2
func! s:FindNextMatchLnum(current, forward)
    let mlist_len = len(s:match_list)

    let i_le = s:BinarySearch(s:match_list, 0, mlist_len - 1, a:current)

    if a:forward
        let i_next = i_le + 1
    else
        if s:match_list[i_le] == a:current
            let i_next = i_le - 1
        else
            let i_next = i_le
        endif
    endif

    if i_next >= mlist_len || i_next < 0
        return a:current
    else
        return s:match_list[i_next]
    endif
endf
" }}}
" }}}

" Input {{{1
" s:ParseAckprgOptions() {{{2
" A primitive approach. *CAN NOT* guarantee to parse correctly in the worst
" situation.
func! s:ParseAckprgOptions(args) abort
    let s:ackprg_options = {}

    let args = a:args
    let prg  = g:ctrlsf_ackprg

    " example: "a b" -> a\ b, "a\" b" -> a\"\ b
    let args = substitute(args, '\v(\\)@<!"(.{-})(\\)@<!"', '\=escape(submatch(2)," ")', 'g')

    " example: 'a b' -> a\ b
    let args = substitute(args, '\v''(.{-})''', '\=escape(submatch(1)," ")', 'g')

    let argv = split(args, '\v(\\)@<!\s+')
    call map(argv, 'substitute(v:val, ''\\ '', " ", "g")')

    let argc = len(argv)

    let path = []
    let i    = 0
    while i < argc
        let arg = argv[i]

        " extract option name from arguments like '--context=3'
        let tmp_match = matchstr(arg, '^[0-9A-Za-z-]\+\ze=')
        if !empty(tmp_match)
            let arg = tmp_match
        endif

        if has_key(s:ARGLIST[prg], arg)
            let arginfo = s:ARGLIST[prg][arg]
            let key = exists('arginfo.alias') ? arginfo.alias : arg

            if arginfo.argt == 'space'
                let s:ackprg_options[key] = argv[ i+1 : i+arginfo.argc ]
                let i += arginfo.argc
            elseif arginfo.argt == 'none'
                let s:ackprg_options[key] = 1
            elseif arginfo.argt == 'equals'
                let s:ackprg_options[key] = matchstr(argv[i], '^[^=]*=\zs.*$')
            endif
        else
            if arg =~ '^-'
                " unlisted arguments
                let s:ackprg_options[arg] = 1
            else
                " possible path
                call add(path, arg)
            endif
        endif

        let i += 1
    endwhile

    if !has_key(s:ackprg_options, '--match')
        let pattern = empty(path) ? '' : remove(path, 0)
        let s:ackprg_options['--match'] = [pattern]
    endif

    " currently these are arguments we are interested
    let s:ackprg_options['path']       = path
    let s:ackprg_options['pattern']    = s:ackprg_options['--match'][0]
    let s:ackprg_options['ignorecase'] = has_key(s:ackprg_options, '--ignore-case') ? 1 : 0
    let s:ackprg_options['context']    = 0
    for opt in ['--after', '--before', '--after-context', '--before-context', '--context']
        if has_key(s:ackprg_options, opt)
            let s:ackprg_options['context'] = 1
        endif
    endfo
endf
" }}}

" s:ParseAckprgOutput() {{{2
func! s:ParseAckprgOutput(raw_output) abort
    let s:ackprg_result = []
    let s:match_list    = []

    if len(s:ackprg_options.path) == 1
        let single_file = s:ackprg_options.path[0]
        if getftype(single_file) == 'file'
            call add(s:ackprg_result, {
                \ 'filename' : single_file,
                \ 'lines'    : [],
                \ })
        endif
    endif

    for line in split(a:raw_output, '\n')
        " ignore blank line
        if line =~ '^$'
            continue
        endif

        let matched = matchlist(line, '\v^(\d*)([-:])(\d*)([-:])?(.*)$')

        " if line doesn't match, consider it as filename
        if empty(matched)
            call add(s:ackprg_result, {
                \ 'filename' : line,
                \ 'lines'    : [],
                \ })
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
" }}}
" }}}

" Output {{{1
" s:RenderContent() {{{2
func! s:RenderContent() abort
    let s:jump_table = []
    let content      = []

    let match_count  = len(s:match_list)
    let s:match_list = []

    " Summary
    call s:InsertLineAndSetJmp(content, 'summary', {
        \ 'files'   : len(s:ackprg_result),
        \ 'matches' : match_count,
        \ })
    call s:InsertLineAndSetJmp(content, 'blank')

    for file in s:ackprg_result
        " Filename
        call s:InsertLineAndSetJmp(content, 'filename', file.filename)

        " Result
        for line in file.lines
            if !empty(line.lnum)
                call s:InsertLineAndSetJmp(content, 'normal', line, {
                    \ 'file' : file.filename,
                    \ 'lnum' : line.lnum,
                    \ 'col'  : line.col,
                    \ })
            else
                call s:InsertLineAndSetJmp(content, 'ellipsis', '', {
                    \ 'file' : file.filename,
                    \ 'lnum' : 0,
                    \ 'col'  : 0,
                    \ })
            endif
        endfo

        " Insert empty line between files
        if file isnot s:ackprg_result[-1]
            call s:InsertLineAndSetJmp(content, 'blank')
        endif
    endfo

    return join(content, "\n")
endf
" }}}

" s:InsertLineAndSetJmp() {{{2
func! s:InsertLineAndSetJmp(buffer, type, ...) abort
    let arg     = exists('a:1') ? a:1 : ''
    let jmpinfo = exists('a:2') ? a:2 : {}

    let content = s:FormatLine(a:type, arg)
    call add(a:buffer, content)

    if !empty(jmpinfo)
        call s:SetJmpTable(jmpinfo.file, jmpinfo.lnum, jmpinfo.col)
    else
        call s:SetJmpTable('', '', '')
    endif

    if a:type == 'normal' && arg.symbol == ':'
        call s:SetMatchList(len(a:buffer))
    endif
endf
" }}}

" s:FormatLine() {{{2
func! s:FormatLine(type, arg) abort
    if a:type == 'summary'
        let output = printf("%s matched lines across %s files", a:arg.matches, a:arg.files)
    elseif a:type == 'filename'
        let output = a:arg . ":"
    elseif a:type == 'normal'
        let output = a:arg.lnum . a:arg.symbol
        let output .= repeat(' ', g:ctrlsf_leading_space - len(output)) . a:arg.content
    elseif a:type == 'ellipsis'
        let output = repeat('.', 4)
    elseif a:type == 'blank'
        let output = ""
    endif
    return output
endf
" }}}

" s:SetJmpTable() {{{2
func! s:SetJmpTable(file, line, col) abort
    call add(s:jump_table, [a:file, a:line, a:col])
endf
" }}}

" s:SetMatchList() {{{2
func! s:SetMatchList(linenr) abort
    call add(s:match_list, a:linenr)
endf
" }}}
" }}}

" Utils {{{1
" s:CheckAckprg() {{{2
func! s:CheckAckprg() abort
    if !exists('g:ctrlsf_ackprg')
        echoerr 'g:ctrlsf_ackprg is not defined!'
        return -99
    endif

    if empty(g:ctrlsf_ackprg)
        echoerr 'ack/ag is not found in the system!'
        return -99
    endif

    let prg = g:ctrlsf_ackprg

    if !has_key(s:ARGLIST, prg)
        echoerr printf('%s is not supported by ctrlsf.vim!', prg)
        return -1
    endif

    if !executable(prg)
        echoerr printf('%s does not seem installed!', prg)
        return -2
    endif
endf
" }}}

" s:BuildCommand() {{{2
func! s:BuildCommand(args) abort
    let prg      = g:ctrlsf_ackprg
    let u_args   = escape(a:args, '%#!')
    let context  = s:ackprg_options['context'] ? '' : g:ctrlsf_context
    let prg_args = {
        \ 'ag'       : '--heading --group --nocolor --nobreak --column',
        \ 'ack'      : '--heading --group --nocolor --nobreak',
        \ 'ack-grep' : '--heading --group --nocolor --nobreak',
        \ }
    return printf('%s %s %s %s', prg, prg_args[prg], context, u_args)
endf
" }}}

" s:BinarySearch() {{{
" Search for the maximum number in 'array' that less or equal to 'key'
func! s:BinarySearch(array, imin, imax, key)
    let array = a:array | let key  = a:key
    let imax  = a:imax  | let imin = a:imin

    let ret = -1
    while (imax >= imin)
        let imid = (imax + imin) / 2

        if array[imid] < key
            let ret = imid
            let imin = imid + 1
        elseif array[imid] > key
            let imax = imid - 1
        else
            let ret = imid | break
        endif
    endwh

    return ret
endf
" }}}
" }}}

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
