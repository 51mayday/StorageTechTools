# Initialization
function tryusing(pkgsym) 
    try
        @eval using $pkgsym
        return true
    catch e
        return e
    end
end

if tryusing(:Pkg) != true
    print("Importing Pkg")
    import Pkg
end

if tryusing(:XLSX) != true
    print("Importing XLSX")
    Pkg.add("XLSX")
    import XLSX
end

# Returns a list of non-zero codes with x bits
function getCodes(x::Int)
    (x == 1) ? ["1"] : map(y -> bitstring(y)[(64-x+1):end], range(1, 2^x-1))
end

# Solves for the solution with the lowest amount of chests for given itemtype -> code mappings from xlsx filename on sheet sheet with data range extending to rows rows, number of bits, and number of groups  
function solver(filename::String, bits::Int, sheet = "Mappings", rows = 1311, numGroups = 3)
    # Gets itemtypes and corresponding codes from .xlsx file
    itemLayout = Dict("itemtype" => XLSX.readdata(filename, sheet, "B2:B$rows"), "binary" => XLSX.readdata(filename, sheet, "D2:D$rows"))

    # Initializing variables for the search loop
    bestChests = Inf
    bestSets = Vector{Dict{String, Vector{String}}}()
    bestGroups = Vector{Int}()

    numBits = Vector{Vector{Int}}()
    for group in 1:numGroups
        push!(numBits, [1:(bits - numGroups + 1)...])
    end

    for combination in collect(Iterators.product(numBits...))
        if sum(combination) != bits
            continue
        end

        bitGroups = Vector{Vector{String}}()
        for x in combination
            push!(bitGroups, [getCodes(x)...])
        end

        sets = Vector{Dict{String, Vector{String}}}()
        for x in bitGroups
            push!(sets, Dict(x .=> map(y -> Vector{String}(), 1:length(x))))
        end

        for index in eachindex(itemLayout["itemtype"])
            itemtype = itemLayout["itemtype"][index]
            code = itemLayout["binary"][index]

            codeSnippets = Vector{String}()
            for coordinate in combination
                snippet = code[1:coordinate]
                push!(codeSnippets, snippet)
                code = chopprefix(code, snippet)
            end

            # Check all codes for each bit group. If the item type code for the corresponding bits matches on of the codes in a particular bit group, add it to the set for that bit group code. 
            for index2 in eachindex(bitGroups)
                group = findfirst(==(codeSnippets[index2]), bitGroups[index2])
                if !isnothing(group)
                    push!(sets[index2][bitGroups[index2][group]], itemtype)
                end
            end
        end

        # Count up the total number of chests
        chests = 0
        for index in eachindex(sets)
            for key in keys(sets[index])
                chests += ceil(length(sets[index][key])/54.0)
            end
        end

        # add any additional chests you know you'll need to flag various item types
        chests += 0 # 3 + 1 + ceil((2^8-4)/54) # adding MIS flag chests, premade box flag chest, and whitelister chests

        # Update overall best solution
        if chests < bestChests 
            bestChests = chests
            bestSets = sets
            bestGroups = combination
        end
    end

    println("\nThe best grouping for $numGroups groups is $bestGroups with $bestChests chests!")
    return [bestGroups, bestChests, bestSets, itemLayout["itemtype"], itemLayout["binary"]]
end

input_filename = "item_layout_mappings_v1.xlsx"
sheet = "Mappings_3"
finalLine = 1258

# input_filename = "temp_digsort_mappings.xlsx"
# sheet = "Sheet1"
# finalLine = 59

# Number of bits to try to solve for
bits = 10

# Runs over all possible combinations of bit groups
best = [Vector{Int}(), Inf, Vector{Dict{String, Vector{String}}}(), Vector{String}(), Vector{String}()]
for numGroups in 1:bits
    solution = solver(input_filename, bits, sheet, finalLine, numGroups) # Change input parameters for your needs
    if solution[2] < best[2]
        global best = solution
    end
end

printstyled("\nThe best grouping is $(best[1]) with $(best[2]) chests!\n"; bold=true, color = :blue)

mask = Vector{String}()
for numBits in best[1]
    push!(mask, "x"^numBits)
end

allSets = Dict{String, Vector{String}}()
for index in eachindex(best[3])
    validIndices = filter(x -> x != index, range(1, length(best[3])))
    prefixIndices = filter(x -> x < index, validIndices)
    suffixIndices = filter(x -> x > index, validIndices)

    for key in keys(best[3][index])
        newKey = key
        if !isnothing(prefixIndices)
            newKey = prod(mask[prefixIndices]) * newKey
        end
        if !isnothing(suffixIndices)
            newKey = newKey * prod(mask[suffixIndices])
        end
        allSets[newKey] = best[3][index][key]
    end
end

# write itemlist files for encoder_chest_filter.sc scarpet script
global filenames = Vector{String}()
for key in keys(allSets)
    vals = allSets[key]
    append!(filenames, ["$key"])
    open("Sets/$key.txt", "w") do file
        for val in vals
            println(file, val)
        end
    end
end

sort!(filenames)

println()
for x in filenames
    print("$x ")
end