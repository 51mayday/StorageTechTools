include("GrouperEncoderGenerator.jl") # Adds functions from GrouperEncoderGenerator.jl into your REPL

# To just get solved groups:
groups = GrouperEncoderGenerator.solve("test_mappings.xlsx"; sheet = "Sheet1", binColName = "bitstring", itemtypeColName = "itemtype", verbose = true)

# To generate litematic: 
GrouperEncoderGenerator.runGenerator("test_mappings.xlsx", "test_full"; sheet="Sheet1", verbose = true, verboseSubOps = true)


