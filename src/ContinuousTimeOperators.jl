module ContinuousTimeOperators
using LinearAlgebra, BandedMatrices, KrylovKit

##############################################################################
##
## Load files
##
##############################################################################
include("build_matrix.jl")
include("eigenproblem.jl")
include("feynman_kac.jl")
include("geometric_functionals.jl")


##############################################################################
##
## Exported methods and types 
##
##############################################################################
export stationary_distribution,
feynman_kac_backward,
feynman_kac_forward,
compute_Eψm,
compute_η,
compute_ϵ 
end