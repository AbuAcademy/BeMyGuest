; ModuleID = 'flatten_target.c'
source_filename = "flatten_target.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nofree noinline norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @classify(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp slt i32 %0, 100
  %3 = select i1 %2, i32 5, i32 6
  %4 = icmp eq i32 %0, 0
  %5 = select i1 %4, i32 3, i32 4
  %6 = icmp slt i32 %0, 0
  %7 = select i1 %6, i32 1, i32 2
  br label %8

8:                                                ; preds = %13, %1
  %9 = phi i32 [ undef, %1 ], [ %14, %13 ]
  %10 = phi i32 [ 0, %1 ], [ 7, %13 ]
  br label %19

11:                                               ; preds = %19
  br label %21

12:                                               ; preds = %19
  br label %13

13:                                               ; preds = %19, %12, %16, %17
  %14 = phi i32 [ 2, %17 ], [ 1, %16 ], [ 0, %12 ], [ -1, %19 ]
  br label %8

15:                                               ; preds = %19
  br label %21

16:                                               ; preds = %19
  br label %13

17:                                               ; preds = %19
  br label %13

18:                                               ; preds = %19
  ret i32 %9

19:                                               ; preds = %21, %8
  %20 = phi i32 [ %10, %8 ], [ %22, %21 ]
  switch i32 %20, label %23 [
    i32 0, label %21
    i32 1, label %13
    i32 2, label %11
    i32 3, label %12
    i32 4, label %15
    i32 5, label %16
    i32 6, label %17
    i32 7, label %18
  ]

21:                                               ; preds = %19, %11, %15
  %22 = phi i32 [ %5, %11 ], [ %3, %15 ], [ %7, %19 ]
  br label %19

23:                                               ; preds = %19
  unreachable
}

; Function Attrs: nofree nounwind uwtable
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

attributes #0 = { nofree noinline norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
