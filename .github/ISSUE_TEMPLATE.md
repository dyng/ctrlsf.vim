## Before submitting your issue

1. Update to the latest version of CtrlSF.
2. Update your backend(ag/ack/pt) to their latest version.
2. Enable debug mode to find what is going wrong. You can enable debug mode by `let g:ctrlsf_debug_mode = 1`.

If you can't find out why things do not work or can be sure it's a bug of CtrlSF, please fulfill below issue template. Thanks in advance!

## Issue template

#### Issue description

*You can describe your issue here.*

#### Things about your system and environment

|  field  |                value                 |
|:-------:|:------------------------------------:|
|   os    |       *OS X Yosemite 10.10.5*        |
|   vim   | *MacVim 7.4 Included patches: 1-712* |
| backend |             *ag 0.31.0*              |
| locale  |            *en_US.UTF-8*             |

- log:

    ```vim
    " attach here CtrlSF's debug mode log
    " you can pipe logs into a file by vim's :redir command
    :let g:ctrlsf_debug_mode = 1
    :redir >/tmp/ctrlsf.log
    :CtrlSF something...
    :redir END
    ```

- vimrc:

    ```vim
    let g:ctrlsf_ackprg = 'pt'
    let g:ctrlsf_populate_qflist = 1
    let g:ctrlsf_default_root = 'project'
    let g:ctrlsf_toggle_map_key = '\t'
    let g:ctrlsf_extra_backend_args = {
        \ 'pt': '--global-gitignore'
        \ }
    ```


- file:

    ```shell
    # please tell me something about files that CtrlSF doesn't work as you expect.
    # if the content of file is sensitive, at least tell me its encoding.
    # it's important in some case!
    name: ctrlsf/plugin.vim
    encoding: utf-8
    content:
    # your file's content is here.
    ```
    
