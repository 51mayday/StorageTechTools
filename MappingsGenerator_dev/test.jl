include("MappingsGenerator.jl")

idealSets = MappingsGenerator.solve("test_mappings.xlsx"; sheet = "Sheet1", verbose = true, binColName = "binary");

MappingsGenerator.write_mappings(idealSets)

idealSets
