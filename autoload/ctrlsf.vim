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
    call ctrlsf#win#OpenWindow()
endf
" }}}

" ctrlsf#CloseWindow() {{{2
func! ctrlsf#CloseWindow() abort
    call ctrlsf#win#CloseWindow()
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
     let passed_matches = 1 + ctrlsf#utils#BinarySearch(s:match_list, 0, total_matches-1, line('.'))
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

    call ctrlsf#db#ParseAckprgResult(ackprg_output)

    call ctrlsf#win#OpenWindow()

    call s:HighlightMatch()

    setl modifiable
    silent %delete _
    silent 0put =ctrlsf#view#Render()
    silent $delete _ " delete trailing empty line
    setl nomodifiable
    call cursor(1, 1)
endf
" }}}

" s:JumpTo() {{{2
func! ctrlsf#JumpTo(mode) abort
    let [file, line, match] = ctrlsf#view#Reflect(line('.'))

    if empty(file) || empty(line)
        return
    endif

    let lnum = line.lnum
    let col  = empty(match)? 0 : match.col

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
func! ctrlsf#NextMatch(forward) abort
    let [vlnum, vcol] = ctrlsf#view#FindNextMatch(line('.'), a:forward)
    call cursor(vlnum, vcol)
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
    let target_winnr = ctrlsf#win#FindTargetWindow(a:file)

    if a:mode == 1 && g:ctrlsf_auto_close
        let ctrlsf_winnr = ctrlsf#win#FindMainWindow()
        if ctrlsf_winnr <= target_winnr
            let target_winnr -= 1
        endif
        call ctrlsf#win#CloseWindow()
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
        call ctrlsf#win#CloseWindow()
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
    if (ctrlsf#win#FocusPreviewWindow() == -1)
        call ctrlsf#win#OpenPreviewWindow()
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

    call ctrlsf#win#FocusMainWindow()
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
" s:HighlightMatch() {{{2
func! s:HighlightMatch() abort
    if !exists('b:current_syntax') || b:current_syntax != 'ctrlsf'
        return -1
    endif

    if !has_key(s:ackprg_options, 'pattern')
        return -2
    endif

    let case = ''
    if (g:ctrlsf_ackprg == 'ag' || get(s:ackprg_options, 'ignorecase'))
        let case = '\c'
    endif
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
" }}}

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
