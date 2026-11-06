; ModuleID = 'str_target.c'
source_filename = "str_target.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [27 x i8] c"http://attacker.com/beacon\00", align 1
@.str.1 = private unnamed_addr constant [35 x i8] c"Bearer eyJhbGciOiJSUzI1NiJ9.secret\00", align 1
@.str.2 = private unnamed_addr constant [5 x i8] c"POST\00", align 1
@.str.3 = private unnamed_addr constant [22 x i8] c"--> Conectando em %s\0A\00", align 1
@.str.4 = private unnamed_addr constant [15 x i8] c"--> Token: %s\0A\00", align 1
@.str.5 = private unnamed_addr constant [17 x i8] c"--> M\C3\A9todo: %s\0A\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @connect() #0 {
  %1 = alloca ptr, align 8
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  store ptr @.str, ptr %1, align 8
  store ptr @.str.1, ptr %2, align 8
  store ptr @.str.2, ptr %3, align 8
  %4 = load ptr, ptr %1, align 8
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, ptr noundef %4)
  %6 = load ptr, ptr %2, align 8
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, ptr noundef %6)
  %8 = load ptr, ptr %3, align 8
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, ptr noundef %8)
  ret void
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  call void @connect()
  ret i32 0
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
