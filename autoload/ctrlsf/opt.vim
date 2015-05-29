" ============================================================================
" File: after/plugin/ctrlsf.vim
" Description: An ack/ag powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 1.00
" ============================================================================

" option list of CtrlSF
let s:option_list = {
    \ '-after'      : {'args': 1},
    \ '-before'     : {'args': 1},
    \ '-context'    : {'args': 1},
    \ '-filetype'   : {'args': 1},
    \ '-ignorecase' : {'args': 0},
    \ '-matchcase'  : {'args': 0},
    \ '-regex'      : {'args': 0},
    \ '-smartcase'  : {'args': 0},
    \ '-A': {'fullname': '-after'},
    \ '-B': {'fullname': '-before'},
    \ '-C': {'fullname': '-context'},
    \ '-I': {'fullname': '-ignorecase'},
    \ '-R': {'fullname': '-regex'},
    \ '-S': {'fullname': '-matchcase'},
    \ }

" default values to options
let s:default = {
    \ 'regex'      : g:ctrlsf_regex_pattern,
    \ 'filetype'   : '',
    \ 'pattern'    : '',
    \ 'path'       : [],
    \ }

" options
let s:options = {}

" OptionKeys()
"
" Return ALL available options. It's useful for completion functions.
"
func! ctrlsf#opt#OptionKeys() abort
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
        if a:name ==# 'after' || a:name ==# 'before' || a:name ==# 'context'
            return s:DefaultContext(a:name)
        else
            return s:default[a:name]
        endif
    endif
endf

let s:context_config = { 'config': '' }
func! s:DefaultContext(name) abort
    if g:ctrlsf_context ==# s:context_config.config
        return get(s:context_config, a:name, -1)
    endif

    let s:context_config['config'] = g:ctrlsf_context

    let parsed = s:ParseOptions(s:context_config['config'])
    let s:context_config['after']   = get(parsed, 'after', -1)
    let s:context_config['before']  = get(parsed, 'before', -1)
    let s:context_config['context'] = get(parsed, 'context', -1)

    return s:context_config[a:name]
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

    " default
    if empty(options)
        for opt in ['after', 'before', 'context']
            if ctrlsf#opt#GetOpt(opt) > 0
                let options[opt] = ctrlsf#opt#GetOpt(opt)
            endif
        endfo
    endif

    return options
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
                    \ from pre-v1.0, plaese be aware of CtrlSF v1.0 no longer
                    \ supports all options of ack and ag. Read manual for
                    \ CtrlSF its own options.", token)
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
