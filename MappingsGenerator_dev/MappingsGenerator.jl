module MappingsGenerator

using XLSX, DataFrames

export read_mappings, solve, write_mappings

# Reads in itemtype - binary pairs as tuples from an XLSX file with columns "itemtype" and `binColName = "binary"`
function read_mappings(io::String; sheet::String = "Sheet1", binColName::String = "binary")
    df = DataFrame(XLSX.readtable(io, sheet))
    return collect(zip(string.(df[!, "itemtype"]), string.(df[!, binColName])))
end

# Finds the maximum number of bits required by the mappings
function max_bits(mappings::Vector{Tuple{String, String}})
    bits = [mapping[2] for mapping in mappings]
    return maximum(length, bits)
end

# Returns a list of non-zero codes with `numBits` bits
function getCodes(numBits::Int)
    (numBits == 1) ? ["1"] : map(y -> bitstring(y)[(64-numBits+1):end], range(1, 2^numBits-1))
end

# Brute force solve for the minimum number of chests for given mappings
function solve(xlsx::String; sheet::String = "Sheet1", verbose::Bool = false, binColName::String = "binary")
    mappings = read_mappings(xlsx; sheet = sheet, binColName = binColName)
    numBits = max_bits(mappings)

    bestChests = Inf
    bestSets = Vector{Dict{String, Vector{String}}}()
    bestGroups = Vector{Int}()

    for numGroups in 1:numBits
        if verbose
            println("Solving for $numGroups groups:")
            subBestChests = Inf
            subBestGroups = Vector{Int}()
        end
        bitLists = Vector{Vector{Int}}()
        for group in 1:numGroups
            push!(bitLists, [1:(numBits - numGroups + 1)...])
        end

        for combination in Iterators.product(bitLists...)
            if sum(combination) != numBits
                continue
            end
            
            bitGroups = Vector{Vector{String}}()
            for groupSize in combination
                push!(bitGroups, [MappingsGenerator.getCodes(groupSize)...])
            end

            sets = Vector{Dict{String, Vector{String}}}()
            for x in bitGroups
                push!(sets, Dict(x .=> map(y -> Vector{String}(), 1:length(x))))
            end

            for mapping in mappings
                itemtype, code = mapping

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

            chests = 0
            for set in sets
                for val in values(set)
                    chests += ceil(length(val)/54.0)
                end
            end

            if chests < bestChests 
                bestChests = chests
                bestSets = sets
                bestGroups = combination
            end

            if verbose && chests < subBestChests
                subBestChests = chests
                subBestGroups = combination
            end
        end
        if verbose
            println("The best solution for $numGroups groups is $subBestGroups with $subBestChests chests.")
        end
    end

    printstyled("\nThe best grouping is $bestGroups with $bestChests chests!\n"; bold=true, color = :blue)

    mask = Vector{String}()
    for numBits in bestGroups
        push!(mask, "x"^numBits)
    end

    allSets = Dict{String, Vector{String}}()
    for index in eachindex(bestSets)
        validIndices = filter(x -> x != index, range(1, length(bestSets)))
        prefixIndices = filter(x -> x < index, validIndices)
        suffixIndices = filter(x -> x > index, validIndices)

        for key in keys(bestSets[index])
            newKey = key
            if !isnothing(prefixIndices)
                newKey = prod(mask[prefixIndices]) * newKey
            end
            if !isnothing(suffixIndices)
                newKey = newKey * prod(mask[suffixIndices])
            end
            allSets[newKey] = bestSets[index][key]
        end
    end

    return allSets
end

# Write itemlist files for encoder_chest_filter.sc scarpet script to the /Sets directory
function write_mappings(sets::Dict{String, Vector{String}}; outputFolderName::String = "Sets", deleteExistingResults::Bool = true)
    if deleteExistingResults
        rm(outputFolderName, force = true, recursive = true)
    end
    mkpath(outputFolderName)
    filenames = Vector{String}()
    for key in keys(sets)
        vals = sets[key]
        append!(filenames, ["$key"])
        open("$outputFolderName/$key.txt", "w") do file
            for val in vals
                println(file, val)
            end
        end
    end

    sort!(filenames)

    println("Saved files:")
    for x in filenames
        print("$x ")
    end
end

end