# StorageTechTools
My tools to assist in encoded storage development and other storage projects. These may be very specific to my usecase. Use at your own risk. There are likely bugs!

## MappingsGenerator
This is a Julia module which assists with generating bit groups for arbitrary itemtype -> binary mappings (e.g. it handles multiple itemtypes mapping to the same binary code, missing codes, etc). The brute force algorithm solves for the bit grouping configuration with lowest possible number of chests. The input is in the form of an .xlsx file, with columns of `itemtypes` and `binary` with the itemtype and corresponding binary code listed on each row. See the example `test_mappings.xlsx` and example use of the script in `test.jl`. This module uses the `XLSX.jl` and `DataFrames.jl` packages.

The column with binary codes may be changed with the flag `binColName::String = columnHeader`. The sheet from which the .xlsx file is read defaults to `Sheet1`, but may be changed with the flag `sheet::String = sheetName`. In verbose mode (`verbose::Bool = true`), the best solution for each number of bit groups will be printed to the user. 

The `write_mappings` function produces .txt files for use with CommandLeo's encoder chest filler functions in their STX Scarpet script. See the examples under the `Sets` directory. 
