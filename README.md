# StorageTechTools
My tools to assist in encoded storage development and other storage projects. These may be very specific to my usecase. Use at your own risk. There are likely bugs!

## MappingsGenerator
This is a Julia module which assists with generating bit groups for arbitrary itemtype -> binary mappings (e.g. it handles multiple itemtypes mapping to the same binary code, missing codes, etc). The brute force algorithm solves for the bit grouping configuration with lowest possible number of chests. The input is in the form of an .xlsx file, with columns of `itemtypes` and `binary` with the itemtype and corresponding binary code listed on each row. See the example `test_mappings.xlsx` and example use of the script in `test.jl`. The module can be used to produce input files for CommandLeo's [STX Scarpet script](https://github.com/CommandLeo/scarpet/wiki/StorageTechX) encoder chest filler function. This module uses the `XLSX.jl` and `DataFrames.jl` packages. Please let me know if you have improvements to suggest. 

[For more information.](https://github.com/51mayday/StorageTechTools/blob/main/MappingsGenerator_dev/README.md)
