" ============================================================================
" Description: An ack/ag/pt/rg powered code search and view tool.
" Author: Ye Ding <dygvirus@gmail.com>
" Licence: Vim licence
" Version: 2.1.2
" ============================================================================

" NextToken()
"
" Return next token of {chars}, which starts from {start}.
"
func! s:NextToken(chars, start) abort
    let buffer      = []
    let state_stack = ['normal']
    let start       = a:start

    while start < len(a:chars)
        let state = state_stack[-1]
        let char  = a:chars[start]
        let start += 1

        " char: [space]
        if char ==# ' '
            if state == 'normal'
                " ignore leading space
                if !empty(buffer)
                    break
                endif
            elseif state == 'escape'
                call add(buffer, char)
                call remove(state_stack, -1)
            else
                call add(buffer, char)
            endif
        " char: "
        elseif char ==# '"'
            if state == 'normal'
                " only quote as first character can start a string
                if empty(buffer)
                    call add(state_stack, 'string_double')
                else
                    call add(buffer, char)
                endif
            elseif state == 'string_single'
                call add(buffer, char)
            elseif state == 'string_double'
                call remove(state_stack, -1)
                break
            elseif state == 'escape'
                call add(buffer, char)
                call remove(state_stack, -1)
            endif
        " char: '
        elseif char ==# "'"
            if state == 'normal'
                " only quote as first character can start a string
                if empty(buffer)
                    call add(state_stack, 'string_single')
                else
                    call add(buffer, char)
                endif
            elseif state == 'string_single'
                call remove(state_stack, -1)
                break
            elseif state == 'string_double'
                call add(buffer, char)
            elseif state == 'escape'
                call add(buffer, char)
                call remove(state_stack, -1)
            endif
        " char: \
        elseif char ==# '\'
            if state == 'normal' || state == 'string_double'
                call add(state_stack, 'escape')
            elseif state == 'string_single'
                call add(buffer, char)
            elseif state == 'escape'
                call add(buffer, char)
                call remove(state_stack, -1)
            endif
        " normal characters
        else
            " if a normal character follows a backslash, then treat that
            " backslash as a plain character
            if state == 'escape'
                call add(buffer, '\')
                call remove(state_stack, -1)
            endif
            call add(buffer, char)
        endif
    endwh

    if len(state_stack) != 1 || state_stack[-1] != 'normal'
        call ctrlsf#log#Error("Unable to parse options: %s. Maybe you forgot
            \ escaping.", string(join(a:chars, '')))
        throw "ParseOptionsException"
    endif

    return [join(buffer, ''), start]
endf

" Tokenize()
"
" Split string into a list of tokens.
"
" Examples:
"
" -I -C 2 path     -> ['-I', '-C', '2', 'path']
" -regex 'foo bar' -> ['-regex', 'foo bar']
" foo\ bar         -> ['foo bar']
"
func! ctrlsf#lex#Tokenize(options_str) abort
    let tokens = []
    let chars  = split(a:options_str, '.\zs')

    let start = 0
    while start < len(chars)
        let [token, start] = s:NextToken(chars, start)
        if !empty(token)
            call add(tokens, token)
        endif
    endwh

    call ctrlsf#log#Debug("Tokens: %s", string(tokens))
    return tokens
endf
