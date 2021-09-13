" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.6.0
" ============================================================================

"""""""""""""""""""""""""""""""""
" Misc Functions
"""""""""""""""""""""""""""""""""
" Mirror()
"
" Make {dicta} as an exact shallow copy of {dictb}
"
func! ctrlsf#utils#Mirror(dicta, dictb) abort
    for key in keys(a:dicta)
        call remove(a:dicta, key)
    endfo

    for key in keys(a:dictb)
        let a:dicta[key] = a:dictb[key]
    endfo

    return a:dicta
endf

" Nmap()
"
func! ctrlsf#utils#Nmap(map, act_func_ref) abort
    for act in keys(a:act_func_ref)
        if empty(get(a:map, act, ""))
            continue
        endif

        if type(a:map[act]) == 1
            exec "silent! nnoremap <silent><buffer> " . a:map[act]
                \ . " :call " . a:act_func_ref[act] . "<CR>"
        endif

        if type(a:map[act]) == 3
            for key in a:map[act]
                exec "silent! nnoremap <silent><buffer> " . key
                    \ . " :call " . a:act_func_ref[act] . "<CR>"
            endfo
        endif

        if type(a:map[act]) == 4
            let m = a:map[act]
            let suffix = has_key(m, 'suffix') ? m['suffix'] : ''
            if type(m['key']) == 1
                exec "silent! nnoremap <silent><buffer> " . m['key']
                    \ . " :call " . a:act_func_ref[act] . "<CR>" . suffix
            elseif type(m['key']) == 3
                for key in m['key']
                    exec "silent! nnoremap <silent><buffer> " . key
                        \ . " :call " . a:act_func_ref[act] . "<CR>" . suffix
                endfo
            endif
        endif
    endfo
endf

" Nunmap()
"
func! ctrlsf#utils#Nunmap(map, act_func_ref) abort
    for act in keys(a:act_func_ref)
        if empty(get(a:map, act, ""))
            continue
        endif

        if type(a:map[act]) == 1
            exec "nunmap <silent><buffer> " . a:map[act]
        endif

        if type(a:map[act]) == 3
            for key in a:map[act]
                exec "nunmap <silent><buffer> " . key
            endfo
        endif

        if type(a:map[act]) == 4
            let m = a:map[act]
            if type(m['key']) == 1
                exec "nunmap <silent><buffer> " . m['key']
            elseif type(a:map[act]) == 3
                for key in m['key']
                    exec "nunmap <silent><buffer> " . key
                endfo
            endif
        endif
    endfo
endf

" ShellEscape()
"
" Almost builtin shellescape() but not affected by 'shellslash' setting on
" windwos
"
func! ctrlsf#utils#ShellEscape(str) abort
    if has('win32')
        return '"' . substitute(a:str, '"', '""', 'g') . '"'
    else
        return shellescape(a:str)
    endif
endf

" Quote()
"
func! ctrlsf#utils#Quote(str) abort
    return '"' . escape(a:str, '"\') . '"'
endf

"""""""""""""""""""""""""""""""""
" Airline Support
"""""""""""""""""""""""""""""""""

" SectionB()
"
" Show current search pattern
"
func! ctrlsf#utils#SectionB()
    return 'Pattern: ' . ctrlsf#opt#GetOpt('pattern')
endf

" SectionC()
"
" Show filename of which cursor is currently placed in
"
func! ctrlsf#utils#SectionC()
    let [file, _, _] = ctrlsf#view#Locate(line('.'))
    return empty(file) ? '' : file
endf

" SectionX()
"
" Show total number of matches and current matching
"
func! ctrlsf#utils#SectionX()
    let [file, line, match] = ctrlsf#view#Locate(line('.'))
    if !empty(match)
        let matchlist = ctrlsf#db#MatchList()
        let total     = len(matchlist)
        let current   = index(matchlist, match) + 1
        return current . '/' . total
    else
        return ''
    endif
endf

" PreviewSectionC()
"
" Show previewing file's name
"
func! ctrlsf#utils#PreviewSectionC()
    return get(b:, 'ctrlsf_file', '')
endf

"""""""""""""""""""""""""""""""""
" Fzf Support
"""""""""""""""""""""""""""""""""

" ctrlsf#utils#FzfRun()
"
func! ctrlsf#utils#FzfRun() abort
    if exists('g:loaded_fzf')
        " backup g:fzf_action
        if exists('g:fzf_action')
            let fzf_action_bak = g:fzf_action
        endif

        let g:fzf_action = {
                    \ 'enter': function('s:FocusMatch'),
                    \ 'ctrl-o': function('s:OpenMatch'),
                    \ }
        call fzf#run(fzf#wrap({
                    \ 'source': ctrlsf#utils#FzfSource(),
                    \ }))

        " restore g:fzf_action
        if exists('fzf_action_bak')
            let g:fzf_action = fzf_action_bak
        else
            unlet g:fzf_action
        endif
    endif
endf

" ctrlsf#utils#FzfSource()
"
func! ctrlsf#utils#FzfSource() abort
    let matchlist = ctrlsf#db#MatchList()
    let num_len = strlen(len(matchlist))

    let lines = []
    for i in range(len(matchlist))
        let mat = matchlist[i]
        let line = printf("%".num_len."d:%s:%d:%s",
                    \ i+1, mat.filename, mat.lnum, mat.text)
        call add(lines, line)
    endfo

    return lines
endf

func! s:FocusMatch(lines) abort
    echom 'called FocusMatch'
    let n = trim(matchlist(a:lines[0], '\v^(\s*\d+):')[1])
    let match = ctrlsf#db#MatchList()[n-1]
    let vmode = ctrlsf#CurrentMode()
    call cursor(match.vlnum(vmode), match.vcol(vmode))
    normal! zv
endf

func! s:OpenMatch(lines) abort
    echom 'called OpenMatch'
    let n = trim(matchlist(a:lines[0], '\v^(\s*\d+):')[1])
    let match = ctrlsf#db#MatchList()[n-1]
    let line = ctrlsf#class#line#New(match.filename, match.lnum, match.text)
    call ctrlsf#JumpTo('open', match.filename, line, match)
endf
