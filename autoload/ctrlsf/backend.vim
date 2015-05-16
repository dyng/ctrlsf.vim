" CheckAckprg()
func! ctrlsf#backend#SelfCheck() abort
    if !exists('g:ctrlsf_ackprg')
        echoerr 'g:ctrlsf_ackprg is not defined!'
        return -99
    endif

    if empty(g:ctrlsf_ackprg)
        echoerr 'ack/ag is not found in the system!'
        return -99
    endif

    let prg = g:ctrlsf_ackprg

    if !executable(prg)
        echoerr printf('%s does not seem installed!', prg)
        return -2
    endif
endf

" BuildCommand()
func! ctrlsf#backend#BuildCommand(args) abort
    let prg      = g:ctrlsf_ackprg
    let u_args   = escape(a:args, '%#!')
    let context  = '-C ' . ctrlsf#opt#GetOpt('context')
    let prg_args = {
        \ 'ag'       : '--heading --group --nocolor --nobreak --column',
        \ 'ack'      : '--heading --group --nocolor --nobreak',
        \ 'ack-grep' : '--heading --group --nocolor --nobreak',
        \ }
    return printf('%s %s %s %s', prg, prg_args[prg], context, u_args)
endf
