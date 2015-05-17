" BuildCommand()
"
func! s:BuildCommand(args) abort
    let tokens = []

    " add executable file
    call add(tokens, g:ctrlsf_ackprg)

    " If user has specified '-A', '-B' or '-C', then use it without complaint
    " else use the default value 'g:ctrlsf_context'
    call add(tokens, ctrlsf#opt#GetContext())

    " ignorecase (smartcase by default)
    call add(tokens, ctrlsf#opt#GetOpt('ignorecase') ? '--ignore-case'
        \ : '--smart-case')

    " regex
    call add(tokens, ctrlsf#opt#GetOpt('regex') ? '' : '--literal')

    " filetype
    let filetype = ctrlsf#opt#GetOpt('filetype')
    call add(tokens, empty(filetype) ? '' : '--' . filetype)

    " default
    call add(tokens, '--heading --group --nocolor --nobreak --column')

    " pattern (including escape)
    call add(tokens, shellescape(ctrlsf#opt#GetOpt('pattern')))

    " path (including escape)
    for path in ctrlsf#opt#GetOpt('path')
        call add(tokens, shellescape(path))
    endfo

    let cmd = join(tokens, ' ')
    call ctrlsf#log#Debug("ExecCommand: %s", cmd)

    return cmd
endf

" SelfCheck()
"
func! ctrlsf#backend#SelfCheck() abort
    if !exists('g:ctrlsf_ackprg')
        call ctrlsf#log#Error("Option 'g:ctrlsf_ackprg' is not defined.")
        return -99
    endif

    if empty(g:ctrlsf_ackprg)
        call ctrlsf#log#Error("Can not find ack or ag on this system.")
        return -99
    endif

    let prg = g:ctrlsf_ackprg

    if !executable(prg)
        call ctrlsf#log#Error('Can not locate %s in PATH.', prg)
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

    " A windows user report CtrlSF doesn't work well when 'shelltemp' is
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
