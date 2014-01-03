if !exists('g:ctrlsf_debug') && exists('g:ctrlsf_loaded')
    finish
endif
let g:ctrlsf_loaded = 1

com! -n=+ CtrlSF call CtrlSF#CtrlSF(<q-args>)

if exists('g:ctrlsf_debug')
    so autoload/ctrlsf.vim
endif
