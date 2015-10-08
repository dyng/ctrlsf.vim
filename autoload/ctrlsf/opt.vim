" ============================================================================
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.32
" ============================================================================

" option list of CtrlSF
let s:option_list = {
    \ '-after'      : {'args': 1},
    \ '-before'     : {'args': 1},
    \ '-context'    : {'args': 1},
    \ '-filetype'   : {'args': 1},
    \ '-ignorecase' : {'args': 0},
    \ '-literal'    : {'args': 0},
    \ '-matchcase'  : {'args': 0},
    \ '-regex'      : {'args': 0},
    \ '-smartcase'  : {'args': 0},
    \ '-A': {'fullname': '-after'},
    \ '-B': {'fullname': '-before'},
    \ '-C': {'fullname': '-context'},
    \ '-I': {'fullname': '-ignorecase'},
    \ '-L': {'fullname': '-literal'},
    \ '-R': {'fullname': '-regex'},
    \ '-S': {'fullname': '-matchcase'},
    \ }

" default values to options
let s:default = {
    \ 'filetype'   : '',
    \ 'pattern'    : '',
    \ 'path'       : [],
    \ }

" options
let s:options = {}

" OptionNames()
"
" Return ALL available options. It's useful for completion functions.
"
func! ctrlsf#opt#OptionNames() abort
    return keys(s:option_list)
endf

" IsOptGiven()
"
" Return whether user has given a specific option
"
func! ctrlsf#opt#IsOptGiven(name) abort
    return has_key(s:options, a:name)
endf

" GetOpt()
"
" Return option {name}, if not exists, return default value
"
func! ctrlsf#opt#GetOpt(name) abort
    if has_key(s:options, a:name)
        return s:options[a:name]
    else
        return get(s:default, 'a:name', '')
    endif
endf

" GetContext()
"
" Return a dict contains 'after', 'before' and/or 'context'
"
func! ctrlsf#opt#GetContext() abort
    let options = {}

    " user specific
    for opt in ['after', 'before', 'context']
        if ctrlsf#opt#IsOptGiven(opt)
            let options[opt] = ctrlsf#opt#GetOpt(opt)
        endif
    endfo

    " if no user specific context, use default context
    if empty(options)
        return s:DefaultContext()
    endif

    return options
endf

let s:default_context = { 'conf': '', 'ctx': {} }
func! s:DefaultContext() abort
    " if g:ctrlsf_context is not changed since last search, then return cached
    " result.
    if g:ctrlsf_context ==# s:default_context.conf
        return s:default_context.ctx
    endif

    let s:default_context['conf'] = g:ctrlsf_context
    let s:default_context['ctx']  = s:ParseOptions(g:ctrlsf_context)

    return s:default_context.ctx
endf

" GetCaseSensitive()
"
" Return 'smartcase', 'ignorecase' or 'matchcase'.
"
" If two or more flags are given at the same time, preferred by priority
"
"   'matchcase' > 'ignorecase' > 'smartcase'
"
func! ctrlsf#opt#GetCaseSensitive() abort
    for opt in ['matchcase', 'ignorecase', 'smartcase']
        if ctrlsf#opt#IsOptGiven(opt)
            return opt
        endif
    endfo

    " default
    return {
        \'smart' : 'smartcase',
        \'yes'   : 'matchcase',
        \'no'    : 'ignorecase',
        \}[g:ctrlsf_case_sensitive]
endf

" GetRegex()
"
" Return 1 or 0.
"
" If both of 'literal' and 'regex' are given, prefer 'literal' than 'regex'.
"
func! ctrlsf#opt#GetRegex() abort
    if ctrlsf#opt#IsOptGiven('literal')
        return 0
    elseif ctrlsf#opt#IsOptGiven('regex')
        return 1
    else
        return g:ctrlsf_regex_pattern
    endif
endf

"""""""""""""""""""""""""""""""""
" Option Parsing
"""""""""""""""""""""""""""""""""

" s:ParseOptions()
"
" Create a dict contains parsed options
"
func! s:ParseOptions(options_str) abort
    let options = {}
    let tokens  = ctrlsf#lex#Tokenize(a:options_str)

    let i = 0
    while i < len(tokens)
        let token = tokens[i]
        let i += 1

        if !has_key(s:option_list, token)
            if token =~# '^-'
                call ctrlsf#log#Error("Unknown option '%s'. If you are user
                    \ from pre-v1.0, plaese be aware of that CtrlSF no longer
                    \ supports all options of ack and ag since v1.0. Read
                    \ manual for CtrlSF its own options.", token)
                throw 'ParseOptionsException'
            endif

            " resolve to PATTERN and PATH
            if !has_key(options, 'pattern')
                let options['pattern'] = token
            else
                if !has_key(options, 'path')
                    let options['path'] = []
                endif
                call add(options['path'], token)
            endif

            continue
        endif

        let name = strpart(token, 1)
        let opt  = s:option_list[token]
        if has_key(opt, 'fullname')
            let name = strpart(opt.fullname, 1)
            let opt  = s:option_list[opt.fullname]
        endif

        if opt.args == 0
            let options[name] = 1
        elseif opt.args == 1
            if tokens[i] =~# '\d\+'
                let options[name] = str2nr(tokens[i])
            else
                let options[name] = tokens[i]
            endif

            let i += 1
        else
            let argv = []
            for j in range(opt.args)
                call add(argv, tokens[i])
                let i += 1
            endfo

            let options[name] = argv
        endif
    endwh

    call ctrlsf#log#Debug("ParsedResult: %s", string(options))
    return options
endf

" ParseOptions()
"
func! ctrlsf#opt#ParseOptions(options_str) abort
    let s:options = s:ParseOptions(a:options_str)

    " derivative options

    " vimregex
    let s:options["_vimregex"] = ctrlsf#pat#Regex()

    " vimhlregex
    let s:options["_vimhlregex"] = ctrlsf#pat#HighlightRegex()

    call ctrlsf#log#Debug("Options: %s", string(s:options))
endf
