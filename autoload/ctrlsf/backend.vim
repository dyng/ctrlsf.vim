" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" Log file that collects error messages from backend
let s:backend_error_log_file = tempname()

let s:backend_args_map = {
    \ 'ag': {
        \ 'ignorecase': {
            \ 'smartcase': '--smart-case',
            \ 'ignorecase': '--ignore-case',
            \ 'matchcase': '--case-sensitive'
            \ },
        \ 'ignoredir': '--ignore-dir',
        \ 'regex': {
            \ '1': '',
            \ '0': '--literal'
            \ },
        \ 'follow': {
            \ '1': '-f',
            \ '0': '--nofollow'
            \ },
        \ 'default': '--noheading --nogroup --nocolor --nobreak'
        \ },
    \ 'ack': {
        \ 'ignorecase': {
            \ 'smartcase': '--smart-case',
            \ 'ignorecase': '--ignore-case',
            \ 'matchcase': '--no-smart-case'
            \ },
        \ 'ignoredir': '--ignore-dir',
        \ 'regex': {
            \ '1': '',
            \ '0': '--literal'
            \ },
        \ 'follow': {
            \ '1': '--follow',
            \ '0': '--nofollow'
            \ },
        \ 'default': '--noheading --nogroup --nocolor --nobreak --nocolumn
            \ --with-filename'
        \ },
    \ 'pt': {
        \ 'ignorecase': {
            \ 'smartcase': '--smart-case',
            \ 'ignorecase': '--ignore-case',
            \ 'matchcase': ''
            \ },
        \ 'ignoredir': '--ignore',
        \ 'regex': {
            \ '1': '-e',
            \ '0': ''
            \ },
        \ 'follow': {
            \ '1': '',
            \ '0': ''
            \ },
        \ 'default': '--nogroup --nocolor'
        \ },
    \ 'rg': {
        \ 'ignorecase': {
            \ 'smartcase': '--smart-case',
            \ 'ignorecase': '--ignore-case',
            \ 'matchcase': ''
            \ },
        \ 'ignoredir': '-g',
        \ 'regex': {
            \ '1': '',
            \ '0': '--fixed-strings'
            \ },
        \ 'follow': {
            \ '1': '--follow',
            \ '0': '--no-follow'
            \ },
        \ 'default': '--no-heading --color never --line-number -H'
        \ }
    \ }

" BuildCommand()
"
func! s:BuildCommand(args, for_shell) abort
    let tokens = []
    let runner = ctrlsf#backend#Runner()

    " add executable file
    call add(tokens, g:ctrlsf_ackprg)

    " If user has specified '-A', '-B' or '-C', then use it without complaint
    " else use the default value 'g:ctrlsf_context'
    let ctx_options = ctrlsf#opt#GetContext()
    let context = ''
    for opt in keys(ctx_options)
        let context .= printf("-%s %s ", toupper(strpart(opt, 0, 1)),
            \ ctx_options[opt])
    endfo
    call add(tokens, context)

    " ignorecase
    let case_sensitive = ctrlsf#opt#GetCaseSensitive()
    let case = s:backend_args_map[runner]['ignorecase'][case_sensitive]
    call add(tokens, case)

    " ignore (dir, file)
    let ignore_dir = ctrlsf#opt#GetIgnoreDir()
    let arg_name = s:backend_args_map[runner]['ignoredir']
    if !empty(arg_name)
        if runner ==# 'rg'
            for dir in ignore_dir
                call add(tokens, arg_name . ' !' . s:Escape(a:for_shell, dir))
            endfor
        else
            for dir in ignore_dir
                call add(tokens, arg_name . ' ' . s:Escape(a:for_shell, dir))
            endfor
        endif
    endif

    " regex
    call add(tokens,
        \ s:backend_args_map[runner]['regex'][ctrlsf#opt#GetRegex()])

    " filetype (NOT SUPPORTED BY ALL BACKEND)
    " support backend: ag, ack, rg
    if !empty(ctrlsf#opt#GetOpt('filetype'))
        if runner ==# 'ag' || runner ==# 'ack'
            call add(tokens, '--' . ctrlsf#opt#GetOpt('filetype'))
        elseif runner ==# 'rg'
            call add(tokens, '--type ' . ctrlsf#opt#GetOpt('filetype'))
        endif
    endif

    if !empty(ctrlsf#opt#GetOpt('word'))
        call add(tokens, '-w')
    endif

    " filematch (NOT SUPPORTED BY ALL BACKEND)
    " support backend: ag, ack, pt, rg
    if !empty(ctrlsf#opt#GetOpt('filematch'))
        if runner ==# 'ag'
            call extend(tokens, [
                \ '--file-search-regex',
                \ s:Escape(a:for_shell, ctrlsf#opt#GetOpt('filematch'))
                \ ])
        elseif runner ==# 'pt'
            call add(tokens, printf("--file-search-regex=%s",
                        \ s:Escape(a:for_shell, ctrlsf#opt#GetOpt('filematch'))))
        elseif runner ==# 'rg'
            call add(tokens, printf("-g %s",
                        \ s:Escape(a:for_shell, ctrlsf#opt#GetOpt('filematch'))))
        elseif runner ==# 'ack'
            " pipe: 'ack -g ${filematch} ${path} |'
            let pipe_tokens = [
                \ g:ctrlsf_ackprg,
                \ '-g',
                \ s:Escape(a:for_shell, ctrlsf#opt#GetOpt('filematch'))
                \ ]
            call extend(pipe_tokens, ctrlsf#opt#GetPath())
            call add(pipe_tokens, '|')

            call insert(tokens, join(pipe_tokens, ' '))
            call add(tokens, '--files-from=-')
        endif
    endif

    " follow symlink
    call add(tokens,
        \ s:backend_args_map[runner]['follow'][g:ctrlsf_follow_symlinks])

    " default
    call add(tokens,
        \ s:backend_args_map[runner]['default'])

    " user custom arguments
    let extra_args = get(g:ctrlsf_extra_backend_args, runner, "")
    if !empty(extra_args)
        call add(tokens, extra_args)
    endif

    " no more flags
    call add(tokens, "--")

    " pattern (including escape)
    call add(tokens, s:Escape(a:for_shell, ctrlsf#opt#GetOpt('pattern')))

    " path
    let path = ctrlsf#opt#GetPath()
    for p in path
        call add(tokens, s:Escape(a:for_shell, p))
    endfo

    return join(tokens, ' ')
endf

" s:Escape()
"
func! s:Escape(for_shell, str)
    return a:for_shell ? shellescape(a:str) : ctrlsf#utils#Quote(a:str)
endf

" Detect()
"
func! ctrlsf#backend#Detect()
    if executable('rg')
        return 'rg'
    endif

    if executable('ag')
        return 'ag'
    endif

    if executable('pt')
        return 'pt'
    endif

    if executable('ack')
        return 'ack'
    endif

    if executable('ack-grep')
        return 'ack-grep'
    endif

    return ''
endf

" Runner()
"
func! ctrlsf#backend#Runner()
    if !exists('g:ctrlsf_ackprg')
        return ''
    elseif g:ctrlsf_ackprg =~# 'ag'
        return 'ag'
    elseif g:ctrlsf_ackprg =~# 'ack'
        return 'ack'
    elseif g:ctrlsf_ackprg =~# 'rg'
        return 'rg'
    elseif g:ctrlsf_ackprg =~# 'pt'
        return 'pt'
    elseif g:ctrlsf_ackprg =~# 'ack-grep'
        return 'ack'
    else
        return ''
    endif
endf

" LastErrors()
"
func! ctrlsf#backend#LastErrors()
    try
        return join(readfile(expand(s:backend_error_log_file)), "\n")
    catch
        call ctrlsf#log#Debug("Exception caught in reading error los: %s",
                    \ v:exception)
        return ""
    endtry
endf

" Run()
"
" Execute backend.
"
" Parameters
" {args} arguments for execution
"
" Returns
" [success/fail, output]
"
func! ctrlsf#backend#Run(args) abort
    let command = s:BuildCommand(a:args, 1)
    call ctrlsf#log#Debug("ExecCommand: %s", command)

    " A windows user reports CtrlSF doesn't work well when 'shelltemp' is
    " turned off. Although I can't reproduce it, I think forcing 'shelltemp'
    " would not do something really bad.
    let shtmp_bak = &shelltemp
    set shelltemp

    let shrd_bak = &shellredir
    let &shellredir='1>%s 2>'.s:backend_error_log_file

    let output = system(command)

    let &shelltemp = shtmp_bak
    let &shellredir = shrd_bak

    if v:shell_error
        let errmsg = ctrlsf#backend#LastErrors()
        if !empty(errmsg)
            return [0, errmsg]
        else
            return [1, output]
        endif
    else
        return [1, output]
    endif
endf

func! ctrlsf#backend#RunAsync(args) abort
    let command = s:BuildCommand(a:args, 0)
    call ctrlsf#log#Debug("ExecCommand: %s", command)

    call ctrlsf#async#StartSearch(command)
    call ctrlsf#log#Notice("Searching...")
endf
