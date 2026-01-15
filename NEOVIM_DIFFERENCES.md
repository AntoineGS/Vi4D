# Vi4D vs Neovim Behavioral Differences

This report documents differences between Vi4D's implementation and Neovim's expected behavior.

---

## 1. Motions

### 1.1 `f`, `F`, `t`, `T` - Find Character Motions

**Vi4D Behavior:** Single-line only (see `FindForward`/`FindBackwards` in `Commands.Motion.pas:418-592`)

**Neovim Behavior:** Also single-line by default, but can wrap with `'wrapscan'`

**Difference:** Minor - Vi4D matches default Neovim behavior

---

### 1.2 `;` and `,` - Repeat Find Motion

**Vi4D:** Not implemented

**Neovim:** `;` repeats last `f`/`F`/`t`/`T` in same direction; `,` repeats in opposite direction

**Impact:** Medium - common workflow for navigating within lines

---

### 1.3 `%` - Matching Bracket

**Vi4D:** Not implemented

**Neovim:** Jumps to matching `()`, `[]`, `{}`, and supports `matchpairs` option

**Impact:** High - very common motion for code navigation

---

### 1.4 `H` - Top of Screen

**Vi4D:** Not implemented (only `L` and `M` exist)

**Neovim:** Moves to top line of visible screen

**Impact:** Medium - `H`/`M`/`L` are typically used together

---

### 1.5 `L` - Bottom of Screen

**Vi4D Behavior:** Goes to `BottomRow - 1` (see `Commands.Motion.pas:636`)

**Neovim Behavior:** Goes to actual bottom row

**Difference:** Vi4D intentionally does this to avoid IDE auto-scroll. Documented as a "particularity."

---

### 1.6 `^` - First Non-Blank

**Vi4D:** Uses `_` instead, `^` not bound

**Neovim:** `^` goes to first non-blank character; `_` does the same but accepts count for lines

**Impact:** Medium - `^` is the standard binding

---

### 1.7 `+` and `-` - Line Navigation

**Vi4D:** Not implemented

**Neovim:** `+` goes down to first non-blank; `-` goes up to first non-blank

**Impact:** Low

---

### 1.8 `ge` and `gE` - End of Previous Word

**Vi4D:** Not implemented

**Neovim:** Moves backward to end of previous word

**Impact:** Medium

---

### 1.9 `|` - Column Motion

**Vi4D:** Not implemented

**Neovim:** `|` goes to column N (default 1)

**Impact:** Low

---

### 1.10 `(` and `)` - Sentence Motions

**Vi4D:** Not implemented

**Neovim:** Moves by sentences

**Impact:** Low for code editing

---

## 2. Operators

### 2.1 `g~` - Toggle Case Operator

**Vi4D:** Not implemented as operator (only `~` for single char, `gU`/`gu` for upper/lower)

**Neovim:** `g~{motion}` toggles case over motion

**Impact:** Low - `gU`/`gu` are more commonly used

---

### 2.2 `gq` - Format Operator

**Vi4D:** Not implemented

**Neovim:** Formats text according to `textwidth`

**Impact:** Low for code editing

---

### 2.3 `!` - Filter Operator

**Vi4D:** Not implemented

**Neovim:** `!{motion}` filters through external program

**Impact:** Low - requires external program

---

### 2.4 `=` - Auto-indent Operator

**Vi4D:** Registered but `TOperatorAutoIndent` class is empty

**Neovim:** Re-indents according to `indentexpr`

**Impact:** Medium - useful for code formatting

---

## 3. Text Objects

### 3.1 `iw`, `aw` - Word Objects

**Vi4D:** `TIAMotionWord.GetSelection` is empty - not functional

**Neovim:** Selects inner/around word

**Impact:** High - extremely common text objects

---

### 3.2 `iW`, `aW` - WORD Objects

**Vi4D:** Not implemented

**Neovim:** Selects inner/around WORD (whitespace-delimited)

**Impact:** Medium

---

### 3.3 `is`, `as` - Sentence Objects

**Vi4D:** Not implemented

**Neovim:** Selects inner/around sentence

**Impact:** Low for code

---

### 3.4 `ip`, `ap` - Paragraph Objects

**Vi4D:** `TIAMotionParagraph.GetSelection` is empty - not functional

**Neovim:** Selects inner/around paragraph

**Impact:** Medium

---

### 3.5 `it`, `at` - Tag Objects

**Vi4D:** `TIAMotionTag.GetSelection` is commented out - not functional

**Neovim:** Selects inner/around XML/HTML tag

**Impact:** Low unless editing markup

---

### 3.6 `iB`, `aB` - Block Objects

**Vi4D:** `TIAMotionBlocks.GetSelection` is empty - not functional

**Neovim:** Same as `i{`/`a{`

**Impact:** Low - duplicate of brace objects

---

### 3.7 Bracket Matching Distance

**Vi4D:** Limited to 100 rows forward (see `Commands.IAMotion.pas:163`)

**Neovim:** No distance limit

**Impact:** Could fail on large code blocks

---

## 4. Registers

### 4.1 Named Registers (`"a` - `"z`)

**Vi4D:** Array exists for 256 registers but no way to select them (`FSelectedRegister` is never changed)

**Neovim:** `"a` through `"z` are named registers; `"A`-`"Z` append

**Impact:** High - register selection is core Vim functionality

---

### 4.2 Special Registers

**Vi4D:** None implemented

**Neovim:**
- `""` - unnamed register (default)
- `"0` - yank register
- `"1`-`"9` - delete history
- `"+`/`"*` - system clipboard
- `"_` - black hole register
- `"/` - search register
- `".` - last inserted text

**Impact:** High - especially system clipboard integration

---

## 5. Visual Mode

### 5.1 Visual Line Mode (`V`)

**Vi4D:** `TEditionVisualLineMode.Execute` is empty - not functional

**Neovim:** Selects entire lines

**Impact:** High - very common mode

---

### 5.2 Visual Block Mode (`Ctrl-V`)

**Vi4D:** Not implemented (noted in README as probably not coming)

**Neovim:** Column/block selection

**Impact:** Medium

---

### 5.3 `gv` - Reselect Previous Visual

**Vi4D:** Not implemented

**Neovim:** Reselects last visual selection

**Impact:** Medium

---

### 5.4 `o` in Visual Mode

**Vi4D:** Not implemented

**Neovim:** `o` swaps cursor to other end of selection

**Impact:** Medium

---

## 6. Insert Mode

### 6.1 `Ctrl-O` - Execute One Normal Command

**Vi4D:** Not implemented

**Neovim:** Execute one normal mode command, then return to insert mode

**Impact:** Medium

---

### 6.2 `Ctrl-R` in Insert Mode

**Vi4D:** Not implemented (only works in normal mode for redo)

**Neovim:** Insert contents of register

**Impact:** Medium

---

### 6.3 `Ctrl-W` - Delete Word Backward

**Vi4D:** Not implemented in insert mode

**Neovim:** Deletes word before cursor in insert mode

**Impact:** Medium

---

### 6.4 `Ctrl-U` - Delete to Start of Line

**Vi4D:** `Ctrl-U` is half-page up in normal mode

**Neovim:** In insert mode, deletes to start of line

**Impact:** Low

---

## 7. Normal Mode Commands

### 7.1 `r` - Replace Character

**Vi4D Behavior:** Known issue - does not return to Normal mode after replacement (noted in README)

**Neovim Behavior:** Replaces char and stays in Normal mode

**Impact:** High - broken behavior

---

### 7.2 `gJ` - Join Without Space

**Vi4D:** Not implemented (only `J` with space)

**Neovim:** Joins lines without adding space

**Impact:** Low

---

### 7.3 `ZZ` and `ZQ`

**Vi4D:** Not implemented

**Neovim:** `ZZ` = `:wq`, `ZQ` = `:q!`

**Impact:** Low - shortcuts for ex commands

---

### 7.4 `&` - Repeat Last Substitution

**Vi4D:** Not implemented

**Neovim:** Repeats last `:s` command

**Impact:** Low - substitution not implemented anyway

---

### 7.5 `q` - Macro Recording

**Vi4D:** Not implemented

**Neovim:** `q{register}` starts recording, `q` stops, `@{register}` plays

**Impact:** High - macros are powerful

---

### 7.6 `@` - Execute Macro/Register

**Vi4D:** Not implemented

**Neovim:** Executes register as commands

**Impact:** High - paired with macro recording

---

### 7.7 `m` - Set Mark

**Vi4D:** Code exists but is commented out (`Engine.pas:445`)

**Neovim:** Sets a mark at cursor position

**Impact:** High - marks are very useful

---

### 7.8 `'` and `` ` `` - Go to Mark

**Vi4D:** Commented out (`Engine.pas:403`)

**Neovim:** Jump to mark (line or exact position)

**Impact:** High - paired with mark setting

---

## 8. Ex Commands

### 8.1 `/` and `?` - Search

**Vi4D:** Not implemented (noted in README roadmap)

**Neovim:** Forward/backward search with pattern

**Impact:** Very High - fundamental Vim functionality

---

### 8.2 `:s` - Substitution

**Vi4D:** Not implemented (noted in README roadmap as `:s/_/_`)

**Neovim:** `:s/pattern/replacement/flags`

**Impact:** High - very common command

---

### 8.3 `:e` - Edit File

**Vi4D:** Not implemented

**Neovim:** Opens file for editing

**Impact:** Medium - Delphi IDE has its own file opening

---

### 8.4 `:bn`, `:bp` - Buffer Navigation

**Vi4D:** Not implemented (but `Tab`/`S-Tab` switch buffers)

**Neovim:** Navigate between buffers

**Impact:** Low - alternative exists

---

### 8.5 `:set` - Options

**Vi4D:** Not implemented

**Neovim:** Configure editor options

**Impact:** Medium

---

### 8.6 `:{range}` - Line Addressing

**Vi4D:** Not implemented

**Neovim:** Ex commands can take line ranges like `:10,20d`

**Impact:** Medium

---

## 9. Undo/Redo

### 9.1 Undo Granularity

**Vi4D Behavior:** Uses IDE's undo which may have different granularity (noted in README)

**Neovim Behavior:** Groups changes by insert session

**Impact:** Medium - may need multiple undos for single conceptual change

---

### 9.2 Cursor Position After Undo

**Vi4D:** Known issue - cursor doesn't return to change location (noted in README)

**Neovim:** Cursor moves to the undone change

**Impact:** Medium

---

### 9.3 Undo Tree

**Vi4D:** Linear undo only

**Neovim:** Full undo tree with `g-`/`g+`

**Impact:** Low - advanced feature

---

## 10. Counts and Repetition

### 10.1 `.` (Dot) Repeat Limitations

**Vi4D:** Replays the key sequence, may not capture insert mode text

**Neovim:** Captures full change including inserted text

**Impact:** High - `.` with insert commands may not work correctly

---

### 10.2 Count with Insert Commands

**Vi4D:** Count is stored but may not repeat insert text N times

**Neovim:** `3iHello<Esc>` inserts "HelloHelloHello"

**Impact:** Medium

---

## 11. Miscellaneous

### 11.1 `Ctrl-A`/`Ctrl-X` - Increment/Decrement

**Vi4D:** Not implemented

**Neovim:** Increment/decrement number under cursor

**Impact:** Medium

---

### 11.2 `Ctrl-G` - File Info

**Vi4D:** Not implemented

**Neovim:** Shows file name and position

**Impact:** Low

---

### 11.3 `g Ctrl-G` - Word Count

**Vi4D:** Not implemented

**Neovim:** Shows word/byte/char count

**Impact:** Low

---

### 11.4 `ga` - Show Character Code

**Vi4D:** Not implemented

**Neovim:** Shows ASCII/Unicode value of character

**Impact:** Low

---

### 11.5 `gf` - Go to File

**Vi4D:** Not implemented

**Neovim:** Opens file under cursor

**Impact:** Medium

---

### 11.6 `Ctrl-]` - Jump to Tag

**Vi4D:** Not implemented

**Neovim:** Jumps to tag definition

**Impact:** Medium - could integrate with IDE's go-to-definition

---

### 11.7 `Ctrl-O`/`Ctrl-I` - Jump List

**Vi4D:** Commented out as "cant find a way to support this" (`Engine.pas:402`)

**Neovim:** Navigate backward/forward in jump list

**Impact:** High - very useful for code navigation

---

## Summary by Priority

### Critical (Core Vim UX)
1. `/` search - fundamental navigation
2. `iw`/`aw` text objects - most common text objects
3. Named registers (`"a-z`) - can't yank to specific registers
4. `r` not returning to Normal mode - broken behavior
5. Marks (`m`, `'`, `` ` ``) - important for code navigation

### High Priority
1. Visual line mode (`V`)
2. `%` bracket matching
3. Macro recording (`q`, `@`)
4. `:s` substitution
5. `.` repeat with full insert capture
6. Jump list (`Ctrl-O`/`Ctrl-I`)
7. System clipboard registers (`"+`, `"*`)

### Medium Priority
1. `H` top of screen
2. `;`/`,` repeat find
3. `^` first non-blank
4. `ge`/`gE` end of previous word
5. `gv` reselect visual
6. Insert mode `Ctrl-O`
7. `=` auto-indent (complete implementation)

### Low Priority (Nice to Have)
1. Sentence motions `(`/`)`
2. `+`/`-` line motions
3. `|` column motion
4. `ZZ`/`ZQ` shortcuts
5. `g~` toggle case operator
6. `Ctrl-A`/`Ctrl-X` increment/decrement
