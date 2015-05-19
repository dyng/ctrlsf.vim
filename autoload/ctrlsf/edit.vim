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
    let common_part = min([len(a:orig.lines), len(a:modi.lines)])
    for i in range(common_part)
        let ln = a:orig.lnum + i - 1 + a:offset
        let a:buffer[ln] = a:modi.lines[i].content
    endfo

    if len(a:orig.lines) > common_part
        for i in range(common_part, len(a:orig.lines) - 1)
            let ln = a:orig.lnum + i - 1 + a:offset
            call remove(a:buffer, ln)
        endfo
    endif

    if len(a:modi.lines) > common_part
        for i in range(common_part, len(a:modi.lines) - 1)
            let ln = a:orig.lnum + i - 1 + a:offset
            call insert(a:buffer, a:modi.lines[i].content, ln)
        endfo
    endif

    return len(a:modi.lines) - len(a:orig.lines)
endf

" s:SaveFile()
"
func! s:SaveFile(orig, modi) abort
    let file = a:orig.file

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

" Open()
"
func! ctrlsf#edit#Open()
    call ctrlsf#edit#win#OpenEditMode()

    let content = ctrlsf#edit#view#Render()
    call ctrlsf#buf#WriteString(content)

    call cursor(1, 1)
endf

" Save()
"
func! ctrlsf#edit#Save()
    let orig = ctrlsf#db#FileSet()
    let modi = ctrlsf#edit#view#Derender(getline(0, '$'))

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

" Quit()
"
func! ctrlsf#edit#Quit()
    call ctrlsf#edit#win#QuitEditMode()
endf
