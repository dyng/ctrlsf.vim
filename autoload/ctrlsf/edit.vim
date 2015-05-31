" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

" s:DiffFile()
"
func! s:DiffFile(orig, modi) abort
    if a:orig.file !=# a:modi.file
        \ || len(a:orig.paragraphs) != len(a:modi.paragraphs)
        throw 'InconsistentException'
    endif

    let i = 0
    while i < len(a:orig.paragraphs)
        let opar = a:orig.paragraphs[i]
        let mpar = a:modi.paragraphs[i]
        let i += 1

        if opar.range() != mpar.range()
            return 1
        endif

        let j = 0
        while j < opar.range()
            if opar.lines[j].content !=# mpar.lines[j].content
                return 1
            endif

            let j += 1
        endwh
    endwh

    return 0
endf

" s:Diff()
"
" Return list of changed files.
"
func! s:Diff(orig, modi) abort
    if len(a:orig) != len(a:modi)
        throw 'InconsistentException'
    endif

    let changed_files = []

    let i = 0
    while i < len(a:orig)
        let [file_orig, file_modi] = [a:orig[i], a:modi[i]]
        let i += 1

        if s:DiffFile(file_orig, file_modi)
            call add(changed_files, {
                \ "orig": file_orig,
                \ "modi": file_modi
                \ })
        endif
    endwh

    return changed_files
endf

" s:VerifyConsistent()
"
" Check if a file in resultset is different from its disk counterpart.
"
func! s:VerifyConsistent(buffer, orig)
    for par in a:orig.paragraphs
        for i in range(par.range())
            let ln = par.lnum() + i
            let line = par.lines[i]

            if line.content !=# a:buffer[ln-1]
                return 0
            endif
        endfo
    endfo

    return 1
endf

" s:WriteParagraph()
"
" Function which does two things:
"
" 1. modify, insert or/and delete lines in buffer
" 2. update resultset to represent modified content
"
func! s:WriteParagraph(buffer, orig, modi, offset)
    let orig_count  = a:orig.range()
    let modi_count  = a:modi.range()
    let start_lnum  = a:orig.lnum()
    let start_vlnum = a:orig.vlnum()

    for i in range(modi_count)
        let mline = a:modi.lines[i]
        let ln    = start_lnum + i + a:offset
        let vln   = start_vlnum + i + a:offset

        " create new line object
        let line_obj = {
            \ 'matched' : function("ctrlsf#class#line#Matched"),
            \ 'match'   : {},
            \ 'lnum'    : ln,
            \ 'vlnum'   : vln,
            \ 'content' : mline.content
            \ }

        let mat_idx = match(line_obj.content, ctrlsf#opt#GetOpt("_vimregex"))
        if mat_idx != -1
            let match = {
                \ 'lnum'  : line_obj.lnum,
                \ 'vlnum' : line_obj.vlnum,
                \ 'col'   : mat_idx + 1,
                \ 'vcol'  : mat_idx + 1 + ctrlsf#view#Indent()
                \ }
            let line_obj.match = match
        endif

        " copy created line object to an existing line or insert it as new
        if i < orig_count
            call ctrlsf#utils#Mirror(a:orig.lines[i], line_obj)
            let a:buffer[ln-1] = line_obj.content
        else
            call add(a:orig.lines, line_obj)
            call insert(a:buffer, line_obj.content, ln-1)
        endif
    endfo

    " remove deleted lines from paragraph
    if orig_count > modi_count
        for i in range(orig_count-1, modi_count, -1)
            let ln = start_lnum + i + a:offset
            call remove(a:orig.lines, i)
            call remove(a:buffer, ln-1)
        endfo
    endif

    return modi_count - orig_count
endf

" s:SaveFile()
"
func! s:SaveFile(orig, modi) abort
    let file = a:orig.file

    try
        let buffer = readfile(file)
    catch
        call ctrlsf#log#Error("Failed to open file %s", file)
        return -1
    endtry

    " if file is changed after searching thus shows differences against
    " resultset, skip writing and warn user.
    if !s:VerifyConsistent(buffer, a:orig)
        call ctrlsf#log#Error("File %s has been changed from last search. Skip
            \ this file. Please run :CtrlsfUpdate to update your search result."
            \ , file)
        return -1
    endif

    let i = 0
    let offset = 0
    while i < len(a:orig.paragraphs)
        let opar = a:orig.paragraphs[i]
        let mpar = a:modi.paragraphs[i]
        let i += 1

        let offset += s:WriteParagraph(buffer, opar, mpar, offset)
    endwh

    if writefile(buffer, file) == -1
        call ctrlsf#log#Error("Failed to write file %s", file)
    else
        call ctrlsf#log#Debug("Writing file %s succeed.", file)
    endif
endf

" Save()
"
func! ctrlsf#edit#Save()
    let orig = ctrlsf#db#FileSet()
    let modi = ctrlsf#view#Derender(getline(0, '$'))

    " clear cache (not very clean code I should say)
    call ctrlsf#db#ClearCache()

    let changed = s:Diff(orig, modi)

    " prompt to confirm save
    if g:ctrlsf_confirm_save
        let mes = printf("%s files will be saved. Confirm? (Y/n)", len(changed))
        let confirm = input(mes) | redraw
        if !(confirm ==? 'y' || confirm ==? '')
            call ctrlsf#log#Info("Cancelled.")
            return -1
        endif
    endif

    if len(changed) == 0
        call ctrlsf#log#Warn("No file has been changed.")
        return -1
    endif

    let [saved, skipped] = [0, 0]
    for file in changed
        if s:SaveFile(file.orig, file.modi) > -1
            let saved += 1
        else
            let skipped += 1
        endif
    endfo

    " reset 'modified' flag
    setl nomodified

    call ctrlsf#log#Info("Saved: %s files. Skipped: %s files.", saved, skipped)

    return len(changed)
endf
