" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

func! s:Summary(resultset) abort
    let files   = len(ctrlsf#db#FileSet())
    let matches = len(ctrlsf#db#MatchList())
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
        if cur_file !=# par.file
            let cur_file = par.file
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

    " TODO: use binary search for better performance
    let ret = ['', {}, {}]
    for par in resultset
        if a:vlnum < par.vlnum()
            break
        endif

        " if there is a corresponding line
        if a:vlnum <= par.vlnum() + par.range() - 1
            " fetch file
            let ret[0] = par.file

            " fetch line object
            let line = par.lines[a:vlnum - par.vlnum()]
            let ret[1] = line

            " fetch match object
            if line.matched()
                let ret[2] = line.match
            endif

            break
        endif
    endfo

    call ctrlsf#log#Debug("Reflect: vlnum: %s, result: %s", a:vlnum, string(ret))
    return ret
endf

" FindNextMatch()
"
" Find next match.
"
" Parameters
" {vlnum}   the line number of search base
" {forward} true or false
"
" Returns
" [vlnum, vcol] line number and column number of next match
"
func! ctrlsf#view#FindNextMatch(vlnum, forward) abort
    let matchlist = ctrlsf#db#MatchList()

    if empty(matchlist)
        return [-1, -1]
    endif

    let [lp, rp] = [0, len(matchlist) - 1]

    " when vlnum is out of range [0, len]
    if a:vlnum < matchlist[lp].vlnum
        let rp = lp
        let lp = -1
    elseif a:vlnum > matchlist[rp].vlnum
        let lp = rp
        let rp = -1
    else
        " main binary search
        while rp - lp > 1
            let mp    = (lp + rp) / 2
            let pivot = matchlist[mp]

            if matchlist[mp].vlnum == a:vlnum
                let lp = (mp == 0) ? -1 : mp - 1
                let rp = (mp == len(matchlist) - 1) ? -1 : mp + 1
                break
            elseif matchlist[mp].vlnum < a:vlnum
                let lp = mp
            else
                let rp = mp
            endif
        endwh
    endif

    let nextp = a:forward ? rp : lp

    if nextp == -1
        return [-1, -1]
    else
        return [matchlist[nextp].vlnum, matchlist[nextp].vcol]
    endif
endf

" s:DerenderParagraph()
"
func! s:DerenderParagraph(buffer, file) abort
    let paragraph = {
        \ 'file'    : a:file,
        \ 'lnum'    : function("ctrlsf#class#paragraph#Lnum"),
        \ 'vlnum'   : function("ctrlsf#class#paragraph#Vlnum"),
        \ 'range'   : function("ctrlsf#class#paragraph#Range"),
        \ 'lines'   : [],
        \ 'matches' : function("ctrlsf#class#paragraph#Matches"),
        \ }

    let indent = ctrlsf#view#Indent()

    for line in a:buffer
        call add(paragraph.lines, {
            \ 'matched' : function("ctrlsf#class#line#Matched"),
            \ 'match'   : -1,
            \ 'lnum'    : -1,
            \ 'vlnum'   : -1,
            \ 'content': strpart(line, indent),
            \ })
    endfo

    return paragraph
endf

" Derender()
"
" Return a pseudo-fileset which is derendered from {content}.
"
func! ctrlsf#view#Derender(content) abort
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
