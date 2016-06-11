" ============================================================================
" Description: An ack/ag/pt powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.7.2
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
        if ctrlsf#backend#Runner() ==# 'ag'
            let case = '--case-sensitive'
        elseif ctrlsf#backend#Runner() ==# 'pt'
            let case = ''
        else
            let case = '--no-smart-case'
        endif
    endif
    call add(tokens, case)

    " ignore (dir, file)
    let ignore_dir = ctrlsf#opt#GetIgnoreDir()
    for dir in ignore_dir
        if ctrlsf#backend#Runner() ==# 'pt'
            call add(tokens, "--ignore " . shellescape(dir))
        else
            call add(tokens, "--ignore-dir " . shellescape(dir))
        endif
    endfor

    " regex
    if ctrlsf#opt#GetRegex()
        if ctrlsf#backend#Runner() ==# 'pt'
            call add(tokens, '-e')
        endif
    else
        if ctrlsf#backend#Runner() !=# 'pt'
            call add(tokens, '--literal')
        endif
    endif

    " filetype
    if !empty(ctrlsf#opt#GetOpt('filetype'))
        if ctrlsf#backend#Runner() !=# 'pt'
            call add(tokens, '--' . ctrlsf#opt#GetOpt('filetype'))
        endif
    endif

    " filematch
    if !empty(ctrlsf#opt#GetOpt('filematch'))
        if ctrlsf#backend#Runner() ==# 'ag'
            call extend(tokens, [
                \ '--file-search-regex',
                \ shellescape(ctrlsf#opt#GetOpt('filematch'))
                \ ])
        elseif ctrlsf#backend#Runner() ==# 'pt'
            call add(tokens, printf("--file-search-regex=%s",
                \ shellescape(ctrlsf#opt#GetOpt('filematch'))))
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
    if ctrlsf#backend#Runner() ==# 'ag'
        call add(tokens, '--noheading --nogroup --nocolor --nobreak')
    elseif ctrlsf#backend#Runner() ==# 'pt'
        call add(tokens, '--nogroup --nocolor')
    else
        call add(tokens, '--noheading --nogroup --nocolor --nobreak --nocolumn
            \ --with-filename')
    endif

    " user custom arguments
    let extra_args = get(g:ctrlsf_extra_backend_args, ctrlsf#backend#Runner(), "")
    if !empty(extra_args)
        call add(tokens, extra_args)
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
    if !exists('g:ctrlsf_ackprg') || empty(g:ctrlsf_ackprg)
        call ctrlsf#log#Error("Option 'g:ctrlsf_ackprg' is not defined or empty
            \ .")
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

    if executable('pt')
        return 'pt'
    endif

    if executable('ack-grep')
        return 'ack-grep'
    endif

    if executable('ack')
        return 'ack'
    endif

    return ''
endf

" Runner()
"
func! ctrlsf#backend#Runner()
    if !exists('g:ctrlsf_ackprg')
        return ''
    elseif g:ctrlsf_ackprg =~# 'ag'
        return 'ag'
    elseif g:ctrlsf_ackprg =~# 'pt'
        return 'pt'
    elseif g:ctrlsf_ackprg =~# 'ack-grep'
        return 'ack'
    elseif g:ctrlsf_ackprg =~# 'ack'
        return 'ack'
    else
        return ''
    endif
endf

" Run()
"
" Execute backend.
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
