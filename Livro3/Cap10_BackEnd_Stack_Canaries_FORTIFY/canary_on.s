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
	sub	rsp, 80
	.cfi_def_cfa_offset 96
	.cfi_offset rbx, -16
	mov	rsi, rdi
	mov	rax, qword ptr fs:[40]
	mov	qword ptr [rsp + 72], rax
	mov	rbx, rsp
	mov	rdi, rbx
	call	strcpy@PLT
	lea	rdi, [rip + .L.str]
	mov	rsi, rbx
	xor	eax, eax
	call	printf@PLT
	mov	rax, qword ptr fs:[40]
	cmp	rax, qword ptr [rsp + 72]
	jne	.LBB0_2
# %bb.1:
	add	rsp, 80
	.cfi_def_cfa_offset 16
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
.LBB0_2:
	.cfi_def_cfa_offset 96
	call	__stack_chk_fail@PLT
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
	push	rbx
	.cfi_def_cfa_offset 16
	sub	rsp, 80
	.cfi_def_cfa_offset 96
	.cfi_offset rbx, -16
	mov	rax, qword ptr fs:[40]
	mov	qword ptr [rsp + 72], rax
	cmp	edi, 2
	jl	.LBB1_2
# %bb.1:
	mov	rsi, qword ptr [rsi + 8]
	mov	rbx, rsp
	mov	rdi, rbx
	call	strcpy@PLT
	lea	rdi, [rip + .L.str]
	mov	rsi, rbx
	xor	eax, eax
	call	printf@PLT
.LBB1_2:
	mov	rax, qword ptr fs:[40]
	cmp	rax, qword ptr [rsp + 72]
	jne	.LBB1_4
# %bb.3:
	xor	eax, eax
	add	rsp, 80
	.cfi_def_cfa_offset 16
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
.LBB1_4:
	.cfi_def_cfa_offset 96
	call	__stack_chk_fail@PLT
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
	.addrsig_sym __stack_chk_fail
