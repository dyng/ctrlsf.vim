if exists('b:current_syntax')
    finish
endif

syntax case match
syntax match ctrlsfeFilename    /^.*\ze:$/
syntax match ctrlsfeLnumMatch   /^\d\+:/
syntax match ctrlsfeLnumUnmatch /^\d\+-/
syntax match ctrlsfeCuttingLine /^\.\+$/

hi def link ctrlsfeFilename     Label
hi def link ctrlsfeMatch        Identifier
hi def link ctrlsfeLnumMatch    CursorLineNr
hi def link ctrlsfeLnumUnmatch  LineNr

let b:current_syntax = 'ctrlsfe'
