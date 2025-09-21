## MappingsGenerator
This is a Julia module which assists with generating bit groups for arbitrary itemtype -> binary mappings (e.g. it handles multiple itemtypes mapping to the same binary code, missing codes, etc). The brute force algorithm solves for the bit grouping configuration with lowest possible number of chests. The input is in the form of an .xlsx file, with columns of `itemtypes` and `binary` with the itemtype and corresponding binary code listed on each row. See the example `test_mappings.xlsx` and example use of the script in `test.jl`. This module uses the `XLSX.jl` and `DataFrames.jl` packages. Please let me know if you have improvements to suggest. 

The column with binary codes may be changed with the flag `binColName::String = columnHeader`. The sheet from which the .xlsx file is read defaults to `Sheet1`, but may be changed with the flag `sheet::String = sheetName`. In verbose mode (`verbose::Bool = true`), the best solution for each number of bit groups will be printed to the user. 

The `write_mappings` function produces .txt files for use with CommandLeo's encoder chest filler functions in their [STX Scarpet script](https://github.com/CommandLeo/scarpet/wiki/StorageTechX). See the examples under the `Sets` directory. 

_____________________________________________________________________

Detailed instructions:
0. Install Julia using [`juliaup`](<https://julialang.org/install/>)
1. Make a folder and download `MappingsGenerator.jl` and `test_mappings.xlsx` there. Modify `test_mappings.xlsx` to fit your item->code mappings. The only columns you need to care about are `itemtype` and `binary` in `Sheet1`. The other columns and sheets were there for testing purposes. You can do lots of funky stuff like miss some codes, have several item types map to the same code, and have one item type produce two codes. 
2. Open a terminal in that folder. Run `julia` to start Julia. Install packages `XLSX` and `DataFrames` by running `] add XLSX` and `] add DataFrames`. Wait for the package manager to finish (may take a couple minutes depending on your computer/internet connection). Exit the `pkg` mode by hitting backspace. 
3. Follow the commands in `test.jl`:

`include("MappingsGenerator.jl") # Adds functions from MappingsGenerator.jl to your REPL`

`idealSets = MappingsGenerator.solve("test_mappings.xlsx"; sheet = "Sheet1", verbose = true, binColName = "binary"); # Solves for the ideal sets given your input XLSX file. Default settings: sheet = "Sheet1, verbose = false, binColName = "binary"`

 `MappingsGenerator.write_mappings(idealSets) # Makes a folder called 'Sets' and writes .txt files for each bit grouping. Use these files with CommandLeo's STX encoder chest filler`

`idealSets # Prints the solved idealSets to the REPL`
4. Copy the contents of `Sets` to `scripts\shared\item_lists\` in your world save folder or global config to use with Leo's STX scarpet scripts.
