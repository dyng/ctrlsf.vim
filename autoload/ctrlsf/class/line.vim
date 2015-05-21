" Matched()
"
func! ctrlsf#class#line#Matched() abort dict
    return !empty(self.match)
endf
