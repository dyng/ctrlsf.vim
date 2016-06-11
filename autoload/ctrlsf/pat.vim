" ============================================================================
" Description: An ack/ag/pt powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.7.2
" ============================================================================

" s:TranslateRegex()
"
" Translate perl-regex to vim-regex.
"
func! s:TranslateRegex(pattern) abort
    let pattern = a:pattern

    " escape '@' and '%' (plain in perl regex but special in vim regex)
    let pattern = escape(pattern, '@%')

    " non-capturing group
    let pattern = substitute(pattern, '\v\(\?:(.{-})\)', '%(\1)', 'g')

    " case sensitive
    let pattern = substitute(pattern, '\V(?i)', '\c', 'g')
    let pattern = substitute(pattern, '\V(?-i)', '\C', 'g')

    " minimal matching
    let pattern = substitute(pattern, '\V*?', '{-}', 'g')
    let pattern = substitute(pattern, '\V+?', '{-1,}', 'g')
    let pattern = substitute(pattern, '\V??', '{-0,1}', 'g')
    let pattern = substitute(pattern, '\m{\(.\{-}\)}?', '{-\1}', 'g')

    " zero-length matching
    let pattern = substitute(pattern, '\v\(\?\=(.{-})\)', '(\1)@=', 'g')
    let pattern = substitute(pattern, '\v\(\?!(.{-})\)', '(\1)@!', 'g')
    let pattern = substitute(pattern, '\v\(\?\<\=(.{-})\)', '(\1)@<=', 'g')
    let pattern = substitute(pattern, '\v\(\?\<!(.{-})\)', '(\1)@<!', 'g')
    let pattern = substitute(pattern, '\v\(\?\>(.{-})\)', '(\1)@>', 'g')

    " '\b' word boundary
    let pattern = substitute(pattern, '\\b', '(<|>)', 'g')

    " TODO:'\B' support

    return pattern
endf

" Regex()
"
func! ctrlsf#pat#Regex() abort
    let pattern = ctrlsf#opt#GetOpt('pattern')

    " ignore case
    let case_sensitive = ctrlsf#opt#GetCaseSensitive()
    let case = ''
    if case_sensitive ==# 'ignorecase'
        let case = '\c'
    elseif case_sensitive ==# 'matchcase'
        let case = '\C'
    else "smartcase
        let pat  = ctrlsf#opt#GetOpt('pattern')
        let case = (pat =~# '\u') ? '\C' : '\c'
    endif

    " magic
    let magic = ctrlsf#opt#GetRegex() ? '\v' : '\V'

    " literal
    if ctrlsf#opt#GetRegex()
        let pattern = s:TranslateRegex(pattern)
    else
        let pattern = escape(pattern, '\')
    endif

    return printf('%s%s%s', magic, case, pattern)
endf

" HighlightRegex()
"
func! ctrlsf#pat#HighlightRegex() abort
    let base = ctrlsf#pat#Regex()

    let magic   = strpart(base, 0, 2)
    let case    = strpart(base, 2, 2)
    let pattern = strpart(base, 4)

    " sign (to prevent matching out of file body)
    let sign = ''
    if magic ==# '\v'
        let sign = '(^\d+:.*)@<='
    else
        let sign = '\(\^\d\+:\.\*\)\@<='
    endif

    return printf('%s%s%s%s', magic, case, sign, pattern)
endf

" MatchPerLineRegex()
"
" Regular expression to match the matched word. Difference from HighlightRegex()
" is that this pattern only matches the first matched word in each line.
"
func! ctrlsf#pat#MatchPerLineRegex() abort
    let base = ctrlsf#pat#Regex()

    let magic   = strpart(base, 0, 2)
    let case    = strpart(base, 2, 2)
    let pattern = strpart(base, 4)

    " sign (to prevent matching out of file body)
    let sign = ''
    if magic ==# '\v'
        let sign = '^\d+:.{-}\zs'
    else
        let sign = '\^\d\+:\.\{-}\zs'
    endif

    return printf('%s%s%s%s', magic, case, sign, pattern)
endf
