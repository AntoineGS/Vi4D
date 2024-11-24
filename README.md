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

### IDE Toolbar

The plugin will automatically install a toolbutton on the Custom toolbar, which is used to show the Vi Mode, the current command being typed as well as give the ability to activate/deactivate the plugin. So make sure you have the Custom toolbar shown!

## Debugging

Ensure the `Host application` under `Project Options` is set to your `bds.exe` path and run the bpl in debug mode.
Note: This does not seem to work in recent versions of Delphi, it works great in D2010 though.

## Roadmap

- Add version-specific projects for the ones I have access to (2010, XE3, 12)
- `V` and (maybe, though probably not) `<C-V>`
- Support for Half Page and Page Up/Down, `gUU`, `guu`, (maybe) `=`
- Complete the inside/around featuresets (paragraphs, tags, blocks, word)
- Implement `/` searching
- Undoing operations that are more than one smaller operations require undoing each smaller operation, find a way to 'group' operations
- Marks support
- I Would LOVE to implement relative line numbers... not sure if it is possible though
- Better registry support (currently only one entry is supported)
- Add more `:` commands and require enter key to trigger the parsing and move them to their own keybinding logic, starting with `!`
- Configurable bindings
- Look into merging the duplicated `ApplyActionToSelection` methods
- Look at bringing back the DLL debugging doc and project from the original repo, as it seems for newer versions of Delphi debugging bds.exe does not work

## Known issues

- `r` does not go back to Normal mode after entering the replacement character
- Undo and Redo do not bring the cursor back to the change
- Around motions with things like `w` need to keep one of the two spaces around
- After using some motions like Inside\Around when the cursor is before the text to change (like before the opening bracket), the view is changed with the cursor on the top line
- `<<` and `>>` do not support count modifier

## Particularities

- `L` goes to last -1 line, due to IDE auto-scrolling if we to to the last line
- `U` is used to Redo, instead of the classic `<C-R>`
- `Fx` and `Tx` only work on a line

## License

This project is licensed under GPLv3 (see LICENSE).
The original codebase is licensed under MIT (see vide-LICENSE).
