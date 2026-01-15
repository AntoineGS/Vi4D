# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vi4D is a Delphi IDE plugin that provides Vi/Vim keybindings for the Delphi code editor. It is a fork of Vi-Delphi, itself based on VIDE.

## Building and Installing

1. Open `Vi4D_XXXXX.dproj` in Delphi (D2010, XE3, or D12 supported)
2. Select `Release` build configuration
3. Right-click the `Vi4D_XXXXX.bpl` in the project view and click "Install"

### Debugging

Set `Host application` under `Project Options` to your `bds.exe` path and run in debug mode. Note: Debugging bds.exe works best in D2010; newer Delphi versions may have issues.

## Architecture

### Core Components

- **Vi4DWizard.pas** - Entry point; registers the plugin via `IOTAWizard`. Intercepts keyboard messages via `TApplicationEvents.OnMessage`, filters for the editor control (`TEditControl`), and routes keystrokes to the Engine.

- **Engine.pas** - Central state machine. Manages Vi mode (Normal/Insert/Visual/Inactive), maintains keybinding dictionaries for operators/motions/editions/ex-commands, and dispatches characters to the current `TOperation`.

- **Operation.pas** - Assembles a complete Vi command from parts. Tracks the current operator, motion, count modifier, and command string. Executes when a complete command is formed (e.g., `d` + `w` = delete word).

### Command Types (in `Engine.FillBindings`)

| Type | Base Class | Examples | Purpose |
|------|-----------|----------|---------|
| Operators | `TOperator` | `d`, `y`, `c`, `>`, `<`, `gU`, `gu`, `gc`, `v` | Actions that require a motion/text-object |
| Motions | `TMotion` | `w`, `b`, `e`, `h`, `j`, `k`, `l`, `f+`, `gg`, `G` | Cursor movements; can be standalone or combined with operators |
| Editions | `TEdition` | `a`, `i`, `o`, `O`, `x`, `p`, `u`, `.` | Standalone commands that don't use operator+motion pattern |
| Ex Commands | `TEx` | `:w`, `:q`, `:wq`, `:qa` | Colon-prefixed commands |

### Key Interfaces

- `IEngine` - Mode management (`CurrentViMode`) and last command execution
- `IMoveMotion` - Cursor movement with `Move(position, count, forEdition)`
- `ISearchMotion` - Motions that need a search token (e.g., `f`, `t`)
- `IIAMotion` - Inside/Around text object selection (`GetSelection`)

### Command Flow

1. `Vi4DWizard.DoApplicationMessage` intercepts WM_KEYDOWN/WM_CHAR
2. `Engine.EditKeyDown`/`EditChar` filters based on current mode
3. `Engine.HandleChar` looks up command in binding dictionaries
4. `Operation.SetAndExecuteIfComplete` assembles and executes when complete
5. Operators use `ApplyActionToSelection` to modify text via `IOTAEditBlock`

### Text Object System

Inside/Around motions (`i+`, `a+`) delegate to `Commands.IAMotion.pas`:
- `TIAMotionParenthesis`, `TIAMotionBraces`, `TIAMotionSquareBracket`, etc.
- Use bracket matching with `IOTAEditPosition.SearchOptions` for paired delimiters

### IDE Integration

- Uses `ToolsAPI` interfaces: `IOTAEditBuffer`, `IOTAEditPosition`, `IOTAEditBlock`, `IOTAEditView`
- `NavUtils.pas` provides helper functions for accessing IDE services
- Toolbar button added to `sCustomToolBar` with mode-colored background

## File Organization

```
src/
  Commands.Base.pas      - TCommand base class, TBlockAction enum, TViMode
  Commands.Operators.pas - Delete, Yank, Change, Indent, Case, Comment operators
  Commands.Motion.pas    - All cursor movement commands
  Commands.Edition.pas   - Insert/append modes, paste, undo, character operations
  Commands.IAMotion.pas  - Inside/Around text object implementations
  Commands.Ex.pas        - Ex (colon) commands
  Operation.pas          - Command assembly and execution
  Engine.pas             - State machine and keybinding registration
  Vi4DWizard.pas         - IDE integration and message interception
  NavUtils.pas           - ToolsAPI helper functions
  Clipboard.pas          - Vi register/clipboard management
```

## Key Patterns

- Multi-character commands use `FCommandToMatch` accumulator (e.g., `gg`, `gU`)
- `+` suffix in bindings means "requires additional character" (e.g., `f+` for `fx`)
- Operators store themselves in `FOperator` and wait for a motion to complete
- Line-level operations (like `dd`) detected when operator key is repeated
