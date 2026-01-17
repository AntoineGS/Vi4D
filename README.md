# Vi4D

## About The Project

This package provides Vi keybinds for the Delphi IDE. This project is forked
from the abandoned [Vi-Delphi](https://github.com/Tanikai/vi-delphi) project
which is based on [VIDE](https://github.com/petdr/vide) repository. Thanks to
both of those projects for the ideas and foundation. :)

## Installation

- Clone the repo
- Open the `Vi4D_XXXXX.dproj` project file in Delphi (where 'XXXXX' is your
  version of Delphi)
- Select the `Release` build configuration
- Right-click the `Vi4D_XXXXX.bpl` entry in the project view
- Click on 'Install'

## Relative Line Numbers

CnWizards ([repo](https://github.com/cnpack/cnwizards)) maintainers were kind
enough to merge my PR to add relative line numbers and I highly recommend you
use it. To use it:

- Install [CnWizards](https://www.cnpack.org/showlist.php?id=39&lang=en), any
  version from 1.5.1.1221
- In the IDE, click on the `CnPack` menu, then `Options`
- In the `Wizard Settings` tab, find `Editor Enhancements`, ensure it is
  `Enabled` and click on `Settings`
- Under the `Line Number / Toolbar` tab, activate `Show Line Number in Editor.`
  and then activate `Show Relative Line Numbers.`
- Voila you now have relative line numbers in Delphi!

### IDE Toolbar

The plugin will automatically install a toolbutton on the Custom toolbar, which
is used to show the Vi Mode, the current command being typed as well as give the
ability to activate/deactivate the plugin. So make sure you have the Custom
toolbar shown!

## Debugging

Ensure the `Host application` under `Project Options` is set to your `bds.exe`
path and run the bpl in debug mode. Note: This does not seem to work in recent
versions of Delphi, it works great in D2010 though.

## Roadmap

- Support for (maybe) `=`
- Complete the inside/around featuresets (paragraphs, tags, blocks, word)
- Configurable bindings
- Look at bringing back the DLL debugging doc and project from the original
  repo, as it seems for newer versions of Delphi debugging bds.exe does not work

## Particularities (things that are not planned)

- `L` goes to last -1 line, due to IDE auto-scrolling if we to to the last line

## License

This project is licensed under GPLv3 (see LICENSE). The original codebase is
licensed under MIT (see vide-LICENSE).
