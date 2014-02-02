" ============================================================================
" File: after/plugin/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 0.01
" ============================================================================

" Airline support {{{1
func! CtrlSFStatusLine(...)
    " main window
    if bufname('%') == '__CtrlSF__'
        let w:airline_section_a = 'CtrlSF'
        let w:airline_section_b = '%{ctrlsf#SectionB()}'
        let w:airline_section_c = '%{ctrlsf#SectionC()}'
        let w:airline_section_x = '%{ctrlsf#SectionX()}'
        let w:airline_section_y = ''
    endif

    " preview window
    if bufname('%') == '__CtrlSFPreview__'
        let w:airline_section_a = 'Preview'
        let w:airline_section_c = '%{ctrlsf#PreviewSectionC()}'
    endif
endf

if exists('g:loaded_airline')
    call airline#add_statusline_func('CtrlSFStatusLine')
endif
" }}}

" modeline {{{1
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker spell:
