" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" s:DiffFile()
"
func! s:DiffFile(orig, modi) abort
    if a:orig.filename !=# a:modi.filename
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
            call ctrlsf#log#Debug("ChangedFile: %s", file_orig.filename)
        endif
    endwh

    return changed_files
endf

" s:TrimPhantomLine()
"
" workaround an issue of ag:
"
" https://github.com/ggreer/the_silver_searcher/issues/685
"
func! s:TrimPhantomLine(buffer, orig) abort
    let tail_par = a:orig.paragraphs[-1]
    let tail_lnum = tail_par.lnum() + tail_par.range() - 1
    if len(a:buffer) <= tail_lnum - 1
        call ctrlsf#log#Debug("Remove phatom line in file: %s", a:orig.filename)
        call tail_par.trim_tail()
    endif
endf

" s:VerifyConsistent()
"
" Check if a file in resultset is different from its disk counterpart.
"
func! s:VerifyConsistent(on_disk, on_mem) abort
    for par in a:on_mem.paragraphs
        for i in range(par.range())
            let ln = par.lnum() + i
            let line = par.lines[i]

            if line.content !=# a:on_disk[ln-1]
                call ctrlsf#log#Debug("InconsistentContent: [Lnum]: %d,
                            \ [FileInMem]: %s, [FileOnDisk]: %s",
                            \ ln, line.content, a:on_disk[ln-1])
                return 0
            endif
        endfo
    endfo

    return 1
endf

" s:WriteParagraph()
"
" Write contents in paragraph to buffer.
"
func! s:WriteParagraph(buffer, orig, modi) abort
    let orig_count  = a:orig.range()
    let modi_count  = a:modi.range()
    let start_lnum  = a:modi.lnum()

    for i in range(modi_count)
        let mline = a:modi.lines[i]
        let ln    = start_lnum + i

        if i < orig_count
            let a:buffer[ln-1] = mline.content
        else
            call insert(a:buffer, mline.content, ln-1)
        endif
    endfo

    " remove deleted lines from paragraph
    if orig_count > modi_count
        for i in range(orig_count-1, modi_count, -1)
            let ln = start_lnum + i
            call remove(a:buffer, ln-1)
        endfo
    endif
endf

" s:SaveFile()
"
func! s:SaveFile(orig, modi) abort
    let file = a:orig.filename

    try
        let buffer = readfile(file)
    catch
        call ctrlsf#log#Error("Failed to open file %s", file)
        return -1
    endtry

    " workaround an issue of ag
    call s:TrimPhantomLine(buffer, a:orig)

    " if file is changed after searching thus shows differences against
    " resultset, skip writing and warn user.
    if !s:VerifyConsistent(buffer, a:orig)
        call ctrlsf#log#Error("File %s has been changed since last search. Skip
            \ this file. Please run :CtrlsfUpdate to update your search result."
            \ , file)
        return -1
    endif

    let i = 0
    while i < len(a:orig.paragraphs)
        let opar = a:orig.paragraphs[i]
        let mpar = a:modi.paragraphs[i]
        let i += 1

        call s:WriteParagraph(buffer, opar, mpar)
    endwh

    " append <CR> to each line when file's format is 'dos'
    if ctrlsf#fs#DetectFileFormat(file) == 'dos'
        for i in range(len(buffer))
            let buffer[i] .= "\r"
        endfo
    endif

    if writefile(buffer, file) == -1
        call ctrlsf#log#Error("Failed to write file %s", file)
    else
        call ctrlsf#log#Debug("WritingFile: %s succeed.", file)
    endif
endf

" Save()
"
func! ctrlsf#edit#Save() abort
    let orig = ctrlsf#db#FileResultSet()
    let rs   = ctrlsf#view#Unrender(getline(0, '$'))
    let modi = ctrlsf#db#FileResultSetBy(rs)

    " check difference and validity
    try
        let changed = s:Diff(orig, modi)
    catch /InconsistentException/
        call ctrlsf#log#Error("CtrlSF's write buffer is corrupted. Note that
                            \ you can't insert line/delete block/delete entire
                            \ file in edit mode.")
        return -1
    endtry

    " prompt to confirm save
    if g:ctrlsf_confirm_save
        call ctrlsf#log#Info(printf("%s files will be saved. Confirm? (Y/n)",
                    \ len(changed)))
        let confirm = nr2char(getchar()) | redraw!
        if !(confirm ==? "y" || confirm ==? "\r")
            call ctrlsf#log#Info("Cancelled.")
            return -1
        endif
    endif

    if len(changed) == 0
        call ctrlsf#log#Warn("No file has been changed.")
        return -1
    endif

    " start saving...
    let [saved, skipped] = [0, 0]
    for file in changed
        if s:SaveFile(file.orig, file.modi) > -1
            let saved += 1
        else
            let skipped += 1
        endif
    endfo

    " update resultset after saving
    call ctrlsf#db#SetResultSet(rs)

    if skipped == 0
        call ctrlsf#log#Info("%s files are saved.", saved)
    else
        call ctrlsf#log#Info("%s files are saved (%s skipped).", saved, skipped)
    endif

    return len(changed)
endf
