func! s:Summary(resultset) abort
    let files   = len(ctrlsf#db#FileSet())
    let matches = len(ctrlsf#db#Matchlist())
    return [printf("%s matched lines across %s files", matches, files)]
endf

func! s:Filename(paragraph) abort
    " empty line + filename
    return ["", a:paragraph.file . ":"]
endf

func! s:Ellipsis() abort
    return [repeat(".", 4)]
endf

func! s:Line(line) abort
    let out = a:line.lnum . (a:line.matched ? ':' : '-')
    let out .= repeat(' ', g:ctrlsf_leading_space - len(out)) . a:line.content
    return [out]
endf

" Render()
"
func! ctrlsf#view#Render() abort
    let resultset = ctrlsf#db#ResultSet()
    let cur_file = ''

    let view = []

    " append summary
    call extend(view, s:Summary(resultset))

    for par in resultset
        if cur_file !=# par.file
            let cur_file = par.file
            call extend(view, s:Filename(par))
        else
            call extend(view, s:Ellipsis())
        endif

        " save line number in view (vlnum of the first line)
        let par.vlnum = len(view) + 1

        for line in par.lines
            call extend(view, s:Line(line))
            let line.vlnum = len(view)
        endfo
    endfo

    return join(view, "\n")
endf

" Reflect()
"
" Find resultset which is corresponding the given line.
"
" Parameters
" {vlnum} number of a line within rendered view
"
" Returns
" [file, line, match] if corresponding line contains one or more matches
" [file, line, {}]    if corresponding line does not contains match
" [{}, {}, {}]        if no corresponding line is found
"
func! ctrlsf#view#Reflect(vlnum) abort
    let resultset = ctrlsf#db#ResultSet()

    let ret = [{}, {}, {}]
    for par in resultset
        if a:vlnum < par.vlnum
            break
        endif

        " if there is a corresponding line
        if a:vlnum <= par.vlnum + par.range - 1
            " fetch file
            let ret[0] = par.file

            " fetch line object
            let line = par.lines[a:vlnum - par.vlnum]
            let ret[1] = line

            " fetch match object
            if line.matched
                let ret[2] = line.match
            endif

            break
        endif
    endfo

    return ret
endf
