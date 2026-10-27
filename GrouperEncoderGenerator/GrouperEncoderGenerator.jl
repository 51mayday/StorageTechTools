module GrouperEncoderGenerator

include("lib/Litematica.jl")

using XLSX
using JSON
using DataFrames

using .Litematica


export read_mappings, solve, generateLitematic, runGenerator

# Config 
const blockerConfig = "minecraft:red_stained_glass_pane"

const wildcardConfig = "minecraft:tropical_fish"

item_stackability_file = "assets/items_stackability_26_2.json"
const item_stackabilities = JSON.parsefile(item_stackability_file)

const ssToColor = Dict(1 => "white_shulker_box", 2 => "light_gray_shulker_box", 3 => "gray_shulker_box", 4 => "black_shulker_box", 5 => "brown_shulker_box", 6 => "red_shulker_box", 7 => "orange_shulker_box", 8 => "yellow_shulker_box", 9 => "lime_shulker_box", 10 => "green_shulker_box", 11 => "cyan_shulker_box", 12 => "light_blue_shulker_box", 13 => "blue_shulker_box", 14 => "purple_shulker_box", 15 => "magenta_shulker_box")

"""
    read_mappings(io::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype")

    Reads the item mappings from an Excel file and returns a list of tuples containing the item type and its corresponding binary string.
"""
function read_mappings(io::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype")
    df = DataFrame(XLSX.readtable(io, sheet))
    return collect(zip(string.(df[!, itemtypeColName]), string.(df[!, binColName])))
end


"""
    getCodes(x::Int)

    Returns a list of binary strings representing the codes for a given number of bits.
"""
function getCodes(x::Int)
    (x == 1) ? ["1"] : map(y -> bitstring(y)[(64-x+1):end], range(1, 2^x-1))
end

"""
    makeBoxes(groups)

    Creates boxes with items for each group based on the provided mappings.
"""
function makeBoxes(groups)
    boxes = [[],[],[]]
    for i in eachindex(groups)
        for code in keys(groups[i])
            k = 1
            while k<=length(groups[i][code])
                items = groups[i][code][k:(k+26 <= length(groups[i][code]) ? k + 26 : end)]
                k+=27
                push!(boxes[i], (parse(Int64, code, base=2), items))
            end
        end
    end
    return boxes
end

"""
    calculateSSRange(signalStrength::Int)

    Calculates the allowed range of item counts (assuming stack size 64) for a give signal strength. Returns a tuple of (min, max) item counts.
"""
function calculateSSRange(signalStrength::Int)
    return Int64.((max(signalStrength, ceil(27*64/14*(signalStrength-1))), min(27*64, max(signalStrength+1, ceil(27*64/14*(signalStrength)))-1)))
end

"""
    getStackability(itemtype::String)

    Returns the stackability of a given item type based on the JSON file.
"""
function getStackability(itemtype::String; wildcardMode::Bool = false)
    if itemtype in keys(item_stackabilities)
        wildcardMode && item_stackabilities[itemtype]["stack_size"] == 1 && return 64
        return item_stackabilities[itemtype]["stack_size"]
    elseif itemtype == "Blocker"
        return 64
    else
        return 64
    end
end

"""
    checkSS(signalStrength::Int, itemlist::Vector{Tuple{String, Int64}})

    Checks if the total number of items in the provided list falls within the allowed range for the given signal strength. Returns true if it does, false otherwise.
"""
function checkSS(signalStrength::Int, itemlist::Vector{Tuple{String, Int64}})
    totalItems = sum(x[2]*64/getStackability(x[1]; wildcardMode = true) for x in itemlist)
    if totalItems in range(calculateSSRange(signalStrength)...)
        return true
    end
    return false
end

function checkIDValid(id::String)
    return id in keys(item_stackabilities)
end

"""
    assembleBoxes(boxes::Vector{Vector{Tuple{Int, Vector{Tuple{String, Int64}}}}}; verbose::Bool = false)

    Assembles boxes with items for each group based on the provided mappings. Ensures that the total number of items in each box falls within the allowed range for the given signal strength. Returns a list of boxes by group with associated code and list of items and amounts that should go into them.
"""
function assembleBoxes(boxes; verbose::Bool = false)
    groups = Vector{Vector{Tuple{Int, Vector{Tuple{String, Int64}}}}}()
    for chest in boxes
        newBoxes = Vector{Tuple{Int, Vector{Tuple{String, Int64}}}}()
        for box in chest
            newBox = (box[1], Vector{Tuple{String, Int64}}())
            
            for item in box[2]
                push!(newBox[2], (item, getStackability(item; wildcardMode = true) != 1 ? 2 : 1))
            end

            if !checkSS(newBox[1], newBox[2])
                remainder = calculateSSRange(newBox[1])[1] - sum(x[2]*64/getStackability(x[1]; wildcardMode = true) for x in newBox[2])
                iter = 0
                while iter < 50 && remainder > 0
                    added = false
                    for i in eachindex(newBox[2])
                        if remainder <= 0
                            break
                        end
                        item = newBox[2][i]
                        stackability = getStackability(item[1]; wildcardMode = true)
                        max_additional = stackability - item[2]
                        additional = min(max_additional, ceil(remainder*stackability/64))
                        if additional > 0
                            added = true
                        end
                        newBox[2][i] = (item[1], item[2] + additional)
                        remainder -= additional*64/stackability
                    end
                    if !added
                        if length(newBox[2]) < 27
                            verbose && println("Adding blocker to box with signal strength $(newBox[1])")
                            push!(newBox[2], ("Blocker", 2))
                            remainder -= 2
                        else
                            break
                        end
                    end
                    iter += 1
                end
            end
            
            if checkSS(newBox[1], newBox[2])
                verbose && println("Assembled box with signal strength $(newBox[1]) and $(sum(x[2]*64/getStackability(x[1]; wildcardMode = true) for x in newBox[2])) items in range $(calculateSSRange(newBox[1]))")
                push!(newBoxes, newBox)
            else
                println("Warning: Could not assemble box with signal strength $(newBox[1]) and items $(newBox[2])")
            end
        end
        push!(groups, newBoxes)
    end
    return groups
end

"""
    solve(itemLayoutFile::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype")

    Returns list of boxes by group with associated code and list of items and amounts that should go into them. 
"""
function solve(itemLayoutFile::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype", verbose::Bool = false)

    itemLayout = read_mappings(itemLayoutFile; sheet = sheet, binColName = binColName, itemtypeColName = itemtypeColName)

    numGroups = round(Int, ceil(length(itemLayout[1][2])/4))

    groups = [Dict(code => String[] for code in getCodes(4)) for _ in 1:numGroups]
    for (i, group) in enumerate(groups)
        pos = (i-1)*4 + 1
        sig = 3
        for (item, code) in itemLayout
            codeFrag = code[pos:(pos+sig)]
            if codeFrag in keys(group)
                push!(group[codeFrag], item)
            end
        end
    end

    return assembleBoxes(makeBoxes(groups); verbose=verbose)
end

function groupToChests(group; chestSize::Int = 27)
    chests = []
    group = copy(group)
    while length(group) > 0
        boxes = splice!(group, 1:min(chestSize, length(group)))
        push!(chests, boxes)
    end
    return chests
end

"""
    generateLitematic(groups, outputFileBaseName::String; baseFileName::String = "assets/base.litematic", outputFolder::String = "output/", verbose::Bool = false)

    Constructs the litematic file for the input chests. Saves output under output/outputFileBaseName.litematic. Takes an input litematic under baseFileName. 
"""
function generateLitematic(groupedChests, outputFileBaseName::String; baseFileName::String = "assets/base.litematic", outputFolder::String = "output/", verbose::Bool = false)
    base = read(baseFileName, Litematic)
    mkpath(outputFolder)
    
    numGroups = length(groupedChests)
    maxHeight = round(Int, ceil(maximum(length.(groupedChests))/2))
    schem_base = fill(base.regions[1].blocks.pool[1], 3, maxHeight, numGroups)
    constructedTEs = Array{Union{Litematica.Tag, Nothing}, 3}(nothing, 3, maxHeight, numGroups)
    
    modules = [[base.regions[1].blocks.pool[x] for x in base.regions[1].blocks.refs], [base.regions[2].blocks.pool[x] for x in base.regions[2].blocks.refs]]

    for (zIndex, chests) in enumerate(groupedChests)
        group_refs = modules[2]
        i = 0
        while i+1 < ceil(length(chests)/2)
            group_refs = cat(group_refs, modules[i % 2 + 1], dims = 2)
            i+=1
        end
        schem_base[1:size(group_refs, 1), 1:size(group_refs, 2), zIndex] = group_refs
    end

    for (zIndex, chests) in enumerate(groupedChests)
        # xyIndex - every increment changes x according to valid indices indexed by yIndex. Every two increments changes y.
        validXIndices = [(1, 2), (2, 3)]
        for (xyIndex, chest) in enumerate(chests)

            yIndexReal = round(Int, ceil(xyIndex/2))
            xIndex = validXIndices[(yIndexReal - 1) % 2 + 1][(xyIndex - 1) % 2 + 1]
            
            itemList = []
            for (slot, box_data) in enumerate(chest)
                ss, box = box_data
                list_tag = []
                for (slot, slot_data) in enumerate(box)

                    id = slot_data[1]
                    count = slot_data[2]

                    extra_data = []
                    if getStackability(id) == 1
                        id = wildcardConfig
                        extra_data = [Litematica.Tag(0xa, "components", [Litematica.Tag(0x8, "minecraft:custom_name", slot_data[1])])]
                    elseif id != "Blocker" && !checkIDValid(id)
                        verbose && println("Substituting wildcard for $id")
                        id = wildcardConfig
                        extra_data = [Litematica.Tag(0xa, "components", [Litematica.Tag(0x8, "minecraft:custom_name", slot_data[1])])]
                    elseif id == "Blocker"
                        id = blockerConfig
                        extra_data = [Litematica.Tag(0xa, "components", [Litematica.Tag(0x8, "minecraft:custom_name", slot_data[1])])]
                    end
                    push!(list_tag, Litematica.Tag(0xa, "", [Litematica.Tag(0x3, "slot", Int32(slot - 1)), Litematica.Tag(0xa, "item", [Litematica.Tag(0x3, "count", Int32(count)), Litematica.Tag(0x8, "id", id), extra_data...])]))
                end
                push!(itemList, 
                    Litematica.Tag(0xa, "", [Litematica.Tag(0x1, "Slot", UInt8(slot-1)), Litematica.Tag(0x8, "id", "minecraft:"*ssToColor[ss]), Litematica.Tag(0x3, "count", Int32(1)), Litematica.Tag(0xa, "components", [Litematica.Tag(0x8, "minecraft:custom_name", string(ss)), Litematica.Tag(0x9, "minecraft:container", 
                        list_tag
                    )])])
                    )
            end

            constructedTEs[xIndex, yIndexReal, zIndex] = 
                Litematica.Tag(0xa, "", [
                    Litematica.Tag(0x3, "x", Int32(xIndex - 1)),
                    Litematica.Tag(0x3, "y", Int32(yIndexReal - 1)),
                    Litematica.Tag(0x3, "z", Int32(zIndex - 1)),
                    Litematica.Tag(0x8, "id", "minecraft:chest"),
                    Litematica.Tag(0xa, "components", []),
                    Litematica.Tag(0x8, "CustomName", string("Group: $zIndex")),
                    Litematica.Tag(0x9, "Items", itemList)
                ])

        end
    end

    p = Litematica.PooledArray(zeros(Litematica.MinecraftDataStructures.BlockState, size(schem_base)))
    p .= schem_base

    reg = Region("Body", (Int32(0), Int32(0), Int32(0)), p, constructedTEs)
    metadataTag = Litematica.Tag(0xa, "Metadata", 
        [Litematica.Tag(0x8, "Description", "Generated with MappingsGenerator.jl"), 
        Litematica.Tag(0x4, "TimeModified", round(Int64, time() * 1000)),
        Litematica.Tag(0x4, "TimeCreated", round(Int64, time() * 1000)),
        Litematica.Tag(0x3, "TotalVolume", Int32(numGroups*maxHeight*3)),
        Litematica.Tag(0x8, "Name", "Groups"),
        Litematica.Tag(0x8, "Author", "51MayDay"),
        Litematica.Tag(0xa, "EnclosingSize", [Litematica.Tag(0x3, "x", Int32(3)), Litematica.Tag(0x3, "z", Int32(numGroups)), Litematica.Tag(0x3, "y", Int32(maxHeight))]),
        Litematica.Tag(0x3, "RegionCount", Int32(1))
    ])
    litematic = Litematic(2586, metadataTag, [reg])
    
    write(joinpath(outputFolder, "$(outputFileBaseName).litematic"), litematic)

    return litematic
end

"""
    runGenerator(mappingsXLSX::String, outputName::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype", verbose::Bool = true, verboseSubOps::Bool = false)

    Runs the full pipeline. Takes an input .xlsx file (and sheet) with columns binColName and itemtypeColName, creates groups of boxes with corresponding signal strength based on the supplied numGroups, and then saves the output as a .litematic under output/outputName.
"""
function runGenerator(mappingsXLSX::String, outputName::String; sheet::String = "Sheet1", binColName::String = "bitstring", itemtypeColName::String = "itemtype", verbose::Bool = true, verboseSubOps::Bool = false)
    verbose && println("Generating groups...")
    chests = groupToChests.(solve(mappingsXLSX; sheet = sheet, binColName = binColName, itemtypeColName = itemtypeColName, verbose = verboseSubOps))
    verbose && println("Generated $(length(chests)) sets of chests, with maximum $(round(Int, ceil(maximum(length.(chests))/2))) double chests per group.")

    verbose && println("Generating litematic...")
    generateLitematic(chests, outputName; verbose = verboseSubOps);
    println("Saved litematic: output/$(outputName).litematic.")

    return
end

end

