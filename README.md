# ctrlsf.vim

An ack/ag/pt/rg powered code search and view tool, takes advantage of Vim 8's power to support asynchronous searching, and lets you edit file in-place with *Edit Mode*.

### Search and Explore

A demo shows how to search a word in an asynchronous way.

![ctrlsf async_demo](https://raw.githubusercontent.com/dyng/i/master/ctrlsf.vim/async-demo.gif)

### Edit Mode

A demo shows how to rename a method named `MoveCursor()` to `Cursor()` in multiple files, using [vim-multiple-cursors][7].

![ctrlsf_edit_demo](https://raw.githubusercontent.com/dyng/i/master/ctrlsf.vim/edit-mode.gif)

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Key Maps](#key-maps)
- [Use Your Own Map](#use-your-own-map)
- [Edit Mode](#edit-mode)
  - [Limitation](#limitation)
- [Arguments](#arguments)
  - [Example](#example)
- [Tips](#tips)
- [Configuration](#configuration)
- [For user comes from pre v1.0](#for-user-comes-from-pre-v10)
  - [Difference between v1.0 and pre-v1.0](#difference-between-v10-and-pre-v10)
  - [Where and why backward compatibility is given up?](#where-and-why-backward-compatibility-is-given-up)

## Features

- Search and display result in a user-friendly view with adjustable context.

- Works in both asynchronous (for **Vim 8.0.1039+** and **NeoVim**) and synchronous (for older version of Vim) manner.

- **Edit mode** which is incredible useful when you are working on project-wide refactoring. (Inspired by [vim-ags][6])

- Preview mode for fast exploring.

- Has two types of view. For both users who love a **sublime-like**, rich context result window, and users who feel more comfortable with good old **quickfix** window. (similar to ack.vim)

- Various options for customized search, view and edition.

## Installation

1. Make sure you have [ack][1], [ag][2], [pt][8] or [rg][10] installed. (Note: currently only Ack2 is supported by plan)

2. An easy way to install CtrlSF is using a package manager, like [pathogen][3], [vundle][4], [neobundle][5] or [vim-plug][9].

    In vim-plug:

    ```vim
    Plug 'dyng/ctrlsf.vim'
    ```

3. Read *Quick Start* for how to use.

## Quick Start

1. Run `:CtrlSF [pattern]`, it will split a new window to show search result.

2. If you are doing an asynchronous searching, you can explore and edit other files in the meanwhile, and can always press `Ctrl-C` to stop searching.

3. In the result window, press `Enter`/`o` to open corresponding file, or press `q` to quit.

4. Press `p` to explore file in a preview window if you only want a glance.

5. You can edit search result as you like. Whenever you apply a change, you can save your change to actual file by `:w`.

6. If you change your mind after saving, you can always undo it by pressing `u` and saving it again.

7. `:CtrlSFOpen` can reopen CtrlSF window when you have closed CtrlSF window. It is free because it won't invoke a same but new search. A handy command `:CtrlSFToggle` is also available.

8. If you prefer a quickfix-like result window, just try to press `M` in CtrlSF window.

## Key Maps

In CtrlSF window:

- `Enter`, `o`, `double-click` - Open corresponding file of current line in the window which CtrlSF is launched from.
- `<C-O>` - Like `Enter` but open file in a horizontal split window.
- `t` - Like `Enter` but open file in a new tab.
- `p` - Like `Enter` but open file in a preview window.
- `P` - Like `Enter` but open file in a preview window and switch focus to it.
- `O` - Like `Enter` but always leave CtrlSF window opening.
- `T` - Like `t` but focus CtrlSF window instead of new opened tab.
- `M` - Switch result window between **normal** view and **compact** view.
- `q` - Quit CtrlSF window.
- `<C-J>` - Move cursor to next match.
- `<C-K>` - Move cursor to previous match.
- `<C-C>` - Stop a background searching process.

In preview window:

- `q` - Close preview window.

Some default defined keys may conflict with keys you have been used to when you are editing. But don't worry, you can customize your mapping by setting `g:ctrlsf_mapping`. `:h g:ctrlsf_mapping` for more information.

## Use Your Own Map

CtrlSF provides many maps which you can use for quick accessing all features, here I will list some most useful ones.

- `<Plug>CtrlSFPrompt`

    Input `:CtrlSF ` in command line for you, just a handy shortcut.

- `<Plug>CtrlSFVwordPath`

    Input `:CtrlSF foo ` in command line where `foo` is the current visual selected word, waiting for further input.

- `<Plug>CtrlSFVwordExec`

    Like `<Plug>CtrlSFVwordPath`, but execute it immediately.

- `<Plug>CtrlSFCwordPath`

    Input `:CtrlSF foo ` in command line where `foo` is word under the cursor.

- `<Plug>CtrlSFCCwordPath`

    Like `<Plug>CtrlSFCwordPath`, but also add word boundary around searching word.

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

- If a file's content varies from last search, CtrlSF will refuse to write your changes to that file (for safety concern). As a rule of thumb, invoke a new search before editing, or just run `:CtrlSFUpdate`.

## Arguments

CtrlSF has a lot of arguments you can use in search. Most arguments are similar to Ack/Ag's but not perfectly same. Here are some most frequently used arguments:

- `-R` - Use regular expression pattern.
- `-I`, `-S` - Search case-insensitively (`-I`) or case-sensitively (`-S`).
- `-C`, `-A`, `-B` - Specify how many context lines to be printed, identical to their counterparts in Ag/Ack.
- `-W` - Only match whole words.

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

- By default, CtrlSF use working directory as search path when no path is specified. But CtrlSF can also use project root as its path if you set `g:ctrlsf_default_root` to `project`, CtrlSF does this by searching VCS directory (.git, .hg, etc.) upward from current file. It is useful when you are working with files across multiple projects.

- `-filetype` is useful when you only want to search in files of specific type. Read option `--type` in `ack`'s [manual][6] for more information.

- If `-filetype` does not exactly match your need, there is an option `-filematch` with which you have more control on which files should be searched. `-filematch` accepts a pattern that only files match this pattern will be searched. Note the pattern is in syntax of your backend but not vim's. Also, a shortcut `-G` is available.

- Running `:CtrlSF` without any argument or pattern will use word under cursor.

## Configuration

- `g:ctrlsf_auto_close` defines if CtrlSF close itself when you are opening some file. By default, CtrlSF window will close automatically in `normal` view mode and keep open in `compact` view mode. You can customize the value as below:

    ```vim
    let g:ctrlsf_auto_close = {
        \ "normal" : 0,
        \ "compact": 0
        \}
    ```

- `g:ctrlsf_auto_focus` defines how CtrlSF focuses result pane when working in async search mode. By default, CtrlSF will not focus at all, setting to `start` makes CtrlSF focus at search starting, setting to `done` makes CtrlSF focus at search is done, but only for immediately finished search. An additional `duration_less_than` is used to define max duration of a search can be focused for 'at done', which is an integer value of milliseconds.

    ```vim
    let g:ctrlsf_auto_focus = {
        \ "at": "start"
        \ }
    " or
    let g:ctrlsf_auto_focus = {
        \ "at": "done",
        \ "duration_less_than": 1000
        \ }
    ```

- `g:ctrlsf_case_sensitive` defines default case-sensitivity in search. Possible values are `yes`, `no` and `smart`, `smart` works the same as it is in vim. The default value is `smart`.

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

- `g:ctrlsf_default_view_mode` defines default view mode which CtrlSF will use. Possible values are `normal` and `compact`. The default value is `normal`.

    ```vim
    let g:ctrlsf_default_view_mode = 'compact'
    ```

- `g:ctrlsf_extra_backend_args` is a dictionary that defines extra arguments that will be passed *literally* to backend, especially useful when you have your favorite backend and need some backend-specific features. For example, using `ptignore` file for [pt][8] should be like

    ```vim
    let g:ctrlsf_extra_backend_args = {
        \ 'pt': '--home-ptignore'
        \ }
    ```

- `g:ctrlsf_extra_root_markers` is a list contains custom root markers. For example, this option is set `['.root']`, and there exists a file or directory `/home/your/project/.root`, then `/home/your/project` will be recognized as project root.

    ```vim
    let g:ctrlsf_extra_root_markers = ['.root']
    ```

- `g:ctrlsf_mapping` defines maps used in result window and preview window. Value of this option is a dictionary, where key is a method and value is a key for mapping. An empty value can disable that method. To specify additional keys to run after a method, use the extended form demonstrated below to specify a `suffix`. You can just define a subset of full dictionary, those not defined functionalities will use default key mapping.

    ```vim
    let g:ctrlsf_mapping = {
        \ "openb": { key: "O", suffix: "<C-w>p" },
        \ "next": "n",
        \ "prev": "N",
        \ }
    ```

- `g:ctrlsf_populate_qflist` defines if CtrlSF will also feed quickfix and location list with search result. By default this feature is disabled but you can enable it by

    ```vim
    let g:ctrlsf_populate_qflist = 1
    ```

- `g:ctrlsf_regex_pattern` defines CtrlSF using literal pattern or regular expression pattern as default. Default value is 0, which means literal pattern.

    ```vim
    let g:ctrlsf_regex_pattern = 1
    ```

- `g:ctrlsf_search_mode` defines whether CtrlSF works in synchronous or asynchronous way. `async` is the recommendation for users who are using Vim 8.0+.

    ```vim
    let g:ctrlsf_search_mode = 'async'
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

[1]: https://github.com/petdance/ack2
[2]: https://github.com/ggreer/the_silver_searcher
[3]: https://github.com/tpope/vim-pathogen
[4]: https://github.com/gmarik/vundle
[5]: https://github.com/Shougo/neobundle.vim
[6]: https://github.com/gabesoft/vim-ags
[7]: https://github.com/terryma/vim-multiple-cursors
[8]: https://github.com/monochromegane/the_platinum_searcher
[9]: https://github.com/junegunn/vim-plug
[10]: https://github.com/BurntSushi/ripgrep
