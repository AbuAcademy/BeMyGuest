; ModuleID = 'ubsan_demo.c'
source_filename = "ubsan_demo.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.src = private unnamed_addr constant [13 x i8] c"ubsan_demo.c\00", align 1
@0 = private unnamed_addr constant { i16, i16, [6 x i8] } { i16 0, i16 11, [6 x i8] c"'int'\00" }
@1 = private unnamed_addr global { { ptr, i32, i32 }, ptr } { { ptr, i32, i32 } { ptr @.src, i32 5, i32 33 }, ptr @0 }
@.str = private unnamed_addr constant [15 x i8] c"Resultado: %d\0A\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 !func_sanitize !6 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  store i32 2147483647, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %4, i32 1), !nosanitize !7
  %6 = extractvalue { i32, i1 } %5, 0, !nosanitize !7
  %7 = extractvalue { i32, i1 } %5, 1, !nosanitize !7
  %8 = xor i1 %7, true, !nosanitize !7
  br i1 %8, label %11, label %9, !prof !8, !nosanitize !7

9:                                                ; preds = %0
  %10 = zext i32 %4 to i64, !nosanitize !7
  call void @__ubsan_handle_add_overflow(ptr @1, i64 %10, i64 1) #4, !nosanitize !7
  br label %11, !nosanitize !7

11:                                               ; preds = %9, %0
  store volatile i32 %6, ptr %3, align 4
  %12 = load volatile i32, ptr %3, align 4
  %13 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %12)
  ret i32 0
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #1

; Function Attrs: uwtable
declare void @__ubsan_handle_add_overflow(ptr, i64, i64) #2

declare i32 @printf(ptr noundef, ...) #3

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { uwtable }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
!6 = !{i32 -1056584962, i32 901845932}
!7 = !{}
!8 = !{!"branch_weights", i32 1048575, i32 1}
