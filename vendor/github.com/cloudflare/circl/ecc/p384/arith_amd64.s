// +build amd64,!noasm

#include "textflag.h"

#define storeBlock(a0,a1,a2,a3,a4,a5, r) \
	MOVQ a0,  0+r \
	MOVQ a1,  8+r \
	MOVQ a2, 16+r \
	MOVQ a3, 24+r \
	MOVQ a4, 32+r \
	MOVQ a5, 40+r

#define loadBlock(r, a0,a1,a2,a3,a4,a5) \
	MOVQ  0+r, a0 \
	MOVQ  8+r, a1 \
	MOVQ 16+r, a2 \
	MOVQ 24+r, a3 \
	MOVQ 32+r, a4 \
	MOVQ 40+r, a5

#define fp384Carry(a0,a1,a2,a3,a4,a5,a6, b0,b1,b2,b3,b4,b5,b6) \
	\ // b = a-p
	MOVQ a0, b0 \
	MOVQ a1, b1 \
	MOVQ a2, b2 \
	MOVQ a3, b3 \
	MOVQ a4, b4 \
	MOVQ a5, b5 \
	MOVQ a6, b6 \
	\
	SUBQ ·p+0(SB), b0 \
	SBBQ ·p+8(SB), b1 \
	SBBQ ·p+16(SB), b2 \
	SBBQ ·p+24(SB), b3 \
	SBBQ ·p+32(SB), b4 \
	SBBQ ·p+40(SB), b5 \
	SBBQ $0, b6 \
	\
	\ // if b is negative then return a
	\ // else return b
	CMOVQCC b0, a0 \
	CMOVQCC b1, a1 \
	CMOVQCC b2, a2 \
	CMOVQCC b3, a3 \
	CMOVQCC b4, a4 \
	CMOVQCC b5, a5

#define mul(a0,a1,a2,a3,a4,a5, rb, stack) \
	\ // a0
	MOVQ a0, AX \
	MULQ 0+rb \
	MOVQ AX, R8 \
	MOVQ DX, R9 \
	MOVQ a0, AX \
	MULQ 8+rb \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ a0, AX \
	MULQ 16+rb \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ a0, AX \
	MULQ 24+rb \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ a0, AX \
	MULQ 32+rb \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ a0, AX \
	MULQ 40+rb \
	ADDQ AX, R13 \
	ADCQ $0, DX \
	MOVQ DX, R14 \
	\
	storeBlock(R8,R9,R10,R11,R12,R13, 0+stack) \
	MOVQ R14, 48+stack \
	\
	\ // a1
	MOVQ a1, AX \
	MULQ 0+rb \
	MOVQ AX, R8 \
	MOVQ DX, R9 \
	MOVQ a1, AX \
	MULQ 8+rb \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ a1, AX \
	MULQ 16+rb \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ a1, AX \
	MULQ 24+rb \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ a1, AX \
	MULQ 32+rb \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ a1, AX \
	MULQ 40+rb \
	ADDQ AX, R13 \
	ADCQ $0, DX \
	MOVQ DX, R14 \
	\
	ADDQ 8+stack, R8 \
	ADCQ 16+stack, R9 \
	ADCQ 24+stack, R10 \
	ADCQ 32+stack, R11 \
	ADCQ 40+stack, R12 \
	ADCQ 48+stack, R13 \
	ADCQ $0, R14 \
	storeBlock(R8,R9,R10,R11,R12,R13, 8+stack) \
	MOVQ R14, 56+stack \
	\
	\ // a2
	MOVQ a2, AX \
	MULQ 0+rb \
	MOVQ AX, R8 \
	MOVQ DX, R9 \
	MOVQ a2, AX \
	MULQ 8+rb \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ a2, AX \
	MULQ 16+rb \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ a2, AX \
	MULQ 24+rb \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ a2, AX \
	MULQ 32+rb \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ a2, AX \
	MULQ 40+rb \
	ADDQ AX, R13 \
	ADCQ $0, DX \
	MOVQ DX, R14 \
	\
	ADDQ 16+stack, R8 \
	ADCQ 24+stack, R9 \
	ADCQ 32+stack, R10 \
	ADCQ 40+stack, R11 \
	ADCQ 48+stack, R12 \
	ADCQ 56+stack, R13 \
	ADCQ $0, R14 \
	storeBlock(R8,R9,R10,R11,R12,R13, 16+stack) \
	MOVQ R14, 64+stack \
	\
	\ // a3
	MOVQ a3, AX \
	MULQ 0+rb \
	MOVQ AX, R8 \
	MOVQ DX, R9 \
	MOVQ a3, AX \
	MULQ 8+rb \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ a3, AX \
	MULQ 16+rb \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ a3, AX \
	MULQ 24+rb \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ a3, AX \
	MULQ 32+rb \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ a3, AX \
	MULQ 40+rb \
	ADDQ AX, R13 \
	ADCQ $0, DX \
	MOVQ DX, R14 \
	\
	ADDQ 24+stack, R8 \
	ADCQ 32+stack, R9 \
	ADCQ 40+stack, R10 \
	ADCQ 48+stack, R11 \
	ADCQ 56+stack, R12 \
	ADCQ 64+stack, R13 \
	ADCQ $0, R14 \
	storeBlock(R8,R9,R10,R11,R12,R13, 24+stack) \
	MOVQ R14, 72+stack \
	\
	\ // a4
	MOVQ a4, AX \
	MULQ 0+rb \
	MOVQ AX, R8 \
	MOVQ DX, R9 \
	MOVQ a4, AX \
	MULQ 8+rb \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ a4, AX \
	MULQ 16+rb \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ a4, AX \
	MULQ 24+rb \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ a4, AX \
	MULQ 32+rb \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ a4, AX \
	MULQ 40+rb \
	ADDQ AX, R13 \
	ADCQ $0, DX \
	MOVQ DX, R14 \
	\
	ADDQ 32+stack, R8 \
	ADCQ 40+stack, R9 \
	ADCQ 48+stack, R10 \
	ADCQ 56+stack, R11 \
	ADCQ 64+stack, R12 \
	ADCQ 72+stack, R13 \
	ADCQ $0, R14 \
	storeBlock(R8,R9,R10,R11,R12,R13, 32+stack) \
	MOVQ R14, 80+stack \
	\
	\ // a5
	MOVQ a5, AX \
	MULQ 0+rb \
	MOVQ AX, R8 \
	MOVQ DX, R9 \
	MOVQ a5, AX \
	MULQ 8+rb \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ a5, AX \
	MULQ 16+rb \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ a5, AX \
	MULQ 24+rb \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ a5, AX \
	MULQ 32+rb \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ a5, AX \
	MULQ 40+rb \
	ADDQ AX, R13 \
	ADCQ $0, DX \
	MOVQ DX, R14 \
	\
	ADDQ 40+stack, R8 \
	ADCQ 48+stack, R9 \
	ADCQ 56+stack, R10 \
	ADCQ 64+stack, R11 \
	ADCQ 72+stack, R12 \
	ADCQ 80+stack, R13 \
	ADCQ $0, R14 \
	storeBlock(R8,R9,R10,R11,R12,R13, 40+stack) \
	MOVQ R14, 88+stack

#define fp384Reduce(stack) \
	\ // m = (T * P') mod R, store m in R8:R9:R10:R11:R12:R13
	MOVQ ·pp+0(SB), AX \
	MULQ 0+stack \
	MOVQ AX, R8 ; MOVQ R8, 96+stack\
	MOVQ DX, R9 \
	MOVQ ·pp+0(SB), AX \
	MULQ 8+stack \
	ADDQ AX, R9 \
	ADCQ $0, DX \
	MOVQ DX, R10 \
	MOVQ ·pp+0(SB), AX \
	MULQ 16+stack \
	ADDQ AX, R10 \
	ADCQ $0, DX \
	MOVQ DX, R11 \
	MOVQ ·pp+0(SB), AX \
	MULQ 24+stack \
	ADDQ AX, R11 \
	ADCQ $0, DX \
	MOVQ DX, R12 \
	MOVQ ·pp+0(SB), AX \
	MULQ 32+stack \
	ADDQ AX, R12 \
	ADCQ $0, DX \
	MOVQ DX, R13 \
	MOVQ ·pp+0(SB), AX \
	MULQ 40+stack \
	ADDQ AX, R13 \
	\
	ADDQ 0+stack, R9 \
	ADCQ 8+stack, R10 \
	ADCQ 16+stack, R11 \
	ADCQ 24+stack, R12 \
	ADCQ 32+stack, R13 \
	\
	MOVQ ·pp+16(SB), AX \
	MULQ 0+stack \
	MOVQ AX, R14 \
	MOVQ DX, R8 \
	MOVQ ·pp+16(SB), AX \
	MULQ 8+stack \
	ADDQ AX, R8 \
	ADCQ $0, DX \
	MOVQ DX, BX \
	MOVQ ·pp+16(SB), AX \
	MULQ 16+stack \
	ADDQ AX, BX \
	ADCQ $0, DX \
	MOVQ DX, CX \
	MOVQ ·pp+16(SB), AX \
	MULQ 24+stack \
	ADDQ AX, CX \
	\
	ADDQ R14, R10 \
	ADCQ R8, R11 \
	ADCQ BX, R12 \
	ADCQ CX, R13 \
	\
	MOVQ ·pp+24(SB), AX \
	MULQ 0+stack \
	MOVQ AX, R14 \
	MOVQ DX, R8 \
	MOVQ ·pp+24(SB), AX \
	MULQ 8+stack \
	ADDQ AX, R8 \
	ADCQ $0, DX \
	MOVQ DX, BX \
	MOVQ ·pp+24(SB), AX \
	MULQ 16+stack \
	ADDQ AX, BX \
	\
	ADDQ R14, R11 \
	ADCQ R8, R12 \
	ADCQ BX, R13 \
	\
	MOVQ ·pp+32(SB), AX \
	MULQ 0+stack \
	MOVQ AX, R14 \
	MOVQ DX, R8 \
	MOVQ ·pp+32(SB), AX \
	MULQ 8+stack \
	ADDQ AX, R8 \
	\
	ADDQ R14, R12 \
	ADCQ R8, R13 \
	\
	MOVQ ·pp+40(SB), AX \
	MULQ 0+stack \
	ADDQ AX, R13 \
	\
	MOVQ 96+stack, R8 \
	\
	storeBlock(R8,R9,R10,R11,R12,R13, 96+stack) \
	\
	\ // m * P
	mul(·p+0(SB),·p+8(SB),·p+16(SB),·p+24(SB),·p+32(SB),·p+40(SB), 96+stack, 144+stack) \
	\
	\ // Add the 768-bit intermediate to m*N
	MOVQ $0, R15 \
	loadBlock(144+stack, R8,R9,R10,R11,R12,R13) \
	loadBlock(192+stack, R14,SI,AX,BX,CX,DX) \
	\
	ADDQ 0+stack, R8 \
	ADCQ 8+stack, R9 \
	ADCQ 16+stack, R10 \
	ADCQ 24+stack, R11 \
	ADCQ 32+stack, R12 \
	ADCQ 40+stack, R13 \
	ADCQ 48+stack, R14 \
	ADCQ 56+stack, SI \
	ADCQ 64+stack, AX \
	ADCQ 72+stack, BX \
	ADCQ 80+stack, CX \
	ADCQ 88+stack, DX \
	ADCQ $0, R15 \
	\
	fp384Carry(R14,SI,AX,BX,CX,DX,R15, R8,R9,R10,R11,R12,R13,DI)

#define mulBMI2(a0,a1,a2,a3,a4,a5, rb, stack) \
	MOVQ a0, DX \
	MULXQ 0+rb, R8, R9; MOVQ R8, 0+stack; MOVQ $0, R8 \
	MULXQ 8+rb, AX, R10 \
	ADDQ AX, R9 \
	MULXQ 16+rb, AX, R11 \
	ADCQ AX, R10 \
	MULXQ 24+rb, AX, R12 \
	ADCQ AX, R11 \
	MULXQ 32+rb, AX, R13 \
	ADCQ AX, R12 \
	MULXQ 40+rb, AX, R14 \
	ADCQ AX, R13 \
	ADCQ $0, R14 \
	\
	MOVQ a1, DX \
	MULXQ 0+rb, AX, BX \
	ADDQ AX, R9; MOVQ R9, 8+stack; MOVL $0, R9 \
	ADCQ BX, R10 \
	MULXQ 16+rb, AX, BX \
	ADCQ AX, R11 \
	ADCQ BX, R12 \
	MULXQ 32+rb, AX, BX \
	ADCQ AX, R13 \
	ADCQ BX, R14 \
	ADCQ $0,  R8 \
	MULXQ 8+rb, AX, BX \
	ADDQ AX, R10 \
	ADCQ BX, R11 \
	MULXQ 24+rb, AX, BX \
	ADCQ AX, R12 \
	ADCQ BX, R13 \
	MULXQ 40+rb, AX, BX \
	ADCQ AX, R14 \
	ADCQ BX, R8 \
	ADCQ $0, R9 \
	\
	MOVQ a2, DX \
	MULXQ 0+rb, AX, BX \
	ADDQ AX, R10; MOVQ R10, 16+stack; MOVL $0, R10 \
	ADCQ BX, R11 \
	MULXQ 16+rb, AX, BX \
	ADCQ AX, R12 \
	ADCQ BX, R13 \
	MULXQ 32+rb, AX, BX \
	ADCQ AX, R14 \
	ADCQ BX, R8 \
	ADCQ $0, R9 \
	MULXQ 8+rb, AX, BX \
	ADDQ AX, R11 \
	ADCQ BX, R12 \
	MULXQ 24+rb, AX, BX \
	ADCQ AX, R13 \
	ADCQ BX, R14 \
	MULXQ 40+rb, AX, BX \
	ADCQ AX, R8 \
	ADCQ BX, R9 \
	ADCQ $0, R10 \
	\
	MOVQ a3, DX \
	MULXQ 0+rb, AX, BX \
	ADDQ AX, R11; MOVQ R11, 24+stack; MOVL $0, R11 \
	ADCQ BX, R12 \
	MULXQ 16+rb, AX, BX \
	ADCQ AX, R13 \
	ADCQ BX, R14 \
	MULXQ 32+rb, AX, BX \
	ADCQ AX, R8 \
	ADCQ BX, R9 \
	ADCQ $0, R10 \
	MULXQ 8+rb, AX, BX \
	ADDQ AX, R12 \
	ADCQ BX, R13 \
	MULXQ 24+rb, AX, BX \
	ADCQ AX, R14 \
	ADCQ BX, R8 \
	MULXQ 40+rb, AX, BX \
	ADCQ AX, R9 \
	ADCQ BX, R10 \
	ADCQ $0, R11 \
	\
	MOVQ a4, DX \
	MULXQ 0+rb, AX, BX \
	ADDQ AX, R12; MOVQ R12, 32+stack; MOVL $0, R12 \
	ADCQ BX, R13 \
	MULXQ 16+rb, AX, BX \
	ADCQ AX, R14 \
	ADCQ BX, R8 \
	MULXQ 32+rb, AX, BX \
	ADCQ AX, R9 \
	ADCQ BX, R10 \
	ADCQ $0, R11 \
	MULXQ 8+rb, AX, BX \
	ADDQ AX, R13 \
	ADCQ BX, R14 \
	MULXQ 24+rb, AX, BX \
	ADCQ AX, R8 \
	ADCQ BX, R9 \
	MULXQ 40+rb, AX, BX \
	ADCQ AX, R10 \
	ADCQ BX, R11 \
	ADCQ $0, R12 \
	\
	MOVQ a5, DX \
	MULXQ 0+rb, AX, BX \
	ADDQ AX, R13; MOVQ R13, 40+stack \
	ADCQ BX, R14 \
	MULXQ 16+rb, AX, BX \
	ADCQ AX, R8 \
	ADCQ BX, R9 \
	MULXQ 32+rb, AX, BX \
	ADCQ AX, R10 \
	ADCQ BX, R11 \
	ADCQ $0, R12 \
	MULXQ 8+rb, AX, BX \
	ADDQ AX, R14 \
	ADCQ BX, R8 \
	MULXQ 24+rb, AX, BX \
	ADCQ AX, R9 \
	ADCQ BX, R10 \
	MULXQ 40+rb, AX, BX \
	ADCQ AX, R11 \
	ADCQ BX, R12

#define fp384ReduceBMI2(stack) \
	\ // m = (T * P') mod R, store m in R8:R9:R10:R11:R12:R13
	MOVQ ·pp+0(SB), DX \
	MULXQ 0+stack, R8, R9 \
	MULXQ 8+stack, AX, R10 \
	ADDQ AX, R9 \
	MULXQ 16+stack, AX, R11 \
	ADCQ AX, R10 \
	MULXQ 24+stack, AX, R12 \
	ADCQ AX, R11 \
	MULXQ 32+stack, AX, R13 \
	ADCQ AX, R12 \
	MULXQ 40+stack, AX, BX \
	ADCQ AX, R13 \
	\
	ADDQ 0+stack, R9 \
	ADCQ 8+stack, R10 \
	ADCQ 16+stack, R11 \
	ADCQ 24+stack, R12 \
	ADCQ 32+stack, R13 \
	\
	MOVQ ·pp+16(SB), DX \
	MULXQ 0+stack, AX, BX \
	ADDQ AX, R10 \
	ADCQ BX, R11 \
	MULXQ 16+stack, AX, BX \
	ADCQ AX, R12 \
	ADCQ BX, R13 \
	MULXQ 8+stack, AX, BX \
	ADDQ AX, R11 \
	ADCQ BX, R12 \
	MULXQ 24+stack, AX, BX \
	ADCQ AX, R13 \
	\
	MOVQ ·pp+24(SB), DX \
	MULXQ 0+stack, AX, BX \
	ADDQ AX, R11 \
	ADCQ BX, R12 \
	MULXQ 16+stack, AX, BX \
	ADCQ AX, R13 \
	MULXQ 8+stack, AX, BX \
	ADDQ AX, R12 \
	ADCQ BX, R13 \
	\
	MOVQ ·pp+32(SB), DX \
	MULXQ 0+stack, AX, BX \
	ADDQ AX, R12 \
	ADCQ BX, R13 \
	MULXQ 8+stack, AX, BX \
	ADDQ AX, R13 \
	\
	MOVQ ·pp+40(SB), DX \
	MULXQ 0+stack, AX, BX \
	ADDQ AX, R13 \
	\
	storeBlock(R8,R9,R10,R11,R12,R13, 96+stack) \
	\
	\ // m * P
	mulBMI2(·p+0(SB),·p+8(SB),·p+16(SB),·p+24(SB),·p+32(SB),·p+40(SB), 96+stack, 144+stack) \
	\
	\ // Add the 768-bit intermediate to m*N
	loadBlock(144+stack, AX,R13,BX,CX,DX,DI) \
	\
	ADDQ 0+stack,  AX \
	ADCQ 8+stack, R13 \
	ADCQ 16+stack, BX \
	ADCQ 24+stack, CX \
	ADCQ 32+stack, DX \
	ADCQ 40+stack, DI \
	ADCQ 48+stack, R14 \
	ADCQ 56+stack, R8 \
	ADCQ 64+stack, R9 \
	ADCQ 72+stack, R10 \
	ADCQ 80+stack, R11 \
	ADCQ 88+stack, R12 \
	MOVQ $0, 0+stack \
	ADCQ $0, 0+stack \
	\
	fp384Carry(R14,R8,R9,R10,R11,R12, 0+stack, AX,R13,BX,CX,DX,DI,SI)

TEXT ·fp384Neg(SB), NOSPLIT, $0-16
	MOVQ ·p+0(SB), R8
	MOVQ ·p+8(SB), R9
	MOVQ ·p+16(SB), R10
	MOVQ ·p+24(SB), R11
	MOVQ ·p+32(SB), R12
	MOVQ ·p+40(SB), R13

	MOVQ a+8(FP), DI
	SUBQ 0(DI), R8
	SBBQ 8(DI), R9
	SBBQ 16(DI), R10
	SBBQ 24(DI), R11
	SBBQ 32(DI), R12
	SBBQ 40(DI), R13

	MOVQ $0, R15
	fp384Carry(R8,R9,R10,R11,R12,R13,R15, R14,AX,BX,CX,DX,DI,SI)

	MOVQ c+0(FP), DI
	storeBlock(R8,R9,R10,R11,R12,R13, 0(DI))
	RET

TEXT ·fp384Add(SB), NOSPLIT, $0-24
	MOVQ a+8(FP), DI
	MOVQ b+16(FP), SI

	loadBlock(0(DI), R8,R9,R10,R11,R12,R13)
	MOVQ $0, R15

	ADDQ  0(SI), R8
	ADCQ  8(SI), R9
	ADCQ 16(SI), R10
	ADCQ 24(SI), R11
	ADCQ 32(SI), R12
	ADCQ 40(SI), R13
	ADCQ $0, R15

	fp384Carry(R8,R9,R10,R11,R12,R13,R15, R14,AX,BX,CX,DX,DI,SI)

	MOVQ c+0(FP), DI
	storeBlock(R8,R9,R10,R11,R12,R13, 0(DI))
	RET

TEXT ·fp384Sub(SB), NOSPLIT, $0-24
	MOVQ ·p+0(SB), R8
	MOVQ ·p+8(SB), R9
	MOVQ ·p+16(SB), R10
	MOVQ ·p+24(SB), R11
	MOVQ ·p+32(SB), R12
	MOVQ ·p+40(SB), R13

	MOVQ b+16(FP), DI
	SUBQ 0(DI), R8
	SBBQ 8(DI), R9
	SBBQ 16(DI), R10
	SBBQ 24(DI), R11
	SBBQ 32(DI), R12
	SBBQ 40(DI), R13

	MOVQ $0, R15
	MOVQ a+8(FP), DI
	ADDQ 0(DI), R8
	ADCQ 8(DI), R9
	ADCQ 16(DI), R10
	ADCQ 24(DI), R11
	ADCQ 32(DI), R12
	ADCQ 40(DI), R13
	ADCQ $0, R15

	fp384Carry(R8,R9,R10,R11,R12,R13,R15, R14,AX,BX,CX,DX,DI,SI)

	MOVQ c+0(FP), DI
	storeBlock(R8,R9,R10,R11,R12,R13, 0(DI))
	RET

TEXT ·fp384Mul(SB), NOSPLIT, $240-24
	MOVQ a+8(FP), DI
	MOVQ b+16(FP), SI

	// Jump to a slightly different implementation if MULX isn't supported.
	CMPB ·hasBMI2(SB), $0
	JE   nobmi2Mul

	// T = a * b
	mulBMI2(0(DI),8(DI),16(DI),24(DI),32(DI),40(DI), 0(SI), 0(SP))
	storeBlock(R14,R8,R9,R10,R11,R12, 48(SP))

	// Reduce T.
	fp384ReduceBMI2(0(SP))

	MOVQ c+0(FP), DI
	storeBlock(R14,R8,R9,R10,R11,R12, 0(DI))
	JMP end

nobmi2Mul:
	// T = a * b
	mul(0(DI),8(DI),16(DI),24(DI),32(DI),40(DI), 0(SI), 0(SP))

	// Reduce T.
	fp384Reduce(0(SP))

	MOVQ c+0(FP), DI
	storeBlock(R14,SI,AX,BX,CX,DX, 0(DI))

end:
	RET

TEXT ·fp384Cmov(SB), NOSPLIT, $0
    MOVQ x+0(FP), DI
    MOVQ y+8(FP), SI
    MOVQ b+16(FP), BX
    TESTQ BX, BX
    MOVQ  0(DI), AX; MOVQ  0(SI), DX; CMOVQNE DX, AX; MOVQ AX,  0(DI);
    MOVQ  8(DI), AX; MOVQ  8(SI), DX; CMOVQNE DX, AX; MOVQ AX,  8(DI);
    MOVQ 16(DI), AX; MOVQ 16(SI), DX; CMOVQNE DX, AX; MOVQ AX, 16(DI);
    MOVQ 24(DI), AX; MOVQ 24(SI), DX; CMOVQNE DX, AX; MOVQ AX, 24(DI);
    MOVQ 32(DI), AX; MOVQ 32(SI), DX; CMOVQNE DX, AX; MOVQ AX, 32(DI);
    MOVQ 40(DI), AX; MOVQ 40(SI), DX; CMOVQNE DX, AX; MOVQ AX, 40(DI);
    RET
