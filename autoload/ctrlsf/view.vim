" ============================================================================
" Description: An ack/ag/pt powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.7.2
" ============================================================================

func! s:Summary(resultset) abort
    let files   = len(ctrlsf#db#FileResultSet())
    let matches = len(ctrlsf#db#MatchList())
    return [printf("%s matched lines across %s files", matches, files)]
endf

func! s:Filename(paragraph) abort
    " empty line + filename
    return ["", a:paragraph.filename . ":"]
endf

func! s:Ellipsis() abort
    return [repeat(".", 4)]
endf

func! s:Line(line) abort
    let out = a:line.lnum . (a:line.matched() ? ':' : '-')
    let out .= repeat(' ', ctrlsf#view#Indent() - len(out))
    let out .= a:line.content
    return [out]
endf

func! ctrlsf#view#Indent() abort
    let maxlnum = ctrlsf#db#MaxLnum()
    return strlen(string(maxlnum)) + 1 + g:ctrlsf_indent
endf

" Render()
"
" Return rendered view of current resultset.
"
func! ctrlsf#view#Render() abort
    let resultset = ctrlsf#db#ResultSet()
    let cur_file = ''

    let view = []

    " append summary
    call extend(view, s:Summary(resultset))

    for par in resultset
        if cur_file !=# par.filename
            let cur_file = par.filename
            call extend(view, s:Filename(par))
        else
            call extend(view, s:Ellipsis())
        endif

        for line in par.lines
            call extend(view, s:Line(line))

            let line.vlnum = len(view)

            if line.matched()
                let line.match.vlnum = len(view)
                let line.match.vcol  = line.match.col + ctrlsf#view#Indent()
            endif
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
" [file, line, {}]    if corresponding line doesn't contains any match
" ['', {}, {}]        if no corresponding line is found
"
func! ctrlsf#view#Reflect(vlnum) abort
    let resultset = ctrlsf#db#ResultSet()

    let ret = s:BSearch(resultset, 0, len(resultset) - 1, a:vlnum)
    call ctrlsf#log#Debug("Reflect: vlnum: %s, result: %s", a:vlnum, string(ret))

    return ret
endf

func! s:BSearch(resultset, left, right, vlnum) abort
    " case: not found
    if a:left > a:right
        return ['', {}, {}]
    endif

    let pivot = (a:left + a:right) / 2
    let par = a:resultset[pivot]

    " case: less than pivot
    if a:vlnum < par.vlnum()
        return s:BSearch(a:resultset, a:left, pivot - 1, a:vlnum)
    endif

    " case: greater than pivot
    if a:vlnum > par.vlnum() + par.range() - 1
        return s:BSearch(a:resultset, pivot + 1, a:right, a:vlnum)
    endif

    " case: found
    let ret = ['', {}, {}]

    " fetch file
    let ret[0] = par.filename

    " fetch line object
    let line = par.lines[a:vlnum - par.vlnum()]
    let ret[1] = line

    " fetch match object
    if line.matched()
        let ret[2] = line.match
    endif

    return ret
endf

" FindNextMatch()
"
" Find next match. Wrapping around or not depends on value of 'wrapscan'.
"
" Parameters
" {vlnum}   the line number of search base
" {forward} true or false
"
" Returns
" [vlnum, vcol] line number and column number of next match
"
func! ctrlsf#view#FindNextMatch(vlnum, forward) abort
    let regex = ctrlsf#pat#MatchPerLineRegex()
    let flag  = a:forward ? 'n' : 'nb'
    return searchpos(regex, flag)
endf

" Derender()
"
" Return a ResultSet which is derendered from {content}.
"
func! ctrlsf#view#Derender(content) abort
    let lines  = type(a:content) == 3 ? a:content : split(a:content, "\n")
    let orig   = ctrlsf#db#ResultSet()
    let indent = ctrlsf#view#Indent()

    let resultset = []

    let current_file = ''
    let next_file    = ''
    let offset       = 0
    let base_lnum    = -1

    let i = 0
    while i < len(lines)
        let buffer = []

        if len(resultset) >= len(orig)
            throw 'BrokenBufferException'
        endif
        let orig_para = orig[len(resultset)]
        let base_lnum = orig_para.lnum()

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
                let lnum = base_lnum + len(buffer) + offset
                let content = strpart(line, indent)
                call add(buffer, [current_file, lnum, content])
            endif
        endwh

        if len(buffer) > 0
            let paragraph = ctrlsf#class#paragraph#New(buffer)

            " if derender failed, throw an exception
            if empty(paragraph.filename) || empty(paragraph.lines)
                throw 'BrokenBufferException'
            endif

            let offset += paragraph.range() - orig_para.range()

            call add(resultset, paragraph)
        endif

        " file boundary
        if next_file !=# current_file
            let offset = 0
            let current_file = next_file
        endif
    endwh

    return resultset
endf
