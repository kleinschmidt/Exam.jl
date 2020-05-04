module Exam

using
    Gumbo,
    AbstractTrees,
    UUIDs,
    ZipFile,
    LightXML

include("response.jl")
include("question.jl")
include("parse.jl")

include("read.jl")

include("qti.jl")
include("media.jl")

end # module
