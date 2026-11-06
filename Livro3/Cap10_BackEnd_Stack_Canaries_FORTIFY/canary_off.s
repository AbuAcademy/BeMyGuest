	.intel_syntax noprefix
	.file	"canary.c"
	.text
	.globl	vulnerable                      # -- Begin function vulnerable
	.p2align	4
	.type	vulnerable,@function
vulnerable:                             # @vulnerable
	.cfi_startproc
# %bb.0:
	push	rbx
	.cfi_def_cfa_offset 16
	sub	rsp, 64
	.cfi_def_cfa_offset 80
	.cfi_offset rbx, -16
	mov	rsi, rdi
	mov	rbx, rsp
	mov	rdi, rbx
	call	strcpy@PLT
	lea	rdi, [rip + .L.str]
	mov	rsi, rbx
	xor	eax, eax
	call	printf@PLT
	add	rsp, 64
	.cfi_def_cfa_offset 16
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
.Lfunc_end0:
	.size	vulnerable, .Lfunc_end0-vulnerable
	.cfi_endproc
                                        # -- End function
	.globl	main                            # -- Begin function main
	.p2align	4
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:
	cmp	edi, 2
	jl	.LBB1_2
# %bb.1:
	push	rbx
	.cfi_def_cfa_offset 16
	sub	rsp, 64
	.cfi_def_cfa_offset 80
	.cfi_offset rbx, -16
	mov	rsi, qword ptr [rsi + 8]
	mov	rbx, rsp
	mov	rdi, rbx
	call	strcpy@PLT
	lea	rdi, [rip + .L.str]
	mov	rsi, rbx
	xor	eax, eax
	call	printf@PLT
	add	rsp, 64
	.cfi_def_cfa_offset 16
	pop	rbx
	.cfi_def_cfa_offset 8
	.cfi_restore rbx
.LBB1_2:
	xor	eax, eax
	ret
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"buffer: %s\n"
	.size	.L.str, 12

	.ident	"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
