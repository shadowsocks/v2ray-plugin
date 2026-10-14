// +build arm64,!noasm

#include "textflag.h"

TEXT ·fp384Cmov(SB), NOSPLIT, $0
    MOVD x+0(FP), R0
    MOVD y+8(FP), R1
    MOVW b+16(FP), R2
    CMP $0, R2
    LDP   0(R0), (R3, R5)
    LDP   0(R1), (R4, R6)
    CSEL NE,R4,R3,R7
    CSEL NE,R6,R5,R8
    STP  (R7, R8),  0(R0)
    LDP  16(R0), (R3, R5)
    LDP  16(R1), (R4, R6)
    CSEL NE,R4,R3,R7
    CSEL NE,R6,R5,R8
    STP  (R7, R8), 16(R0)
    LDP  32(R0), (R3, R5)
    LDP  32(R1), (R4, R6)
    CSEL NE,R4,R3,R7
    CSEL NE,R6,R5,R8
    STP  (R7, R8), 32(R0)
    RET

// Compute c = -a mod p
TEXT ·fp384Neg(SB), NOSPLIT, $0-16
	MOVD	c+0(FP), R0
	MOVD	a+8(FP), R1

	// Load p in R2-R7, a in R8-R13
	// Compute p-a in R8-R13
	LDP	·p+0(SB), (R2, R3)
	LDP	0(R1), (R8, R9)
	SUBS	R8, R2, R8
	SBCS	R9, R3, R9
	LDP	·p+16(SB), (R4, R5)
	LDP	16(R1), (R10, R11)
	SBCS	R10, R4, R10
	SBCS	R11, R5, R11
	LDP	·p+32(SB), (R6, R7)
	LDP	32(R1), (R12, R13)
	SBCS	R12, R6, R12
	SBC	R13, R7, R13

	// Compute (p-a)-p in R2-R7
	SUBS	R2,  R8, R2
	SBCS	R3,  R9, R3
	SBCS	R4, R10, R4
	SBCS	R5, R11, R5
	SBCS	R6, R12, R6
	SBCS	R7, R13, R7

	// If (p-a)-p < 0 (nearly always), return p-a
	// Only return (p-a)-p for a = 0
	// Store result in c
	CSEL	CC, R8, R2, R2
	CSEL	CC, R9, R3, R3
	STP	(R2, R3), 0(R0)
	CSEL	CC, R10, R4, R4
	CSEL	CC, R11, R5, R5
	STP	(R4, R5), 16(R0)
	CSEL	CC, R12, R6, R6
	CSEL	CC, R13, R7, R7
	STP	(R6, R7), 32(R0)

	RET

// Compute c = a+b mod p
TEXT ·fp384Add(SB), NOSPLIT, $0-24
	MOVD	c+0(FP), R0
	MOVD	a+8(FP), R1
	MOVD	b+16(FP), R2

	// Load a in R3-R8, b in R9-R14
	// Compute a+b in R3-R9
	LDP	0(R1), (R3, R4)
	LDP	0(R2), (R9, R10)
	ADDS	R9, R3
	ADCS	R10, R4
	LDP	16(R1), (R5, R6)
	LDP	16(R2), (R11, R12)
	ADCS	R11, R5
	ADCS	R12, R6
	LDP	32(R1), (R7, R8)
	LDP	32(R2), (R13, R14)
	ADCS	R13, R7
	ADCS	R14, R8
	ADC	ZR, ZR, R9

	// Load p in R10-R15
	LDP	·p+ 0(SB), (R10, R11)
	LDP	·p+16(SB), (R12, R13)
	LDP	·p+32(SB), (R14, R15)

	// Compute a+b-p in R10-R16
	SUBS	R10, R3, R10
	SBCS	R11, R4, R11
	SBCS	R12, R5, R12
	SBCS	R13, R6, R13
	SBCS	R14, R7, R14
	SBCS	R15, R8, R15
	SBCS	 ZR, R9, R16

	// If a+b-p is negative, return a+b
	// Store result in c
	CSEL	CC, R3, R10, R3
	CSEL	CC, R4, R11, R4
	STP	(R3, R4), 0(R0)
	CSEL	CC, R5, R12, R5
	CSEL	CC, R6, R13, R6
	STP	(R5, R6), 16(R0)
	CSEL	CC, R7, R14, R7
	CSEL	CC, R8, R15, R8
	STP	(R7, R8), 32(R0)

	RET

// Compute c = a-b mod p
TEXT ·fp384Sub(SB), NOSPLIT, $0-24
	MOVD	c+0(FP), R0
	MOVD	a+8(FP), R1
	MOVD	b+16(FP), R2

	// Load a in R3-R8, b in R9-R14
	// Compute a-b in R3-R9
	LDP	0(R1), (R3, R4)
	LDP	0(R2), (R9, R10)
	SUBS	R9, R3
	SBCS	R10, R4
	LDP	16(R1), (R5, R6)
	LDP	16(R2), (R11, R12)
	SBCS	R11, R5
	SBCS	R12, R6
	LDP	32(R1), (R7, R8)
	LDP	32(R2), (R13, R14)
	SBCS	R13, R7
	SBCS	R14, R8
	SBC	ZR, ZR, R9

	// Load p in R10-R15
	// If a-b < 0, (a-b)+p to R3-R8
	// Store result in c
	LDP	·p+ 0(SB), (R10, R11)
	AND	R9, R10
	LDP	·p+16(SB), (R12, R13)
	AND	R9, R11
	AND	R9, R12
	LDP	·p+32(SB), (R14, R15)
	AND	R9, R13
	AND	R9, R14
	AND	R9, R15

	ADDS	R10, R3
	ADCS	R11, R4
	STP	(R3, R4), 0(R0)
	ADCS	R12, R5
	ADCS	R13, R6
	STP	(R5, R6), 16(R0)
	ADCS	R14, R7
	ADC	R15, R8
	STP	(R7, R8), 32(R0)

	RET

// Expects that A0*B0 is already in C0(low),C3(high) and A0*B1 in C1(low),C2(high)
// C0 is not actually touched
// Result of (A0-A2) * (B0-B2) will be in C0-C5
// Inputs remain intact
#define mul192x192comba(A0,A1,A2, B0,B1,B2, C0,C1,C2,C3,C4,C5, S0,S1,S2,S3) \
	MUL	A1, B0, S2	\
	UMULH	A1, B0, S3	\
				\
	ADDS	C3, C1		\
	ADCS	ZR, C2		\
	ADC	ZR, ZR, C3	\
				\
	MUL	A0, B2, S0	\
	UMULH	A0, B2, S1	\
				\
	ADDS	S2, C1		\
	ADCS	S3, C2		\
	ADC	ZR, C3		\
				\
	MUL	A1, B1, S2	\
	UMULH	A1, B1, S3	\
				\
	ADDS	S0, C2		\
	ADCS	S1, C3		\
	ADC	ZR, ZR, C4	\
				\
	MUL	A2, B0, S0	\
	UMULH	A2, B0, S1	\
				\
	ADDS	S2, C2		\
	ADCS	S3, C3		\
	ADC	ZR, C4		\
				\
	MUL	A1, B2, S2	\
	UMULH	A1, B2, S3	\
				\
	ADDS	S0, C2		\
	ADCS	S1, C3		\
	ADC	ZR, C4		\
				\
	MUL	A2, B1, S0	\
	UMULH	A2, B1, S1	\
				\
	ADDS	S2, C3		\
	ADCS	S3, C4		\
	ADC	ZR, ZR, C5	\
				\
	MUL	A2, B2, S2	\
	UMULH	A2, B2, S3	\
				\
	ADDS	S0, C3		\
	ADCS	S1, C4		\
	ADC	ZR, C5		\
				\
	ADDS	S2, C4		\
	ADC	S3, C5


// Assumes that there are at least 96 bytes left on the stack
// Expects that X and Y point to input
// X and Y get overwritten, Z0 will be in Y
#define mul384x384karatsuba(X,Y, Z1,Z2,Z3,Z4,Z5,Z6,Z7,Z8,Z9,Z10,Z11, T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12) \
	/* Load a in Z1-Z6, b in T12,Z7-Z11 */ \
	LDP	 0(X), ( Z1,  Z2)	\
	LDP	 0(Y), (T12,  Z7)	\
	MUL	Z1,  Z7, T1		\
	UMULH	Z1, T12, T3		\
	LDP	16(X), ( Z3,  Z4)	\
	LDP	16(Y), ( Z8,  Z9)	\
	MUL	Z1, T12, T0		\
	UMULH	Z1,  Z7, T2		\
	LDP	32(X), ( Z5,  Z6)	\
	LDP	32(Y), (Z10, Z11)	\
					\
	/* Compute aL*bL in T0-T5 */	\
	mul192x192comba(Z1,Z2,Z3, T12,Z7,Z8, T0,T1,T2,T3,T4,T5, T6,T7,T8,T9) \
					\
	/* Compute aH*bH in T6-T11, destroys aL and bL */ \
	MUL	Z4, Z10, T7		\
	MUL	Z4,  Z9, T6		\
	UMULH	Z4,  Z9, T9		\
	UMULH	Z4, Z10, T8		\
	mul192x192comba(Z4,Z5,Z6, Z9,Z10,Z11, T6,T7,T8,T9,T10,T11, Z1,Z2,T12,Z7) \
					\
	/* Compute aL*bL + aH*bH in Z1-Z6,T12, destroys aH */ \
	ADDS	T0,  T6,  Z1		\
	ADCS	T1,  T7,  Z2		\
	ADCS	T2,  T8,  Z3		\
	ADCS	T3,  T9,  Z4		\
	ADCS	T4, T10,  Z5		\
	ADCS	T5, T11,  Z6		\
	ADC	ZR,  ZR, T12		\
					\
	/* Add to T0-T11 and store on stack */ \
	STP	( T0,  T1), -16(RSP)	\
	ADDS	Z1, T3			\
	STP	( T2,  T3), -32(RSP)	\
	ADCS	Z2, T4			\
	ADCS	Z3, T5			\
	STP	( T4,  T5), -48(RSP)	\
	ADCS	Z4, T6			\
	ADCS	Z5, T7			\
	STP	( T6,  T7), -64(RSP)	\
	ADCS	Z6, T8			\
	ADC	ZR, T12			\
	STP	( T8,  T9), -80(RSP)	\
	STP	(T10, T11), -96(RSP)	\
					\
	/* Load a to Z1-Z6 */		\
	LDP	 0(X), (Z1, Z2)		\
	LDP	16(X), (Z3, Z4)		\
	LDP	32(X), (Z5, Z6)		\
					\
	/* Compute |aL-aH| to Z1-Z3, keep borrow in X */ \
	SUBS	Z4, Z1			\
	SBCS	Z5, Z2			\
	SBCS	Z6, Z3			\
	SBC	ZR, ZR, X		\
	NEGS	Z1, Z4			\
	NGCS	Z2, Z5			\
	NGC	Z3, Z6			\
	ADDS	$1, X			\
					\
	/* Load b to Z7-Z11,T0 */	\
	LDP	 0(Y), ( Z7,  Z8)	\
	LDP	16(Y), ( Z9, Z10)	\
	LDP	32(Y), (Z11,  T0)	\
					\
	CSEL	EQ, Z4, Z1, Z1		\
	CSEL	EQ, Z5, Z2 ,Z2		\
	CSEL	EQ, Z6, Z3, Z3		\
					\
	/* Compute |bH-bL| to Z7-Z9, keep borrow in Y */ \
	SUBS	Z7, Z10			\
	SBCS	Z8, Z11			\
	SBCS	Z9, T0			\
	SBC	ZR, ZR, Y		\
	NEGS	Z10, Z7			\
	NGCS	Z11, Z8			\
	NGC	T0, Z9			\
	ADDS	$1, Y			\
	CSEL	EQ, Z7, Z10, Z7		\
	CSEL	EQ, Z8, Z11, Z8		\
	CSEL	EQ, Z9,  T0, Z9		\
					\
	/* Combine borrows */		\
	EOR	Y, X			\
					\
	/* Compute |aL-aH|*|bH-bL| to Z10,Z11,T0-T3 */ \
	MUL	Z1, Z8, Z11		\
	MUL	Z1, Z7, Z10		\
	UMULH	Z1, Z8,  T0		\
	UMULH	Z1, Z7,  T1		\
	mul192x192comba(Z1,Z2,Z3, Z7,Z8,Z9, Z10,Z11,T0,T1,T2,T3, T4,T5,T6,T7) \
					\
	/* The result has to be negated if exactly one of the operands was negative */ \
	NEGS	Z10,  Y			\
	NGCS	Z11, Z1			\
	NGCS	 T0, Z2			\
	NGCS	 T1, Z3			\
	NGCS	 T2, Z4			\
	NGCS	 T3, Z5			\
	NGC	 ZR, T4			\
					\
	AND	T4, X			\
	CMP	$1, X			\
	CSEL	EQ,  Y, Z10, Z10	\
	CSEL	EQ, Z1, Z11, Z11	\
	CSEL	EQ, Z2,  T0,  T0	\
	CSEL	EQ, Z3,  T1,  T1	\
	CSEL	EQ, Z4,  T2,  T2	\
	CSEL	EQ, Z5,  T3,  T3	\
					\
	/* Add that to the middle part */ \
	LDP	-16(RSP), (  Y,  Z1)	\
	LDP	-32(RSP), ( Z2,  Z3)	\
	LDP	-48(RSP), ( Z4,  Z5)	\
	ADDS	Z10, Z3			\
	ADCS	Z11, Z4			\
	LDP	-64(RSP), ( Z6,  Z7)	\
	ADCS	T0, Z5			\
	ADCS	T1, Z6			\
	LDP	-80(RSP), ( Z8,  Z9)	\
	ADCS	T2, Z7			\
	ADCS	T3, Z8			\
	LDP	-96(RSP), (Z10, Z11)	\
	ADCS	T12, Z9			\
	ADCS	ZR, Z10			\
	ADC	ZR, Z11			\
	SUBS	X, Z9			\
	SBCS	ZR, Z10			\
	SBC	ZR, Z11

// Compute c = a*b*R^-1 mod p
TEXT ·fp384Mul(SB), NOSPLIT, $200-24
	MOVD	c+0(FP), R0
	MOVD	a+8(FP), R1
	MOVD	b+16(FP), R2

	// Compute a*b in R2-R13
	mul384x384karatsuba(R1, R2, R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,R13, R14,R15,R16,R17,R19,R20,R21,R22,R23,R24,R25,R26,R27)

	// Store a*b on the stack
	STP	( R2,  R3), -112(RSP)
	STP	( R4,  R5), -128(RSP)
	STP	( R6,  R7), -144(RSP)
	STP	( R8,  R9), -160(RSP)
	STP	(R10, R11), -176(RSP)
	STP	(R12, R13), -192(RSP)

	// Compute m = a*b*pp mod 2^384 in R19-R24
	// Store it temporarily in c
	MOVD	·pp+0(SB), R14
	MUL	R14, R2, R19
	UMULH	R14, R2, R20

	MUL	R14, R3, R16
	UMULH	R14, R3, R21
	ADDS	R16, R20
	ADC	 ZR, R21

	MUL	R14, R4, R16
	UMULH	R14, R4, R22
	ADDS	R16, R21
	ADC	 ZR, R22

	MUL	R14, R5, R16
	UMULH	R14, R5, R23
	ADDS	R16, R22
	ADC	 ZR, R23

	MUL	R14, R6, R16
	UMULH	R14, R6, R24
	ADDS	R16, R23
	ADC	 ZR, R24

	MADD	R14, R24, R7, R24

	// ·pp+8(SB) = 1, so we can just add
	ADDS	R2, R20
	STP	(R19, R20), 0(R0)
	ADCS	R3, R21
	ADCS	R4, R22
	ADCS	R5, R23
	ADC	R6, R24

	LDP	·pp+16(SB), (R14, R15)
	MUL	R14, R2, R8
	UMULH	R14, R2, R9

	MUL	R14, R3, R16
	UMULH	R14, R3, R10
	ADDS	R16, R9
	ADC	 ZR, R10

	MUL	R14, R4, R16
	UMULH	R14, R4, R11
	ADDS	R16, R10
	ADC	 ZR, R11

	MUL	R14, R5, R16
	ADD	R16, R11

	ADDS	 R8, R21
	ADCS	 R9, R22
	ADCS	R10, R23
	ADC	R11, R24

	MUL	R15, R2, R8
	UMULH	R15, R2, R9

	MUL	R15, R3, R16
	UMULH	R15, R3, R10
	ADDS	R16, R9
	ADC	 ZR, R10

	MADD	R15, R10, R4, R10

	ADDS	R8, R22
	STP	(R21, R22), 16(R0)
	ADCS	R9, R23
	ADC	R10, R24

	LDP	·pp+32(SB), (R14, R15)
	MUL	R14, R2, R8
	UMULH	R14, R2, R9

	MADD	R14, R9, R3, R9

	ADDS	R8, R23
	ADC	R9, R24

	MADD	R15, R24, R2, R24
	STP	(R23, R24), 32(R0)

	// Compute m*p in R1-R12
	MOVD	$·p(SB), R1
	mul384x384karatsuba(R0, R1, R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12, R13,R14,R15,R16,R17,R19,R20,R21,R22,R23,R24,R25,R26)

	// Add a*b to m*p in R1-R12,R26
	LDP	-112(RSP), (R13, R14)
	ADDS	R13, R1
	LDP	-128(RSP), (R15, R16)
	ADCS	R14, R2
	ADCS	R15, R3
	LDP	-144(RSP), (R17, R19)
	ADCS	R16, R4
	ADCS	R17, R5
	LDP	-160(RSP), (R20, R21)
	ADCS	R19, R6
	ADCS	R20, R7
	LDP	-176(RSP), (R22, R23)
	ADCS	R21, R8
	ADCS	R22, R9
	LDP	-192(RSP), (R24, R25)
	ADCS	R23, R10
	ADCS	R24, R11
	ADCS	R25, R12
	ADC	ZR, ZR, R26

	// Reduce the top half mod p
	LDP	·p+ 0(SB), (R13, R14)
	SUBS	R13, R7, R13
	LDP	·p+16(SB), (R15, R16)
	SBCS	R14, R8, R14
	SBCS	R15, R9, R15
	LDP	·p+32(SB), (R17, R19)
	SBCS	R16, R10, R16
	SBCS	R17, R11, R17
	SBCS	R19, R12, R19
	SBCS	ZR, R26

	// Store result in c
	MOVD	c+0(FP), R0
	CSEL	CC, R7, R13, R7
	CSEL	CC, R8, R14, R8
	STP	( R7,  R8),  0(R0)
	CSEL	CC, R9, R15, R9
	CSEL	CC, R10, R16, R10
	STP	( R9, R10), 16(R0)
	CSEL	CC, R11, R17, R11
	CSEL	CC, R12, R19, R12
	STP	(R11, R12), 32(R0)

	RET
