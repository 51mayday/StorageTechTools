module MinecraftDataStructures

using PooledArrays

export Block, BlockState, AbstractBlockState, CompressedPalettedContainer

abstract type AbstractBlockState end

struct Block <: AbstractBlockState
  id::String
end

struct BlockState <: AbstractBlockState
  id::String
  properties::Vector{Pair{String, String}}
end

Base.:(==)(a::Block, b::Block) = a.id == b.id
Base.:(==)(a::BlockState, b::BlockState) = a.id == b.id && a.properties == b.properties
Base.isequal(a::Block, b::Block) = a.id == b.id
Base.isequal(a::BlockState, b::BlockState) = a.id == b.id && a.properties == b.properties
Base.hash(a::Block, h::UInt64) = hash(a.id, h)
Base.hash(a::BlockState, h::UInt64) = hash(a.id, hash(a.properties, h))

Base.zero(::Type{AbstractBlockState}) = Block("minecraft:air")
Base.zero(::AbstractBlockState) = Block("minecraft:air")
Base.zero(::Type{Block}) = Block("minecraft:air")
Base.zero(::Block) = Block("minecraft:air")
Base.zero(::Type{BlockState}) = BlockState("minecraft:air", Pair{String, String}[])
Base.zero(::BlockState) = BlockState("minecraft:air", Pair{String, String}[])

Base.one(::Type{AbstractBlockState}) = Block("minecraft:stone")
Base.one(::AbstractBlockState) = Block("minecraft:stone")
Base.one(::Type{Block}) = Block("minecraft:stone")
Base.one(::Block) = Block("minecraft:stone")
Base.one(::Type{BlockState}) = BlockState("minecraft:stone", Pair{String, String}[])
Base.one(::BlockState) = BlockState("minecraft:stone", Pair{String, String}[])

Base.show(io::IO, lr::Block) = print(io, split(lr.id, ":")[end])
Base.show(io::IO, lr::BlockState) = print(io, split(lr.id, ":")[end])

struct CompressedPalettedContainer{T}
  palette::Vector{T}
  data::Array{Int64}
end

function CompressedPalettedContainer(uncompressed::PooledArray{<:AbstractBlockState}, min_bits::Int64)
  wordsize = max(min_bits, ceil(Int, log2(length(uncompressed.pool))))
  CompressedPalettedContainer(uncompressed.pool,
    reinterpret.(Int64, BitArray((n - 1) >>> i & 1 == 1 for n in uncompressed.refs for i in 0:wordsize - 1).chunks))
end

function CompressedPalettedContainer(uncompressed::PooledArray{<:AbstractBlockState}, min_bits::Int64, desired_palette)
  wordsize = max(min_bits, ceil(Int, log2(length(desired_palette))))
  CompressedPalettedContainer(desired_palette,
    reinterpret.(Int64, BitArray((n - 1) >>> i & 1 == 1 for n in uncompressed.refs for i in 0:wordsize - 1).chunks))
end

function PooledArray(compressed::CompressedPalettedContainer, min_bits::Int64, len::Int)
  wordsize = max(min_bits, ceil(Int, log2(length(compressed.palette))))
  data = ones(UInt32, len)
  shift = 0
  j = 1
  mask = 2^wordsize - 1
  for i in 1:len
    data[i] += (compressed.data[j] >>> shift) & mask
    if shift + wordsize > 64
      data[i] += (compressed.data[j += 1] >>> (shift - 64)) & mask
      shift = shift + wordsize - 64
    elseif shift + wordsize == 64
      j += 1
      shift = 0
    else
      shift += wordsize
    end
  end
  # TODO: find a way to directly set the PooledArray
  # return PooledArray(getindex(compressed.palette, data))
  return PooledArray(PooledArrays.RefArray(data), Dict(b => UInt32(i) for (i, b) in enumerate(compressed.palette)), compressed.palette, Threads.Atomic{Int64}(1))
end

end
