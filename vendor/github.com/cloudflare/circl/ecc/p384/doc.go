// Package p384 provides optimized elliptic curve operations on the P-384 curve.
//
// These are some improvements over crypto/elliptic package:
//   - Around 10x faster in amd64 architecture.
//   - Reduced number of memory allocations.
//   - Native support for arm64 architecture.
//   - ScalarMult is performed using a constant-time algorithm.
//   - ScalarBaseMult fallbacks into ScalarMult.
//   - A new method included for double-point multiplication.
package p384
