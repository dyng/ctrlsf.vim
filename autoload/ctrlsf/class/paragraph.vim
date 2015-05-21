" Lnum()
"
func! ctrlsf#class#paragraph#Lnum() abort dict
    return self.lines[0].lnum
endf

" Vlnum()
"
func! ctrlsf#class#paragraph#Vlnum() abort dict
    return self.lines[0].vlnum
endf

" Range()
"
func! ctrlsf#class#paragraph#Range() abort dict
    return len(self.lines)
endf
