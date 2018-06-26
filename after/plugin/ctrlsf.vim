" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" Loading Guard {{{1
if !exists('g:ctrlsf_debug') && exists('g:ctrlsf_tail_loaded')
    finish
endif
let g:ctrlsf_tail_loaded = 1
" }}}

" Airline support {{{1
func! CtrlSFStatusLine(...)
    " main window
    if bufname('%') == '__CtrlSF__'
        let w:airline_section_a = 'CtrlSF'
        let w:airline_section_b = '%{ctrlsf#utils#SectionB()}'
        let w:airline_section_c = '%{ctrlsf#utils#SectionC()}'
        let w:airline_section_x = '%{ctrlsf#utils#SectionX()}'
        let w:airline_section_y = ''
    endif

    " preview window
    if bufname('%') == '__CtrlSFPreview__'
        let w:airline_section_a = 'Preview'
        let w:airline_section_c = '%{ctrlsf#utils#PreviewSectionC()}'
    endif
endf

if exists('g:loaded_airline')
    call airline#add_statusline_func('CtrlSFStatusLine')
endif
