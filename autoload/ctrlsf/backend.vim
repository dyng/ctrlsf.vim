" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.40
" ============================================================================

" BuildCommand()
"
func! s:BuildCommand(args) abort
    let tokens = []

    " add executable file
    call add(tokens, g:ctrlsf_ackprg)

    " If user has specified '-A', '-B' or '-C', then use it without complaint
    " else use the default value 'g:ctrlsf_context'
    let ctx_options = ctrlsf#opt#GetContext()
    let context = ''
    for opt in keys(ctx_options)
        let context .= printf("--%s=%s ", opt, ctx_options[opt])
    endfo
    call add(tokens, context)

    " ignorecase
    let case_sensitive = ctrlsf#opt#GetCaseSensitive()
    let case = ''
    if case_sensitive ==# 'smartcase'
        let case = '--smart-case'
    elseif case_sensitive ==# 'ignorecase'
        let case = '--ignore-case'
    else
        if g:ctrlsf_ackprg =~# 'ag'
            let case = '--case-sensitive'
        else
            let case = '--no-smart-case'
        endif
    endif
    call add(tokens, case)

    " regex
    if !ctrlsf#opt#GetRegex()
        call add(tokens, '--literal')
    endif

    " filetype
    if !empty(ctrlsf#opt#GetOpt('filetype'))
        call add(tokens, '--' . ctrlsf#opt#GetOpt('filetype'))
    endif

    " filematch
    if !empty(ctrlsf#opt#GetOpt('filematch'))
        if g:ctrlsf_ackprg =~# 'ag'
            call extend(tokens, [
                \ '--file-search-regex',
                \ shellescape(ctrlsf#opt#GetOpt('filematch'))
                \ ])
        else
            " pipe: 'ack -g ${filematch} ${path} |'
            let pipe_tokens = [
                \ g:ctrlsf_ackprg,
                \ '-g',
                \ shellescape(ctrlsf#opt#GetOpt('filematch'))
                \ ]
            call extend(pipe_tokens, ctrlsf#opt#GetPath())
            call add(pipe_tokens, '|')

            call insert(tokens, join(pipe_tokens, ' '))
            call add(tokens, '--files-from=-')
        endif
    endif

    " default
    if g:ctrlsf_ackprg =~# 'ag'
        call add(tokens, '--noheading --nogroup --nocolor --nobreak')
    else
        call add(tokens, '--noheading --nogroup --nocolor --nobreak --nocolumn
            \ --with-filename')
    endif

    " pattern (including escape)
    call add(tokens, shellescape(ctrlsf#opt#GetOpt('pattern')))

    " path
    call extend(tokens, ctrlsf#opt#GetPath())

    return join(tokens, ' ')
endf

" SelfCheck()
"
func! ctrlsf#backend#SelfCheck() abort
    if !exists('g:ctrlsf_ackprg')
        call ctrlsf#log#Error("Option 'g:ctrlsf_ackprg' is not defined.")
        return -99
    endif

    if empty(g:ctrlsf_ackprg)
        call ctrlsf#log#Error("Can not find ack/ag on this system, make sure
            \ you have one of them installed.")
        return -99
    endif

    let prg = g:ctrlsf_ackprg

    if !executable(prg)
        call ctrlsf#log#Error('Can not locate %s in PATH, make sure you have it
            \ installed.', prg)
        return -2
    endif
endf

" Detect()
"
func! ctrlsf#backend#Detect()
    if executable('ag')
        return 'ag'
    endif

    if executable('ack-grep')
        return 'ack-grep'
    endif

    if executable('ack')
        return 'ack'
    endif

    return ''
endf

" Run()
"
" Execute Ack/Ag.
"
" Parameters
" {args} arguments for execution
"
" Returns
" [success/fail, output]
"
func! ctrlsf#backend#Run(args) abort
    let command = s:BuildCommand(a:args)
    call ctrlsf#log#Debug("ExecCommand: %s", command)

    " A windows user reports CtrlSF doesn't work well when 'shelltemp' is
    " turned off. Although I can't reproduce it, I think forcing 'shelltemp'
    " would not do something really bad.
    let stmp_bak = &shelltemp
    set shelltemp
    let output = system(command)
    let &shelltemp = stmp_bak

    if v:shell_error && !empty(output)
        return [0, output]
    else
        return [1, output]
    endif
endf
