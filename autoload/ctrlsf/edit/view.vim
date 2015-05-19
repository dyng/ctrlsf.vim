" Render()
"
" Share the same view with result buffer currently
"
func! ctrlsf#edit#view#Render() abort
    return ctrlsf#view#Render()
endf

" s:DerenderParagraph()
"
func! s:DerenderParagraph(buffer, file) abort
    let paragraph = {
        \ 'file': a:file,
        \ 'lines': [],
        \ }

    let indent = ctrlsf#view#Indent()

    for line in a:buffer
        call add(paragraph.lines, {
            \ 'content': strpart(line, indent),
            \ })
    endfo

    return paragraph
endf

" Derender()
"
func! ctrlsf#edit#view#Derender(content) abort
    let lines = type(a:content) == 3 ? a:content : split(a:content, "\n")

    let fileset = []

    let current_file = ''
    let next_file    = ''

    let i = 0
    while i < len(lines)
        let buffer = []

        while i < len(lines)
            let line = lines[i]
            let i += 1

            if line ==# '....' || line ==# ''
                break
            elseif line !~ '\v^\d+[:-]'
                " strip trailing colon
                let next_file = substitute(line, ':$', '', '')
                break
            else
                call add(buffer, line)
            endif
        endwh

        if len(buffer) > 0
            let paragraph = s:DerenderParagraph(buffer, current_file)

            " if derender failed, throw an exception
            if empty(paragraph.file)
                throw 'BrokenBufferException'
            endif

            if len(fileset) > 0 && fileset[-1].file ==# paragraph.file
                call add(fileset[-1].paragraphs, paragraph)
            else
                call add(fileset, {
                    \ 'file': paragraph.file,
                    \ 'paragraphs': [ paragraph ],
                    \ })
            endif
        endif

        let current_file = next_file
    endwh

    return fileset
endf
