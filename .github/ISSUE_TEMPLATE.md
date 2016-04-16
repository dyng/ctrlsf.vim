#### Before submitting your issue

1. Update to the latest version of CtrlSF.
2. Enable debug mode to find what is going wrong. You can enable debug mode by `let g:ctrlsf_debug_mode = 1`.

If you can't find out why things do not work or are sure it's a bug of CtrlSF, please fulfill the rest part of this issue. Thanks!

#### Issue description

You can describe your issue here.

#### Things about your system and environment

- os: OS X Yosemite 10.10.5
- vim: MacVim 7.4 Included patches: 1-712
- ack/ag/pt: ag 0.31.0
- locale: en_US.UTF-8
- file:
    - name: plugin/ctrlsf.vim
    - encoding: utf-8
- vimrc:

    ```vim
    let g:ctrlsf_ackprg = 'ag'
    let g:ctrlsf_populate_qflist = 1
    let g:ctrlsf_default_root = 'project'
    let g:ctrlsf_toggle_map_key = '\t'
    let g:ctrlsf_extra_backend_args = {
        \ 'pt': '--global-gitignore'
        \ }
    ```

- log:

    ```vim
    " attach here CtrlSF's debug mode log
    " you can pipe logs into a file by vim's :redir command
    :let g:ctrlsf_debug_mode = 1
    :redir >/tmp/ctrlsf.log
    :CtrlSF something...
    :redir END
    ```
