" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

let s:rendered_par = 0
let s:rendered_line = 0
let s:rendered_match = 0
let s:cur_file = ''
let s:procbar_dots = 0

func! s:Summary(procbar) abort
    let files   = len(ctrlsf#db#FileResultSet())
    let matches = len(ctrlsf#db#MatchList())
    if a:procbar == 100
        return [printf("%s matched lines across %s files. Done!", matches, files)]
    elseif a:procbar == 0
        return [printf("%s matched lines across %s files.", matches, files)]
    elseif a:procbar == -1
        return [printf("%s matched lines across %s files. Cancelled.", matches, files)]
    else
        return [printf("%s matched lines across %s files. Searching%s", matches, files, repeat('.', a:procbar))]
    endif
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

func! s:MatchLine(match) abort
    let out = printf("%s|%s col %s| %s",
                \ a:match.filename,
                \ a:match.lnum,
                \ a:match.col,
                \ a:match.text)
    return [out]
endf

" ctrlsf#view#Indent()
"
func! ctrlsf#view#Indent() abort
    let maxlnum = ctrlsf#db#MaxLnum()
    return strlen(string(maxlnum)) + 1 + g:ctrlsf_indent
endf

" Reset()
"
" Reset all states of this module.
"
func! ctrlsf#view#Reset() abort
    let s:rendered_par = 0
    let s:rendered_line = 0
    let s:rendered_match = 0
    let s:cur_file = ''
    let s:procbar_dots = 0
endf

" Render()
"
" Return rendered view of current resultset.
"
" Returns:
" Text of rendered view
"
func! ctrlsf#view#Render() abort
    call ctrlsf#view#Reset()
    if ctrlsf#CurrentMode() ==# 'normal'
        return s:NormalView()
    else
        return s:CompactView()
    endif
endf

" RenderIncr()
"
" Render incrementally.
"
" Returns:
" Text of rendered view to append
"
func! ctrlsf#view#RenderIncr() abort
    if ctrlsf#CurrentMode() ==# 'normal'
        return s:NormalViewIncr()
    else
        return s:CompactViewIncr()
    endif
endf

" RenderSummary()
"
" Render a summary.
"
func! ctrlsf#view#RenderSummary() abort
    if g:ctrlsf_search_mode ==# 'sync'
        return join(s:Summary(0), "\n")
    else
        if ctrlsf#async#IsSearching()
            let s:procbar_dots = s:procbar_dots % 3 + 1
            return join(s:Summary(s:procbar_dots), "\n")
        elseif ctrlsf#async#IsCancelled()
            return join(s:Summary(-1), "\n")
        else
            return join(s:Summary(100), "\n")
        endif
    endif
endf

" s:NormalViewIncr()
"
func! s:NormalViewIncr() abort
    let resultset = ctrlsf#db#ResultSet()
    let to_render = resultset[s:rendered_par:-1]

    let view = []

    for par in to_render
        if s:cur_file !=# par.filename
            let s:cur_file = par.filename
            call extend(view, s:Filename(par))
        else
            call extend(view, s:Ellipsis())
        endif

        for line in par.lines
            call extend(view, s:Line(line))

            let line.vlnum = s:rendered_line + len(view) + 1

            if line.matched()
                let line.match.vlnum = line.vlnum
                let line.match.vcol  = line.match.col + ctrlsf#view#Indent()
            endif
        endfo
    endfo

    let s:rendered_par = s:rendered_par + len(to_render)
    let s:rendered_line = s:rendered_line + len(view)

    return view
endf

" s:CompactViewIncr()
"
func! s:CompactViewIncr() abort
    let matchlist = ctrlsf#db#MatchList()
    let to_render = matchlist[s:rendered_match:-1]

    let view = []

    for mat in to_render
        call extend(view, s:MatchLine(mat))
    endfo

    let s:rendered_match = s:rendered_match + len(to_render)

    return view
endf

" s:NormalView()
"
func! s:NormalView() abort
    let summary = ctrlsf#view#RenderSummary()
    let body = join(s:NormalViewIncr(), "\n")
    return summary . "\n" . body
endf

" s:CompactView()
"
func! s:CompactView() abort
    return join(s:CompactViewIncr(), "\n")
endf

" Locate()
"
" Find resultset which is corresponding the given line.
"
" Parameters:
" {vlnum} number of a line within rendered view
"
" Returns:
" [file, line, match] if corresponding line contains one or more matches
" [file, line, {}]    if corresponding line doesn't contains any match
" ['', {}, {}]        if no corresponding line is found
"
func! ctrlsf#view#Locate(vlnum) abort
    if ctrlsf#CurrentMode() ==# 'normal'
        return s:LocateNormalView(a:vlnum)
    else
        return s:LocateCompactView(a:vlnum)
    endif
endf

" s:LocateCompactView()
"
func! s:LocateCompactView(vlnum) abort
    let matchlist = ctrlsf#db#MatchList()
    let match = get(matchlist, a:vlnum-1, {})
    if !empty(match)
        let line = ctrlsf#class#line#New(match.filename, match.lnum, match.text)
        return [match.filename, line, match]
    else
        return ['', {}, {}]
    endif
endf

" s:LocateNormalView()
"
func! s:LocateNormalView(vlnum) abort
    let resultset = ctrlsf#db#ResultSet()
    return s:BSearch(resultset, 0, len(resultset) - 1, a:vlnum)
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
" Find next match.
"
" Parameters:
" {forward} true or false
" {wrapscan} true or false
"
" Returns:
" [vlnum, vcol] line number and column number of next match
"
func! ctrlsf#view#FindNextMatch(forward, wrapscan) abort
    let regex = ctrlsf#pat#MatchPerLineRegex(ctrlsf#CurrentMode())
    let flag  = a:forward ? 'n' : 'nb'
    let flag .= a:wrapscan ? 'w' : 'W'
    return searchpos(regex, flag)
endf

" Unrender()
"
" Return a 'ResultSet' which is unrendered from {content}.
"
func! ctrlsf#view#Unrender(content) abort
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
            elseif line !~ '\v^\d+[:-]\s{2,}'
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
