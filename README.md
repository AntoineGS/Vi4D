# Vi4D

## About The Project

This package provides Vi keybinds for the Delphi IDE. This project is forked from the abandoned [Vi-Delphi](https://github.com/Tanikai/vi-delphi) project which is based on [VIDE](https://github.com/petdr/vide) repository.
Thank you to both of those projects for the ideas and foundations. :)

## Installation

- Clone the repo
- Open the 'Vi4D.dproj' project file in Delphi
- Select the 'Release' build configuration
- Right-click the 'Vi4D.bpl' entry in the project view
- Click on 'Install'

## Debugging

Ensure the `Host application` under `Project Options` is set to your `bds.exe` path and run the bpl in debug mode.

## Roadmap

Coming soon

## Known issues / Differences with Neovim

A lot of this are notes I have taken during the initial refactor/rewrite, I will clean them up at some point as I address them.

- Selected text will not trigger any special behavior (so selecting text and pressing x or d will not delete the selection)
- Undoing operations that are more than one smaller operations require undoing each smaller operation
- `r` does not go back to Normal mode after entering the replacement character
- `S` does not support number.modifier
- `/` is not implemented yet
- `d` on multiple (and maybe one) lines and then pasting has issues with indents being added to each line
- cutting multiple lines and pasting them will insert it where the cursor is, should EOL and ensure a new line
- No `V` or `v` or `<C-V>`
- No inner/around yet
- TextObjects and Navigation are (so far) the same, Navigation has an .Execute a bit more complete, review after inner/around to see if it is still true
- `dw` does not work when on a white space, it should delete the whitespace
- add a centralized Move in Nav to validate input
- Marks support
- Clipboard only supports one entry
- Using `Fx` and `Tx` when the cursor is past EoL causes the cursor to move to the wrong place
- I Would LOVE to implement relative line numbers... not sure if it is possible though

(Wont Fix)

- `L` goes to last -1 line, due to IDE auto-scrolling if we to to the last line

## License

This project is licensed under GPLv3 (see LICENSE).
The original codebase is licensed under MIT (see vide-LICENSE).
