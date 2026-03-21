module NaNMathExt
using Unitful
import NaNMath

NaNMath.sqrt(q::Unitful.AbstractQuantity) = NaNMath.sqrt(ustrip(q))*sqrt(unit(q))
NaNMath.pow(q::Unitful.AbstractQuantity, r) = NaNMath.pow(ustrip(q), r)*unit(q)^r
end
