	.attribute	4, 16
	.attribute	5, "rv32i2p1"
	.file	"display.c"
	.text
	.globl	DisplayInit                     # -- Begin function DisplayInit
	.p2align	2
	.type	DisplayInit,@function
DisplayInit:                            # @DisplayInit
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	sw	s0, 8(sp)                       # 4-byte Folded Spill
	lui	s0, %hi(display)
	addi	s0, s0, %lo(display)
	li	a2, 976
	mv	a0, s0
	li	a1, 0
	call	memset
	li	a0, 17
	sw	a0, 8(s0)
	sw	a0, 20(s0)
	sw	a0, 32(s0)
	sw	a0, 44(s0)
	sw	a0, 56(s0)
	sw	a0, 68(s0)
	sw	a0, 80(s0)
	sw	a0, 92(s0)
	sw	a0, 104(s0)
	sw	a0, 116(s0)
	sw	a0, 128(s0)
	sw	a0, 140(s0)
	sw	a0, 152(s0)
	sw	a0, 164(s0)
	sw	a0, 176(s0)
	sw	a0, 188(s0)
	sw	a0, 200(s0)
	sw	a0, 212(s0)
	sw	a0, 224(s0)
	sw	a0, 236(s0)
	sw	a0, 248(s0)
	sw	a0, 260(s0)
	sw	a0, 272(s0)
	sw	a0, 284(s0)
	sw	a0, 296(s0)
	sw	a0, 308(s0)
	sw	a0, 320(s0)
	sw	a0, 332(s0)
	sw	a0, 344(s0)
	sw	a0, 356(s0)
	sw	a0, 368(s0)
	sw	a0, 380(s0)
	sw	a0, 392(s0)
	sw	a0, 404(s0)
	sw	a0, 416(s0)
	sw	a0, 428(s0)
	sw	a0, 440(s0)
	sw	a0, 452(s0)
	sw	a0, 464(s0)
	sw	a0, 476(s0)
	sw	a0, 488(s0)
	sw	a0, 500(s0)
	sw	a0, 512(s0)
	sw	a0, 524(s0)
	sw	a0, 536(s0)
	sw	a0, 548(s0)
	sw	a0, 560(s0)
	sw	a0, 572(s0)
	sw	a0, 584(s0)
	sw	a0, 596(s0)
	sw	a0, 608(s0)
	sw	a0, 620(s0)
	sw	a0, 632(s0)
	sw	a0, 644(s0)
	sw	a0, 656(s0)
	sw	a0, 668(s0)
	sw	a0, 680(s0)
	sw	a0, 692(s0)
	sw	a0, 704(s0)
	sw	a0, 716(s0)
	sw	a0, 728(s0)
	sw	a0, 740(s0)
	sw	a0, 752(s0)
	sw	a0, 764(s0)
	sw	a0, 776(s0)
	sw	a0, 788(s0)
	sw	a0, 800(s0)
	sw	a0, 812(s0)
	sw	a0, 824(s0)
	sw	a0, 836(s0)
	sw	a0, 848(s0)
	sw	a0, 860(s0)
	sw	a0, 872(s0)
	sw	a0, 884(s0)
	sw	a0, 896(s0)
	sw	a0, 908(s0)
	sw	a0, 920(s0)
	sw	a0, 932(s0)
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.Lfunc_end0:
	.size	DisplayInit, .Lfunc_end0-DisplayInit
                                        # -- End function
	.globl	DisplayInitChar                 # -- Begin function DisplayInitChar
	.p2align	2
	.type	DisplayInitChar,@function
DisplayInitChar:                        # @DisplayInitChar
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	sw	s0, 8(sp)                       # 4-byte Folded Spill
	sw	s1, 4(sp)                       # 4-byte Folded Spill
	sw	s2, 0(sp)                       # 4-byte Folded Spill
	mv	s0, a2
	mv	s1, a1
	li	a1, 12
	call	__mulsi3
	mv	s2, a0
	li	a1, 156
	mv	a0, s1
	call	__mulsi3
	lw	a1, 0(s0)
	lui	a2, %hi(display)
	addi	a2, a2, %lo(display)
	add	a0, a2, a0
	add	a0, a0, s2
	sw	a1, 0(a0)
	lw	a1, 4(s0)
	li	a2, 17
	sw	a1, 4(a0)
	sw	a2, 8(a0)
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	lw	s1, 4(sp)                       # 4-byte Folded Reload
	lw	s2, 0(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.Lfunc_end1:
	.size	DisplayInitChar, .Lfunc_end1-DisplayInitChar
                                        # -- End function
	.globl	DisplayInitRectangle            # -- Begin function DisplayInitRectangle
	.p2align	2
	.type	DisplayInitRectangle,@function
DisplayInitRectangle:                   # @DisplayInitRectangle
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	sw	s0, 8(sp)                       # 4-byte Folded Spill
	mv	s0, a1
	li	a1, 10
	call	__mulsi3
	lui	a1, %hi(display)
	addi	a1, a1, %lo(display)
	add	a0, a1, a0
	lh	a1, 0(s0)
	lh	a2, 2(s0)
	lh	a3, 4(s0)
	lh	a4, 6(s0)
	sh	a1, 936(a0)
	sh	a2, 938(a0)
	sh	a3, 940(a0)
	sh	a4, 942(a0)
	sh	zero, 944(a0)
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.Lfunc_end2:
	.size	DisplayInitRectangle, .Lfunc_end2-DisplayInitRectangle
                                        # -- End function
	.globl	DisplaySetRectangleColor        # -- Begin function DisplaySetRectangleColor
	.p2align	2
	.type	DisplaySetRectangleColor,@function
DisplaySetRectangleColor:               # @DisplaySetRectangleColor
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	sw	s0, 8(sp)                       # 4-byte Folded Spill
	mv	s0, a1
	li	a1, 10
	call	__mulsi3
	lui	a4, %hi(display)
	addi	a4, a4, %lo(display)
	add	a4, a4, a0
	lhu	a0, 944(a4)
	bne	a0, s0, .LBB3_2
# %bb.1:
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.LBB3_2:
	lhu	a0, 936(a4)
	lhu	a1, 938(a4)
	lhu	a2, 940(a4)
	lhu	a3, 942(a4)
	sh	s0, 944(a4)
	mv	a4, s0
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	tail	LcdRectFill
.Lfunc_end3:
	.size	DisplaySetRectangleColor, .Lfunc_end3-DisplaySetRectangleColor
                                        # -- End function
	.globl	DisplaySetChar                  # -- Begin function DisplaySetChar
	.p2align	2
	.type	DisplaySetChar,@function
DisplaySetChar:                         # @DisplaySetChar
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	sw	s0, 8(sp)                       # 4-byte Folded Spill
	sw	s1, 4(sp)                       # 4-byte Folded Spill
	mv	s0, a2
	mv	a2, a1
	slli	a1, a0, 2
	slli	a0, a0, 4
	sub	s1, a0, a1
	li	a1, 156
	mv	a0, a2
	call	__mulsi3
	lui	a1, %hi(display)
	addi	a1, a1, %lo(display)
	add	a0, a1, a0
	add	a5, a0, s1
	lw	a0, 8(a5)
	bne	a0, s0, .LBB4_2
# %bb.1:
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	lw	s1, 4(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.LBB4_2:
	lhu	a0, 0(a5)
	lhu	a1, 2(a5)
	lhu	a3, 4(a5)
	lhu	a4, 6(a5)
	sw	s0, 8(a5)
	mv	a2, s0
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	lw	s1, 4(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	tail	DrawChar
.Lfunc_end4:
	.size	DisplaySetChar, .Lfunc_end4-DisplaySetChar
                                        # -- End function
	.type	display,@object                 # @display
	.local	display
	.comm	display,976,4
	.ident	"Ubuntu clang version 20.1.2 (0ubuntu1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
