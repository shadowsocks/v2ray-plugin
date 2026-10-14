package p384

import (
	"crypto/elliptic"
	"math/big"
)

// Curve is used to provide the extended functionality and performance of
// elliptic.Curve interface.
type Curve interface {
	elliptic.Curve
	// IsAtInfinity returns True is the point is the identity point.
	IsAtInfinity(X, Y *big.Int) bool
	// CombinedMult calculates P=mG+nQ, where G is the generator and
	// Q=(Qx,Qy). The scalars m and n are positive integers in big-endian form.
	// Runs in non-constant time to be used in signature verification.
	CombinedMult(Qx, Qy *big.Int, m, n []byte) (Px, Py *big.Int)
}

// Params returns the parameters for the curve. Note: The value returned by
// this function fallbacks to the stdlib implementation of elliptic curve
// operations. Use this method to only recover elliptic curve parameters.
func (c curve) Params() *elliptic.CurveParams { return elliptic.P384().Params() }

// IsAtInfinity returns True is the point is the identity point.
func (c curve) IsAtInfinity(x, y *big.Int) bool {
	return x.Sign() == 0 && y.Sign() == 0
}
