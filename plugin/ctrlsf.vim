if !exists('g:ctrlsf_debug') && exists('g:ctrlsf_loaded')
    finish
endif
let g:ctrlsf_loaded = 1

com! -n=+ CtrlSF call CtrlSF#Search(<q-args>)
com! -n=0 CtrlSFOpen call CtrlSF#OpenWindow()
com! -n=0 CtrlSFClose call CtrlSF#CloseWindow()
