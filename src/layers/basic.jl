"""
    Chain(layers...)

Chain multiple layers / functions together, so that they are called in sequence
on a given input.

    m = Chain(x -> x^2, x -> x+1)
    m(5) == 26

    m = Chain(Dense(10, 5), Dense(5, 2))
    x = rand(10)
    m(x) = m[2](m[1](x))

`Chain` also supports indexing and slicing, e.g. `m[2]` or `m[1:end-1]`.
"""
type Chain
  layers::Vector{Any}
  Chain(xs...) = new([xs...])
end

@forward Chain.layers Base.getindex, Base.first, Base.last, Base.endof, Base.push!
@forward Chain.layers Base.start, Base.next, Base.done

Optimise.children(c::Chain) = c.layers

(s::Chain)(x) = foldl((x, m) -> m(x), x, s.layers)

Compiler.graph(s::Chain) =
  foldl((v, m) -> vertex(m, v), constant(inputnode(1)), s.layers)

Base.getindex(c::Chain, i::AbstractArray) = Chain(c.layers[i]...)

function Base.show(io::IO, c::Chain)
  print(io, "Chain(")
  join(io, c.layers, ", ")
  print(io, ")")
end

"""
    Dense(in::Integer, out::Integer, σ = identity)

Creates a traditional `Dense` layer with parameters `W` and `b`.

    y = σ.(W * x .+ b)
"""
struct Dense{F,S,T}
  σ::F
  W::S
  b::T
end

Dense(in::Integer, out::Integer, σ = identity; init = initn) =
  Dense(σ, param(init(out, in)), param(init(out)))

Optimise.children(d::Dense) = (d.W, d.b)

(a::Dense)(x) = a.σ.(a.W*x .+ a.b)

function Base.show(io::IO, l::Dense)
  print(io, "Dense(", size(l.W, 2), ", ", size(l.W, 1))
  l.σ == identity || print(io, ", ", l.σ)
  print(io, ")")
end