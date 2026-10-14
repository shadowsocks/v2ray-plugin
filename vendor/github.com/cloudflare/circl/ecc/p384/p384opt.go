//go:build (!noasm && arm64) || (!noasm && amd64)
// +build !noasm,arm64 !noasm,amd64

package p384

import (
	"crypto/subtle"
	"math/big"

	"github.com/cloudflare/circl/math"
)

type curve struct{}

// P384 returns a Curve which implements P-384 (see FIPS 186-3, section D.2.4).
func P384() Curve { return curve{} }

// IsOnCurve reports whether the given (x,y) lies on the curve.
func (c curve) IsOnCurve(x, y *big.Int) bool {
	x1, y1 := &fp384{}, &fp384{}
	x1.SetBigInt(x)
	y1.SetBigInt(y)
	montEncode(x1, x1)
	montEncode(y1, y1)

	y2, x3 := &fp384{}, &fp384{}
	fp384Sqr(y2, y1)
	fp384Sqr(x3, x1)
	fp384Mul(x3, x3, x1)

	threeX := &fp384{}
	fp384Add(threeX, x1, x1)
	fp384Add(threeX, threeX, x1)

	fp384Sub(x3, x3, threeX)
	fp384Add(x3, x3, &bb)

	return *y2 == *x3
}

// Add returns the sum of (x1,y1) and (x2,y2).
func (c curve) Add(x1, y1, x2, y2 *big.Int) (x, y *big.Int) {
	P := newAffinePoint(x1, y1).toJacobian()
	P.mixadd(P, newAffinePoint(x2, y2))
	return P.toAffine().toInt()
}

// Double returns 2*(x,y).
func (c curve) Double(x1, y1 *big.Int) (x, y *big.Int) {
	P := newAffinePoint(x1, y1).toJacobian()
	P.double()
	return P.toAffine().toInt()
}

// reduceScalar shorten a scalar modulo the order of the curve.
func (c curve) reduceScalar(k []byte) []byte {
	bigK := new(big.Int).SetBytes(k)
	bigK.Mod(bigK, c.Params().N)
	return bigK.FillBytes(make([]byte, sizeFp))
}

// toOdd performs k = (-k mod N) if k is even.
func (c curve) toOdd(k []byte) ([]byte, int) {
	var X, Y big.Int
	X.SetBytes(k)
	Y.Neg(&X).Mod(&Y, c.Params().N)
	isEven := 1 - int(X.Bit(0))
	x := X.Bytes()
	y := Y.Bytes()

	if len(x) < len(y) {
		x = append(make([]byte, len(y)-len(x)), x...)
	} else if len(x) > len(y) {
		y = append(make([]byte, len(x)-len(y)), y...)
	}
	subtle.ConstantTimeCopy(isEven, x, y)
	return x, isEven
}

// ScalarMult returns (Qx,Qy)=k*(Px,Py) where k is a number in big-endian form.
func (c curve) ScalarMult(x1, y1 *big.Int, k []byte) (x, y *big.Int) {
	return c.scalarMultOmega(x1, y1, k, 5)
}

func (c curve) scalarMultOmega(x1, y1 *big.Int, k []byte, omega uint) (x, y *big.Int) {
	k = c.reduceScalar(k)
	oddK, isEvenK := c.toOdd(k)

	var scalar big.Int
	scalar.SetBytes(oddK)
	if scalar.Sign() == 0 {
		return new(big.Int), new(big.Int)
	}
	const bitsN = uint(384)
	L := math.SignedDigit(&scalar, omega, bitsN)

	var R jacobianPoint
	Q := zeroPoint().toJacobian()
	TabP := newAffinePoint(x1, y1).oddMultiples(omega)
	for i := len(L) - 1; i > 0; i-- {
		for j := uint(0); j < omega-1; j++ {
			Q.double()
		}
		idx := absolute(L[i]) >> 1
		for j := range TabP {
			R.cmov(&TabP[j], subtle.ConstantTimeEq(int32(j), idx))
		}
		R.cneg(int(L[i]>>31) & 1)
		Q.add(Q, &R)
	}
	// Calculate the last iteration using complete addition formula.
	for j := uint(0); j < omega-1; j++ {
		Q.double()
	}
	idx := absolute(L[0]) >> 1
	for j := range TabP {
		R.cmov(&TabP[j], subtle.ConstantTimeEq(int32(j), idx))
	}
	R.cneg(int(L[0]>>31) & 1)
	QQ := Q.toProjective()
	QQ.completeAdd(QQ, R.toProjective())
	QQ.cneg(isEvenK)
	return QQ.toAffine().toInt()
}

// ScalarBaseMult returns k*G, where G is the base point of the group
// and k is an integer in big-endian form.
func (c curve) ScalarBaseMult(k []byte) (x, y *big.Int) {
	params := c.Params()
	return c.ScalarMult(params.Gx, params.Gy, k)
}

// CombinedMult calculates P=mG+nQ, where G is the generator and Q=(x,y,z).
// The scalars m and n are integers in big-endian form. Non-constant time.
func (c curve) CombinedMult(xQ, yQ *big.Int, m, n []byte) (xP, yP *big.Int) {
	const nOmega = uint(5)
	var k big.Int
	k.SetBytes(m)
	nafM := math.OmegaNAF(&k, baseOmega)
	k.SetBytes(n)
	nafN := math.OmegaNAF(&k, nOmega)

	if len(nafM) > len(nafN) {
		nafN = append(nafN, make([]int32, len(nafM)-len(nafN))...)
	} else if len(nafM) < len(nafN) {
		nafM = append(nafM, make([]int32, len(nafN)-len(nafM))...)
	}

	TabQ := newAffinePoint(xQ, yQ).oddMultiples(nOmega)
	var jR jacobianPoint
	var aR affinePoint
	P := zeroPoint().toJacobian()
	for i := len(nafN) - 1; i >= 0; i-- {
		P.double()
		// Generator point
		if nafM[i] != 0 {
			idxM := absolute(nafM[i]) >> 1
			aR = baseOddMultiples[idxM]
			if nafM[i] < 0 {
				aR.neg()
			}
			P.mixadd(P, &aR)
		}
		// Input point
		if nafN[i] != 0 {
			idxN := absolute(nafN[i]) >> 1
			jR = TabQ[idxN]
			if nafN[i] < 0 {
				jR.neg()
			}
			P.add(P, &jR)
		}
	}
	return P.toAffine().toInt()
}

// absolute returns always a positive value.
func absolute(x int32) int32 {
	mask := x >> 31
	return (x + mask) ^ mask
}
