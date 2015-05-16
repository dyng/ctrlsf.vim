" BuildCommand()
"
func! s:BuildCommand(args) abort
    let tokens = []

    " add executable file
    call add(tokens, g:ctrlsf_ackprg)

    " If user has given '-A', '-B' or '-C', then use it without complaint
    " else use the default value 'g:ctrlsf_context'
    let context = ''
    for opt in ['after', 'before', 'context']
        if ctrlsf#opt#HasOpt(opt)
            let context .= printf('--%s=%s ', opt, ctrlsf#opt#GetOpt(opt))
        endif
    endfo
    if empty(context)
        for opt in ['after', 'before', 'context']
            if ctrlsf#opt#GetOpt(opt) > 0
                let context .= printf('--%s=%s ', opt, ctrlsf#opt#GetOpt(opt))
            endif
        endfo
    endif
    call add(tokens, context)

    " ignorecase
    call add(tokens, ctrlsf#opt#GetOpt('ignorecase') ? '--ignore-case' : '')

    " regex
    call add(tokens, ctrlsf#opt#GetOpt('regex') ? '' : '--literal')

    " filetype
    let filetype = ctrlsf#opt#GetOpt('filetype')
    call add(tokens, empty(filetype) ? '' : '--' . filetype)

    " default
    call add(tokens, '--heading --group --nocolor --nobreak --column')

    " pattern
    call add(tokens, ctrlsf#opt#GetOpt('pattern'))

    " path
    call extend(tokens, ctrlsf#opt#GetOpt('path'))

    let cmd = join(tokens, ' ')
    call ctrlsf#log#Debug(cmd)

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
