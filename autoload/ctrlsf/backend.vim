" CheckAckprg()
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
