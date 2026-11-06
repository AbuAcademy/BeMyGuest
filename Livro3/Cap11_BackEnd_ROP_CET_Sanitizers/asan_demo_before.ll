; ModuleID = 'asan_demo.c'
source_filename = "asan_demo.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [34 x i8] c"este texto tem mais de 16 bytes!!\00", align 1
@sink = dso_local global i32 0, align 4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @heap_overflow() #0 {
  %1 = alloca ptr, align 8
  %2 = call noalias ptr @malloc(i64 noundef 16) #3
  store ptr %2, ptr %1, align 8
  %3 = load ptr, ptr %1, align 8
  %4 = call ptr @strcpy(ptr noundef %3, ptr noundef @.str) #4
  %5 = load ptr, ptr %1, align 8
  %6 = getelementptr inbounds i8, ptr %5, i64 0
  %7 = load i8, ptr %6, align 1
  %8 = sext i8 %7 to i32
  store volatile i32 %8, ptr @sink, align 4
  %9 = load ptr, ptr %1, align 8
  call void @free(ptr noundef %9) #4
  ret void
}

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #1

; Function Attrs: nounwind
declare ptr @strcpy(ptr noundef, ptr noundef) #2

; Function Attrs: nounwind
declare void @free(ptr noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @use_after_free() #0 {
  %1 = alloca ptr, align 8
  %2 = call noalias ptr @malloc(i64 noundef 32) #3
  store ptr %2, ptr %1, align 8
  %3 = load ptr, ptr %1, align 8
  call void @free(ptr noundef %3) #4
  %4 = load ptr, ptr %1, align 8
  %5 = getelementptr inbounds i8, ptr %4, i64 0
  store i8 88, ptr %5, align 1
  %6 = load ptr, ptr %1, align 8
  %7 = getelementptr inbounds i8, ptr %6, i64 0
  %8 = load i8, ptr %7, align 1
  %9 = sext i8 %8 to i32
  store volatile i32 %9, ptr @sink, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @stack_overflow() #0 {
  %1 = alloca [8 x i8], align 1
  %2 = getelementptr inbounds [8 x i8], ptr %1, i64 0, i64 10
  store i8 -1, ptr %2, align 1
  %3 = getelementptr inbounds [8 x i8], ptr %1, i64 0, i64 10
  %4 = load i8, ptr %3, align 1
  %5 = sext i8 %4 to i32
  store volatile i32 %5, ptr @sink, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store i32 0, ptr %3, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  %6 = load i32, ptr %4, align 4
  %7 = icmp slt i32 %6, 2
  br i1 %7, label %8, label %9

8:                                                ; preds = %2
  store i32 1, ptr %3, align 4
  br label %20

9:                                                ; preds = %2
  %10 = load ptr, ptr %5, align 8
  %11 = getelementptr inbounds ptr, ptr %10, i64 1
  %12 = load ptr, ptr %11, align 8
  %13 = getelementptr inbounds i8, ptr %12, i64 0
  %14 = load i8, ptr %13, align 1
  %15 = sext i8 %14 to i32
  switch i32 %15, label %19 [
    i32 49, label %16
    i32 50, label %17
    i32 51, label %18
  ]

16:                                               ; preds = %9
  call void @heap_overflow()
  br label %19

17:                                               ; preds = %9
  call void @use_after_free()
  br label %19

18:                                               ; preds = %9
  call void @stack_overflow()
  br label %19

19:                                               ; preds = %9, %18, %17, %16
  store i32 0, ptr %3, align 4
  br label %20

20:                                               ; preds = %19, %8
  %21 = load i32, ptr %3, align 4
  ret i32 %21
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind allocsize(0) }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
