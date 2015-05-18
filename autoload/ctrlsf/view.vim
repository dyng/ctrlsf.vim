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
    let out = a:line.lnum . (a:line.matched ? ':' : '-')
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

            if line.matched
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
