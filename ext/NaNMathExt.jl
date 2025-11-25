module NaNMathExt
using Unitful
import NaNMath

NaNMath.sqrt(q::Quantity) = NaNMath.sqrt(ustrip(q))*sqrt(unit(q))
NaNMath.pow(q::Quantity, r) = NaNMath.pow(ustrip(q), r)*unit(q)^r
end
