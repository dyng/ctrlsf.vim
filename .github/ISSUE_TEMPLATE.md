## Before submitting your issue（请在提交 issue 前一定要检查以下项目！）

1. Update to the latest version of CtrlSF.
2. Update your backend(ag/ack/pt/rg) to their latest version.
3. Enable debug mode to try to find what is going wrong yourself. You can enable debug mode by `let g:ctrlsf_debug_mode = 1`.

If you can't find out why things do not work or can be sure it's a bug of CtrlSF, please fulfill below issue template. Thanks in advance!

## Issue template

#### Issue description

*You can describe your issue here.（请将你的 issue 内容填写于此）*

#### Things about your system and environment（请在此填写你的系统信息）

|  field  |                value                 |
|:-------:|:------------------------------------:|
|   os    |       *OS X Yosemite 10.10.5*        |
|   vim   | *MacVim 7.4 Included patches: 1-712* |
| backend |             *ag 0.31.0*              |
| locale  |            *en_US.UTF-8*             |

- log:

    ```vim
    " attach debug-mode log here
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
    # please tell me something about files that CtrlSF doesn't work on.
    # if the content of file is private information, its encoding should be helpful.
    # it's important in some case!
    name: ctrlsf/plugin.vim
    encoding: utf-8
    content:
    # your file's content is here.
    ```
