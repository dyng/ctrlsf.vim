# ctrlsf.vim

An ack/ag powered code search and view tool, like ack.vim or `:vimgrep` but together with more context, and let you edit in-place with powerful edit mode.

### Search and Explore

![ctrlsf demo](http://i.imgur.com/NOy8gwj.gif)

### Edit Mode (with [vim-multiple-cursors][7])

![ctrlsf_edit_demo](http://i.imgur.com/xMUm8Ii.gif)

## Features

- Search and display result in a user-friendly view with adjustable context.

- Edit mode which is incredible useful when you are doing refactoring. (Inspired by [vim-ags][6])

- Preview mode for fast exploring.

- Various options for customized search, view and edit.

## Installation

1. Make sure you have [ack][1] or [ag][2] installed.

2. An easy way to install CtrlSF is using a package manager, like [pathogen][3], [vundle][4] or [neobundle][5].

    In vundle:

    ```vim
    Bundle 'dyng/ctrlsf.vim'
    ```

3. Read *Basic Usage* for how to use.

## Basic Usage

1. Run `:CtrlSF [pattern]`, it will split a new window to show search result.

2. Press `Enter` to open corresponding file, or press `q` to quit.

3. Press `p` to explore file in a preview window if you only want a glance.

4. You can edit search result as you like. Whenever you apply a change, you can save your change to actual file by `:w`.

5. If you change your mind after saving, you can always undo it by pressing `u` and saving it again.

6. `:CtrlSFOpen` can reopen CtrlSF window when you have closed CtrlSF window. It is free because it won't invoke a same but new search. A handy command `:CtrlSFToggle` is also available.

## Key Maps

In CtrlSF window:

- `Enter` - Open corresponding file of current line in the window which CtrlSF is launched from.
- `t` - Like `Enter` but open file in a new tab.
- `p` - Like `Enter` but open file in a preview window.
- `O` - Like `Enter` but always leave CtrlSF window opening.
- `T` - Lkie `t` but focus CtrlSF window instead of new opened tab.
- `q` - Quit CtrlSF window.
- `<C-J>` - Move cursor to next match.
- `<C-K>` - Move cursor to previous match.

In preview window:

- `q` - Close preview window.

Some default defined keys may comflict with keys you have been used to when you are editing. But don't worry, you can customize your mapping by setting `g:ctrlsf_mapping`. `:h g:ctrlsf_mapping` for more information.

## Use Your Own Map

There are also some useful maps need to be mentioned.

- `<Plug>CtrlSFPrompt`

    Input `:CtrlSF ` in command line for you, just a handy shortcut.

- `<Plug>CtrlSFVwordPath`

    Input `:CtrlSF foo ` in command line where `foo` is the current visual selected word, waiting for further input.

- `<Plug>CtrlSFVwordExec`

    Like `<Plug>CtrlSFVwordPath`, but execute it immediately.

- `<Plug>CtrlSFCwordPath`

    Input `:CtrlSF foo ` in command line where `foo` is word under the cursor.

- `<Plug>CtrlSFPwordPath`

    Input `:CtrlSF foo ` in command line where `foo` is the last search pattern of vim.

For a full list of maps, please refer to the document.

I strongly recommend you should do some maps for a nicer user experience, because typing 8 characters for every single search is really boring and painful experience. Another reason is that **one of the most useful feature 'Search Visual Selected Word' can be accessed by map only.**

Example:

```
nmap     <C-F>f <Plug>CtrlSFPrompt
vmap     <C-F>f <Plug>CtrlSFVwordPath
vmap     <C-F>F <Plug>CtrlSFVwordExec
nmap     <C-F>n <Plug>CtrlSFCwordPath
nmap     <C-F>p <Plug>CtrlSFPwordPath
nnoremap <C-F>o :CtrlSFOpen<CR>
nnoremap <C-F>t :CtrlSFToggle<CR>
inoremap <C-F>t <Esc>:CtrlSFToggle<CR>
```

## Edit Mode

1. Edit mode is not really a 'mode'. You don't need to press any key to enter edit mode, just edit the result directly.

2. When your editing is done, save it and CtrlSF will ask you for confirmation, 'y' or just enter will make CtrlSF apply those changes to actual files. (You can turn off confirmation by setting `g:ctrlsf_confirm_save` to 0)

3. Undo is the same as regular editing. You just need to press 'u' and save again.

4. Finally I recommend using [vim-multiple-cursors][7] together with edit mode.

### Limitation

- You can modify or delete lines but **you can't insert**. (If it turns out that inserting is really needed, I'll implement it later.)

- If a file's content varies from last search, CtrlSF will refuse to write your changes to that file (for safty concern). As a rule of thumb, invoke a new search before editing, or just run `:CtrlSFUpdate`.

## Arguments

CtrlSF has a lot of arguments you can use in search. Most arguments are similar to Ack/Ag's but not perfectly same. Here are some most frequently used arguments:

- `-R` - Use regular expression pattern.
- `-I`, `-S` - Search case-insensitively (`-I`) or case-sensitively (`-S`).
- `-C`, `-A`, `-B` - Specify how many context lines to be printed, identical to their counterparts in Ag/Ack.

Read `:h ctrlsf-arguments` for a full list of arguments.

### Example

- Search a regular expression pattern case-insensitively:

    ```vim
    :CtrlSF -R -I foo.*
    ```

- Search a pattern that contains space:

    ```vim
    :CtrlSF 'def foo():'
    ```

- Search a pattern with characters requiring escaping:

    ```vim
    :CtrlSF '"foobar"'
    " or
    :CtrlSF \"foobar\"
    ```

## Tips

- CtrlSF searches pattern literally by default, which is different from Ack/Ag. If you need to search a regular expression pattern, run `:CtrlSF -R regex`. If you dislike this default behavior, turn it off by `let g:ctrlsf_regex_pattern = 1`.

- By default, CtrlSF use working directory as search path when no path is specified. But CtrlSF can also use project root as its path if you set `g:ctrlsf_default_root` to `project`, CtrlSF does this by searching VCS directory (.git, .hg, etc.) upward from current file. It is usefule when you are working with files across multiple projects.

- `-filetype` is useful when you only want to search in files of specific type. Read option `--type` in `ack`'s [manual][6] for more information.

- Running `:CtrlSF` without any argument or pattern will use word under cursor.

## Configuration

- `g:ctrlsf_auto_close` defines if CtrlSF close itself when you are opening some file. By default CtrlSF window will close automatically but you can prevent it by setting `g:ctrlsf_auto_close` to 0.

    ```vim
    let g:ctrlsf_auto_close = 0
    ```

- `g:ctrlsf_case_sensitive` defines default case-sensivivity in search. Possible values are `yes`, `no` and `smart`, `smart` works the same as it is in vim. The default value is `smart`.

    ```vim
    let g:ctrlsf_case_sensitive = 'no'
    ```

- `g:ctrlsf_context` defines how many context lines will be printed. Please read `ack`'s [manual][6] for acceptable format. The default value is `-C 3`, and you can set another value by

    ```vim
    let g:ctrlsf_context = '-B 5 -A 3'
    ```
- `g:ctrlsf_default_root` defines how CtrlSF find search root when no explicit path is given. Two possible values are `cwd` and `project`. `cwd` means current working directory and `project` means project root. CtrlSF locates project root by searching VCS root (.git, .hg, .svn, etc.)

    ```vim
    let g:ctrlsf_default_root = 'project'
    ```

- `g:ctrlsf_indent` defines how many spaces are placed between line number and content. Default value is 4.

    ```vim
    let g:ctrlsf_indent = 2
    ```

- `g:ctrlsf_mapping` defines maps used in result window and preview window. Value of this option is a dictionary, where key is a method and value is a key for mapping. An empty value can disable that method. You can just defind a subset of full dictionary, those not defined functionalities will use default key mapping.

    ```vim
    let g:ctrlsf_mapping = {
        \ "next": "n",
        \ "prev": "N",
        \ }
    ```

- `g:ctrlsf_regex_pattern` defines CtrlSF using literal pattern or regular expression pattern as default. Default value is 0, which means literal pattern.

    ```vim
    let g:ctrlsf_regex_pattern = 1
    ```

- `g:ctrlsf_position` defines where CtrlSf places its window. Possible values are `left`, `right`, `top` and `bottom`. If nothing specified, the default value is `left`.

    ```vim
    let g:ctrlsf_position = 'bottom'
    ```

- `g:ctrlsf_winsize` defines the width (if CtrlSF opens vertically) or height (if CtrlSF opens horizontally) of CtrlSF main window. You can specify it with percent value or absolute value.

    ```vim
    let g:ctrlsf_winsize = '30%'
    " or
    let g:ctrlsf_winsize = '100'
    ```

A full list of options can be found in `:help ctrlsf-options`.

## For user comes from pre v1.0

### Difference between v1.0 and pre-v1.0

There are many features and changes introduced in v1.0, but the most important difference is **v1.0 breaks backward compatibility**.

### Where and why backward compatibility is given up?

CtrlSF is at first designed as a wrapper of ag/ack within vim, and the principle of interface design is *sticking to the interface of ag/ack running upon shell*. This fact lets user get access to all features of ag/ack, and it's easier to implement too. However I found it is not as useful as I thought, what's worse, this principle limits features I could add to CtrlSF and makes CtrlSF counter-intuitive sometimes.

**So I want to change it.**

Example:

Case-insensitive searching in pre-v1.0 CtrlSF is like this

```vim
CtrlSF -i foo
```

In v1.0, that will be replaced by

```vim
CtrlSF -ignorecase foo
```

For those most frequently used arguments, an upper case short version is available

```vim
CtrlSF -I foo
```

### Changelist

- Brand new edit mode is added.
- Literal searching becomes default.
- Mapping becomes customizable.
- Smart case is added and turned on by default.
- `g:ctrlsf_leading_space` is replaced by `g:ctrlsf_indent`.
- etc...

[1]: https://github.com/petdance/ack
[2]: https://github.com/ggreer/the_silver_searcher
[3]: https://github.com/tpope/vim-pathogen
[4]: https://github.com/gmarik/vundle
[5]: https://github.com/Shougo/neobundle.vim
[6]: https://github.com/gabesoft/vim-ags
[7]: https://github.com/terryma/vim-multiple-cursors
