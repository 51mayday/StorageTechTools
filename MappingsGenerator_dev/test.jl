include("MappingsSolver.jl")

idealSets = MappingsSolver.solve("test_mappings.xlsx"; sheet = "Sheet1", verbose = true, binColName = "binary");

MappingsSolver.write_mappings(idealSets)

idealSets
