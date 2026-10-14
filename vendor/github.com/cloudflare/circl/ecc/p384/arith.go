//go:build (!noasm && arm64) || (!noasm && amd64)
// +build !noasm,arm64 !noasm,amd64

package p384

import (
	"math/big"

	"github.com/cloudflare/circl/internal/conv"
)

const sizeFp = 48

type fp384 [sizeFp]byte

func (e fp384) BigInt() *big.Int { return conv.BytesLe2BigInt(e[:]) }
func (e fp384) String() string   { return conv.BytesLe2Hex(e[:]) }

func (e *fp384) SetBigInt(b *big.Int) {
	if b.BitLen() > 384 || b.Sign() < 0 {
		b = new(big.Int).Mod(b, p.BigInt())
	}
	conv.BigInt2BytesLe(e[:], b)
}

func montEncode(c, a *fp384) { fp384Mul(c, a, &r2) }
func montDecode(c, a *fp384) { fp384Mul(c, a, &fp384{1}) }
func fp384Sqr(c, a *fp384)   { fp384Mul(c, a, a) }

func fp384Inv(z, x *fp384) {
	t0, t1, t2, t3, t4 := &fp384{}, &fp384{}, &fp384{}, &fp384{}, &fp384{}
	/* alpha_1 */
	fp384Sqr(t4, x)
	/* alpha_2 */
	fp384Mul(t4, t4, x)
	/* alpha_3 */
	fp384Sqr(t0, t4)
	fp384Mul(t0, t0, x)
	/* alpha_6 */
	fp384Sqr(t1, t0)
	fp384Sqr(t1, t1)
	fp384Sqr(t1, t1)
	fp384Mul(t1, t1, t0)
	/* alpha_12 */
	fp384Sqr(t2, t1)
	for i := 0; i < 5; i++ {
		fp384Sqr(t2, t2)
	}
	fp384Mul(t2, t2, t1)
	/* alpha_15 */
	for i := 0; i < 3; i++ {
		fp384Sqr(t2, t2)
	}
	fp384Mul(t2, t2, t0)
	/* alpha_30 */
	fp384Sqr(t1, t2)
	for i := 0; i < 14; i++ {
		fp384Sqr(t1, t1)
	}
	fp384Mul(t1, t1, t2)
	/* alpha_60 */
	fp384Sqr(t3, t1)
	for i := 0; i < 29; i++ {
		fp384Sqr(t3, t3)
	}
	fp384Mul(t3, t3, t1)
	/* T_3 = alpha_30^(2^2) */
	fp384Sqr(t1, t1)
	fp384Sqr(t1, t1)
	/* alpha_32 */
	*t0 = *t1
	fp384Mul(t0, t0, t4)
	/* T_3 = a^(2^32-3) = (alpha_30)^(2^2)*alpha_1 */
	fp384Mul(t1, t1, x)
	/* alpha_120 */
	fp384Sqr(t4, t3)
	for i := 0; i < 59; i++ {
		fp384Sqr(t4, t4)
	}
	fp384Mul(t4, t4, t3)
	/* alpha_240 */
	fp384Sqr(t3, t4)
	for i := 0; i < 119; i++ {
		fp384Sqr(t3, t3)
	}
	fp384Mul(t3, t3, t4)
	/* alpha_255 */
	for i := 0; i < 15; i++ {
		fp384Sqr(t3, t3)
	}
	fp384Mul(t3, t3, t2)
	/* T_5 = a^(2^288-2^32-1) = (alpha_255)^(2^33)*alpha_32 */
	for i := 0; i < 33; i++ {
		fp384Sqr(t3, t3)
	}
	fp384Mul(t3, t3, t0)
	/* T_1 = a^(2^384-2^128-2^96+2^32-3) = (T_1)^(2^96)*T_3 */
	fp384Sqr(t4, t3)
	for i := 0; i < 95; i++ {
		fp384Sqr(t4, t4)
	}
	fp384Mul(z, t4, t1)
}

//go:noescape
func fp384Cmov(x, y *fp384, b int)

//go:noescape
func fp384Neg(c, a *fp384)

//go:noescape
func fp384Add(c, a, b *fp384)

//go:noescape
func fp384Sub(c, a, b *fp384)

//go:noescape
func fp384Mul(c, a, b *fp384)

var (
	// p is the order of the base field, represented as little-endian 64-bit words.
	p = fp384{
		0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	}
	// pp satisfies r*rp - p*pp = 1 where rp and pp are both integers.
	pp = fp384{ //nolint
		0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0xff, 0xfb, 0xff, 0xff, 0xff,
		0xfa, 0xff, 0xff, 0xff, 0xfc, 0xff, 0xff, 0xff, 0x02, 0x00, 0x00, 0x00,
		0x0c, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00,
	}
	// r2 is R^2 where R = 2^384 mod p.
	r2 = fp384{
		0x01, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00,
		0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0xff,
		0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	}
	// bb is the Montgomery encoding of the curve parameter B.
	bb = fp384{
		0xcc, 0x2d, 0x41, 0x9d, 0x71, 0x88, 0x11, 0x08, 0xec, 0x32, 0x4c, 0x7a,
		0xd8, 0xad, 0x29, 0xf7, 0x2e, 0x02, 0x20, 0x19, 0x9b, 0x20, 0xf2, 0x77,
		0xe2, 0x8a, 0x93, 0x94, 0xee, 0x4b, 0x37, 0xe3, 0x94, 0x20, 0x02, 0x1f,
		0xf4, 0x21, 0x2b, 0xb6, 0xf9, 0xbf, 0x4f, 0x60, 0x4b, 0x11, 0x08, 0xcd,
	}
)
