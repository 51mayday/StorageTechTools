## GrouperEncoderGenerator
This is a Julia module which generates mappings and a resulting `.litematic` file for grouper-based encoders as described by Optic (i.e. Pencoder). The grouper-based encoder uses a seed item and a grouper to search boxes containing a 4 bit component of the seed item's code encoded in the box's signal strength value. For arbitrary itemtype -> binary mappings (e.g. it handles multiple itemtypes mapping to the same binary code, missing codes, etc), the solver figures out the required number of groups, partitions items into groups according to their codes, and then assembles items into boxes with signal strength matching the desired 4 bit code. The generator partitions groups of boxes into chests, then constructs a `.litematic` containing said boxes said groups ready for pasting onto your grouper-based encoder.

Input to the base functions are in the form of an `.xlsx` file, with columns of `itemtype` and corresponding `bitstring` with the itemtype and corresponding binary code listed on each row. Note that the program assumes all entries in `bitstring` are the same length. Additionally, a base `.litematic`, `/assets/base.litematic`, is used for constructing the output `.litematic`. Any items not in the 26.2 itemtype list (or unstackable) will be replaced with a wildcard item. Blocker items will be used to push constructed boxes to the desired signal strength. Wildcard and blocker itemtypes can be chosen in the config section of `GrouperEncoderGenerator.jl`. 

See the example `test_mappings.xlsx` and example use of the script in `test.jl`.

This module uses old versions of Intricate's  `Litematica.jl` and `NBT.jl` packages provided in `/lib/`. This module uses the `JSON.jl`, `XLSX.jl`, and `DataFrames.jl` packages. 

Please let me know if you have improvements to suggest. 

The column with itemtypes may be changed with the flag `itemtypeColName::String = itemtypeHeader`. The column with binary codes may be changed with the flag `binColName::String = columnHeader`. The sheet from which the .xlsx file is read defaults to `Sheet1`, but may be changed with the flag `sheet::String = sheetName`. In verbose mode (`verbose::Bool = true`), the generator will provide updates throughout the solving process. In sub-operation verbose mode (`verboseSubOps::Bool = true`), the `solver` function will print information on status of assembled boxes and resulting signal strenghts. 

The `runGenerator(mappingsXLSX::String, outputName::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype", verbose::Bool = true, verboseSubOps::Bool = false)` function produces a `.litematic` file in the `/output/` directory. See the example under the `/output/` directory. 

_____________________________________________________________________

Detailed instructions:
1. (If not already installed) Install Julia using [`juliaup`](<https://julialang.org/install/>)
2. Make a folder and download `GrouperEncoderGenerator.jl`, `test_mappings.xlsx`, `/assets/`, and `/lib/` there. Modify `test_mappings.xlsx` to fit your itemtype -> bitstring mappings. The only columns you need to care about are `itemtype` and `binary` in `Sheet1`. The other columns and sheets were there for testing purposes. You can do lots of funky stuff like miss some codes, have several item types map to the same code, and have one item type produce two codes. 
3. Open a terminal in that folder. Run `julia` to start Julia. Install packages `JSON`, `XLSX`, and `DataFrames` by running `] add JSON XLSX DataFrames`. Wait for the package manager to finish (may take a couple minutes depending on your computer/internet connection). Exit the `pkg` mode by hitting backspace. 
4. Follow the commands in `test.jl`:

`include("GrouperEncoderGenerator.jl") # Adds functions from GrouperEncoderGenerator.jl into your REPL`

`# To just get solved groups:`
`groups = GrouperEncoderGenerator.solve("mappings_real.xlsx"; sheet = "Sheet1", binColName = "bitstring", itemtypeColName = "itemtype", verbose = true)`

`# To generate litematic: `
`GrouperEncoderGenerator.runGenerator("mappings_real.xlsx", "test_full"; sheet="Sheet1", verbose = true, verboseSubOps = true)`

5. Paste the resulting file `/output/test_full.litematic` into your world. 
