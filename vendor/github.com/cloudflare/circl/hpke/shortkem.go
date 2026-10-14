package hpke

import (
	"crypto/elliptic"
	"crypto/rand"
	"crypto/subtle"
	"fmt"
	"math/big"

	"github.com/cloudflare/circl/kem"
)

type shortKEM struct {
	dhKemBase
	elliptic.Curve
}

func (s shortKEM) PrivateKeySize() int        { return s.byteSize() }
func (s shortKEM) SeedSize() int              { return s.byteSize() }
func (s shortKEM) CiphertextSize() int        { return 1 + 2*s.byteSize() }
func (s shortKEM) PublicKeySize() int         { return 1 + 2*s.byteSize() }
func (s shortKEM) EncapsulationSeedSize() int { return s.byteSize() }

func (s shortKEM) byteSize() int { return (s.Params().BitSize + 7) / 8 }

func (s shortKEM) sizeDH() int { return s.byteSize() }
func (s shortKEM) calcDH(dh []byte, sk kem.PrivateKey, pk kem.PublicKey) error {
	PK := pk.(*shortKEMPubKey)
	SK := sk.(*shortKEMPrivKey)
	l := len(dh)
	x, _ := s.ScalarMult(PK.x, PK.y, SK.priv) // only x-coordinate is used.
	if x.Sign() == 0 {
		return ErrInvalidKEMSharedSecret
	}
	b := x.Bytes()
	copy(dh[l-len(b):l], b)
	return nil
}

// Deterministically derives a keypair from a seed. If you're unsure,
// you're better off using GenerateKey().
//
// Panics if seed is not of length SeedSize().
func (s shortKEM) DeriveKeyPair(seed []byte) (kem.PublicKey, kem.PrivateKey) {
	// Implementation based on
	// https://www.ietf.org/archive/id/draft-irtf-cfrg-hpke-07.html#name-derivekeypair
	if len(seed) != s.SeedSize() {
		panic(kem.ErrSeedSize)
	}

	bitmask := byte(0xFF)
	if s.Params().BitSize == 521 {
		bitmask = 0x01
	}

	dkpPrk := s.labeledExtract([]byte(""), []byte("dkp_prk"), seed)
	var bytes []byte
	ctr := 0
	for skBig := new(big.Int); skBig.Sign() == 0 || skBig.Cmp(s.Params().N) >= 0; ctr++ {
		if ctr > 255 {
			panic("derive key error")
		}
		bytes = s.labeledExpand(
			dkpPrk,
			[]byte("candidate"),
			[]byte{byte(ctr)},
			uint16(s.byteSize()),
		)
		bytes[0] &= bitmask
		skBig.SetBytes(bytes)
	}
	l := s.PrivateKeySize()
	sk := &shortKEMPrivKey{s, make([]byte, l), nil}
	copy(sk.priv[l-len(bytes):], bytes)
	return sk.Public(), sk
}

func (s shortKEM) GenerateKeyPair() (kem.PublicKey, kem.PrivateKey, error) {
	sk, x, y, err := elliptic.GenerateKey(s, rand.Reader)
	pub := &shortKEMPubKey{s, x, y}
	return pub, &shortKEMPrivKey{s, sk, pub}, err
}

func (s shortKEM) UnmarshalBinaryPrivateKey(data []byte) (kem.PrivateKey, error) {
	l := s.PrivateKeySize()
	if len(data) < l {
		return nil, ErrInvalidKEMPrivateKey
	}
	sk := &shortKEMPrivKey{s, make([]byte, l), nil}
	copy(sk.priv[l-len(data):l], data[:l])
	if !sk.validate() {
		return nil, ErrInvalidKEMPrivateKey
	}

	return sk, nil
}

func (s shortKEM) UnmarshalBinaryPublicKey(data []byte) (kem.PublicKey, error) {
	x, y := elliptic.Unmarshal(s, data)
	if x == nil {
		return nil, ErrInvalidKEMPublicKey
	}
	key := &shortKEMPubKey{s, x, y}
	if !key.validate() {
		return nil, ErrInvalidKEMPublicKey
	}
	return key, nil
}

type shortKEMPubKey struct {
	scheme shortKEM
	x, y   *big.Int
}

func (k *shortKEMPubKey) String() string {
	return fmt.Sprintf("x: %v\ny: %v", k.x.Text(16), k.y.Text(16))
}
func (k *shortKEMPubKey) Scheme() kem.Scheme { return k.scheme }
func (k *shortKEMPubKey) MarshalBinary() ([]byte, error) {
	return elliptic.Marshal(k.scheme, k.x, k.y), nil
}

func (k *shortKEMPubKey) Equal(pk kem.PublicKey) bool {
	k1, ok := pk.(*shortKEMPubKey)
	return ok &&
		k.scheme.Params().Name == k1.scheme.Params().Name &&
		k.x.Cmp(k1.x) == 0 &&
		k.y.Cmp(k1.y) == 0
}

func (k *shortKEMPubKey) validate() bool {
	p := k.scheme.Params().P
	notAtInfinity := k.x.Sign() > 0 && k.y.Sign() > 0
	lessThanP := k.x.Cmp(p) < 0 && k.y.Cmp(p) < 0
	onCurve := k.scheme.IsOnCurve(k.x, k.y)
	return notAtInfinity && lessThanP && onCurve
}

type shortKEMPrivKey struct {
	scheme shortKEM
	priv   []byte
	pub    *shortKEMPubKey
}

func (k *shortKEMPrivKey) String() string     { return fmt.Sprintf("%x", k.priv) }
func (k *shortKEMPrivKey) Scheme() kem.Scheme { return k.scheme }
func (k *shortKEMPrivKey) MarshalBinary() ([]byte, error) {
	return append(make([]byte, 0, k.scheme.PrivateKeySize()), k.priv...), nil
}

func (k *shortKEMPrivKey) Equal(pk kem.PrivateKey) bool {
	k1, ok := pk.(*shortKEMPrivKey)
	return ok &&
		k.scheme.Params().Name == k1.scheme.Params().Name &&
		subtle.ConstantTimeCompare(k.priv, k1.priv) == 1
}

func (k *shortKEMPrivKey) Public() kem.PublicKey {
	if k.pub == nil {
		x, y := k.scheme.ScalarBaseMult(k.priv)
		k.pub = &shortKEMPubKey{k.scheme, x, y}
	}
	return k.pub
}

func (k *shortKEMPrivKey) validate() bool {
	n := new(big.Int).SetBytes(k.priv)
	order := k.scheme.Curve.Params().N
	return len(k.priv) == k.scheme.PrivateKeySize() && n.Cmp(order) < 0
}
