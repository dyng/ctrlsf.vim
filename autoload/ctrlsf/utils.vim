" BinarySearch()
"
" Search for the maximum number in 'array' that less or equal to 'key'.
"
func! ctrlsf#utils#BinarySearch(array, imin, imax, key)
    let array = a:array | let key  = a:key
    let imax  = a:imax  | let imin = a:imin

    let ret = -1
    while (imax >= imin)
        let imid = (imax + imin) / 2

        if array[imid] < key
            let ret = imid
            let imin = imid + 1
        elseif array[imid] > key
            let imax = imid - 1
        else
            let ret = imid | break
        endif
    endwh

    return ret
endf
