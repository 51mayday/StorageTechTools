# StorageTechTools
My tools to assist in encoded storage development and other storage projects. These may be very specific to my usecase. Use at your own risk. There are likely bugs!

## MappingsGenerator
This is a Julia module which assists with generating bit groups for arbitrary itemtype -> binary mappings (e.g. it handles multiple itemtypes mapping to the same binary code, missing codes, etc). The brute force algorithm solves for the bit grouping configuration with lowest possible number of chests. The input is in the form of an .xlsx file, with columns of `itemtypes` and `binary` with the itemtype and corresponding binary code listed on each row. See the example `test_mappings.xlsx` and example use of the script in `test.jl`. The module can be used to produce input files for CommandLeo's [STX Scarpet script](https://github.com/CommandLeo/scarpet/wiki/StorageTechX) encoder chest filler function. This module uses the `XLSX.jl` and `DataFrames.jl` packages. Please let me know if you have improvements to suggest. 

[For more information.](https://github.com/51mayday/StorageTechTools/blob/main/MappingsGenerator_dev/README.md)

## GrouperEncoderGenerator
This is a Julia module which generates mappings and a resulting `.litematic` file for grouper-based encoders as described by Optic (i.e. Pencoder). The grouper-based encoder uses a seed item and a grouper to search boxes containing a 4 bit component of the seed item's code encoded in the box's signal strength value. For arbitrary itemtype -> binary mappings (e.g. it handles multiple itemtypes mapping to the same binary code, missing codes, etc), the solver figures out the required number of groups, partitions items into groups according to their codes, and then assembles items into boxes with signal strength matching the desired 4 bit code. The generator partitions groups of boxes into chests, then constructs a `.litematic` containing said boxes said groups ready for pasting onto your grouper-based encoder.

Input to the base functions are in the form of an `.xlsx` file, with columns of `itemtype` and corresponding `bitstring` with the itemtype and corresponding binary code listed on each row. Note that the program assumes all entries in `bitstring` are the same length. Additionally, a base `.litematic`, `/assets/base.litematic`, is used for constructing the output `.litematic`. Any items not in the 26.2 itemtype list (or unstackable) will be replaced with a wildcard item. Blocker items will be used to push constructed boxes to the desired signal strength. Wildcard and blocker itemtypes can be chosen in the config section of `GrouperEncoderGenerator.jl`. 

See the example `test_mappings.xlsx` and example use of the script in `test.jl`.

[For more information.](https://github.com/51mayday/StorageTechTools/blob/main/GrouperEncoderGenerator/README.md)
