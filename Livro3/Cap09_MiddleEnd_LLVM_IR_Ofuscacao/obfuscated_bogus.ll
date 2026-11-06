; ModuleID = 'flatten_target.c'
source_filename = "flatten_target.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @classify(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, -1
  %3 = mul i32 %0, %2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %25

6:                                                ; preds = %1, %25
  %7 = alloca i32, align 4
  %8 = icmp slt i32 %0, 0
  br i1 %8, label %9, label %10

9:                                                ; preds = %6
  br i1 %5, label %21, label %26

10:                                               ; preds = %6
  br i1 %5, label %11, label %27

11:                                               ; preds = %10, %27
  %12 = icmp eq i32 %0, 0
  br i1 %12, label %13, label %14

13:                                               ; preds = %11
  br i1 %5, label %21, label %28

14:                                               ; preds = %11
  br i1 %5, label %15, label %29

15:                                               ; preds = %14, %29
  %16 = icmp slt i32 %0, 100
  br i1 %16, label %17, label %18

17:                                               ; preds = %15
  br i1 %5, label %21, label %30

18:                                               ; preds = %15
  br i1 %5, label %21, label %31

19:                                               ; preds = %26, %28, %30, %31
  %20 = phi i32 [ 2, %31 ], [ 1, %30 ], [ 0, %28 ], [ -1, %26 ]
  store i32 %20, ptr %7, align 4
  br i1 %5, label %23, label %32

21:                                               ; preds = %9, %13, %17, %18
  %22 = phi i32 [ 2, %18 ], [ 1, %17 ], [ 0, %13 ], [ -1, %9 ]
  store i32 %22, ptr %7, align 4
  br label %23

23:                                               ; preds = %21, %19, %32
  %24 = load i32, ptr %7, align 4
  ret i32 %24

25:                                               ; preds = %1
  tail call void asm sideeffect "nop", ""() #3
  br label %6

26:                                               ; preds = %9
  tail call void asm sideeffect "nop", ""() #3
  br label %19

27:                                               ; preds = %10
  tail call void asm sideeffect "nop", ""() #3
  br label %11

28:                                               ; preds = %13
  tail call void asm sideeffect "nop", ""() #3
  br label %19

29:                                               ; preds = %14
  tail call void asm sideeffect "nop", ""() #3
  br label %15

30:                                               ; preds = %17
  tail call void asm sideeffect "nop", ""() #3
  br label %19

31:                                               ; preds = %18
  tail call void asm sideeffect "nop", ""() #3
  br label %19

32:                                               ; preds = %19
  tail call void asm sideeffect "nop", ""() #3
  br label %23
}

; Function Attrs: nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @classify(i32 noundef -5)
  %2 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %1)
  %3 = tail call i32 @classify(i32 noundef 0)
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %5 = tail call i32 @classify(i32 noundef 42)
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %5)
  %7 = tail call i32 @classify(i32 noundef 200)
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %7)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #2

attributes #0 = { noinline nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
