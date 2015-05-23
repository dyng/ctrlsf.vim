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

        if len(opar.lines) != len(mpar.lines)
            return 1
        endif

        let j = 0
        while j < len(opar.lines)
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

" s:WriteParagraph()
"
func! s:WriteParagraph(buffer, orig, modi, offset)
    let orig_count  = len(a:orig.lines)
    let modi_count  = len(a:modi.lines)
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

        let mat_idx = match(line_obj.content, ctrlsf#pat#Regex())
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

    " FIXME: if file is modified externally, then loaded file content is
    " different from that in resultset
    try
        let buffer = readfile(file)
    catch
        call ctrlsf#log#Error("Failed to open file %s", file)
        return
    endtry

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

    if len(changed) == 0
        call ctrlsf#log#Warn("No file has been changed.")
        return 0
    endif

    for file in changed
        call s:SaveFile(file.orig, file.modi)
    endfo

    " reset 'modified' flag
    setl nomodified

    call ctrlsf#log#Info("%s files have been saved.", len(changed))
endf
