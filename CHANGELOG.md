# Changelog

All notable changes to this project will be documented in this file.

## [0.6] - 2026-01-17

### Bug Fixes

- Convert LF to CRLF as the IDE would not actually add a new line
- Allow changing register without closing popup
- Group undos for comments and paste. remaining highlight after del
- Move cursor to undo/redo position
- Gg should be used to go to a specific line, not G

### Features

- Add support for numbered registers
- Add popup for marks and registers
- Increase width of popup text
- Add support for V-LINE and V-BLOCK
- Support for substitutions (:%s/_/_)

### Miscellaneous Tasks

- Update README.md
- Update REAMDE.md
- Update README.md
- Update README.md

### Refactor

- Break down engine.pas

## [0.5] - 2026-01-16

### Bug Fixes

- Commands like ci( would move the screen, also limit bracket match distance
- Bracket highlighting breaking UI after an IA motion
- Missing files in projects
- R command now stays in Normal mode after replacing
- Search n/N now wrap around file

### Features

- Add gc* and support for guu, gUU
- Implement / searching
- Implement iw/aw text objects
- Implement named registers ("a-z)
- Implement global marks (m, ', `)

### Miscellaneous Tasks

- Add claude.md
- Gitignore claude folder

### Refactor

- Bugfixes on recent unpushed features

### Temp

- Add AI summary

## [0.4] - 2025-09-24

### Features

- Add support for C-d, C-u, C-r, Tab an S-Tab

## [0.3] - 2025-03-05

### Miscellaneous Tasks

- Fix D12 project missing a file

## [0.2] - 2025-02-20

### Bug Fixes

- Typo

### Features

- Support for more Ex Commands (qa, wq, wa, xa, qwa)
- Ability to use backspace on vi command, and require the return key for Ex commands

### Miscellaneous Tasks

- Update README

## [0.1] - 2024-12-09

### Added

- Source from github.com/petdr/vide + License
- Working Rio package
- About/Installation readme
- Dll configuration for debugging
- Installing + Debugging DLL info to readme
- License note to source files
- Temporary hello world action for toolbar
- Notice to previous vide project
- Escape cancels partially formed command
- Spacebar keybind

### Bug Fixes

- Button not persisting after an IDE restart and giving errors
- Copy, pasting multiple lines would remove new line feeds
- Rewrite of the bracket matching algorithm as it was flawed when encountering nested brackets
- Access violations and invalid pointer operations during closing
- Empty button that would show up after an IDE restart
- Recently broken f and t motions
- 'word' motion not working when cursor starts on on a white space
- Using `Fx` and `Tx` when the cursor is past EoL would cause the cursor to move to the wrong place
- Issues with # and * when on special characters
- Access violation when closing a unit using the x button

### Edit

- Autoformatting
- Merged license files
- Project restructuring
- Changed FActive/FInsert to Enum, Added toolbar status message
- Changed ProcessAction from case of to procedure dictionary
- Moved FInDelete/FInYank check to respective procedures
- InDelete, InChange, InYank to CurrentEditMode enum
- Moved number parsing to dictionary
- Reverted number dict and added movement dict
- Local Variable & Parameter renaming
- FEditPosition/Block renamed to FCursorPosition/Selection
- Symbol renaming
- Renamed count to currentCount
- Renamed FCount to FCurrentCount
- Moved MovementCount to procedure parameter
- More restructuring

### Features

- Major rewrites, expand feature set
- Support for XE3
- Add button automatically to Custom toolbar, with coloring
- Add support for redo (U), save (:w), close (:q)
- Initial support for inside/around modifier (support for brackets, quotes, ticks)
- Add support for count modifiers on uppercase motions (like S, D) and EOL, BOL motions (like _, $, 0)
- Add 'Y' motion
- Support for #
- Support for `v` command as well as selection-based commands

### Fix

- Weird linebreak bug
- Keybind procedures not getting called
- (temporary) variable for movement counts
- Renaming TViEngine in DelphiWizard.pas

### Miscellaneous Tasks

- Update post-opening in D12
- Update Readme with toolbar installation
- Cleanup of package
- Remove useless comment
- Convert todo tags into roadmap items on the Readme, cleanup Readme
- Cleanup and update Readme
- Update readme
- Update README
- Update readme to include relative line number configuration
- Update REAMDE file

### Refactor

- Change InnerAround to InsideAround as per conventions
- Combine textobjects and navigation
- Cleanup class names
- Move Execute out of NavigationMotion
- Rename INavigationMotion and IEditMotion
- Centralize move param validation

### Ci

- Delphi 2010-specific package
- Add XE3-specific package
- Add D12 package

