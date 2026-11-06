; ModuleID = 'memset_wipe.c'
source_filename = "memset_wipe.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [24 x i8] c"Segredo alocado em: %p\0A\00", align 1
@.str.1 = private unnamed_addr constant [9 x i8] c"PID: %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [64 x i8] c"Pressione ENTER para continuar...(mas antes, leia a mem\C3\B3ria!)\0A\00", align 1
@.str.3 = private unnamed_addr constant [38 x i8] c"free() chamado \E2\80\94 segredo 'apagado'\0A\00", align 1
@.str.4 = private unnamed_addr constant [34 x i8] c"Pressione ENTER para encerrar...\0A\00", align 1
@.str.5 = private unnamed_addr constant [16 x i8] c"s3cr3t_p4ssw0rd\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @handle_secret(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i64, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = call i64 @strlen(ptr noundef %5) #7
  store i64 %6, ptr %3, align 8
  %7 = load i64, ptr %3, align 8
  %8 = add i64 %7, 1
  %9 = call noalias ptr @malloc(i64 noundef %8) #8
  store ptr %9, ptr %4, align 8
  %10 = load ptr, ptr %4, align 8
  %11 = load ptr, ptr %2, align 8
  %12 = load i64, ptr %3, align 8
  %13 = add i64 %12, 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %10, ptr align 1 %11, i64 %13, i1 false)
  %14 = load ptr, ptr %4, align 8
  %15 = call i32 (ptr, ...) @printf(ptr noundef @.str, ptr noundef %14)
  %16 = call i32 @getpid() #9
  %17 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %16)
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.2)
  %19 = call i32 @getchar()
  %20 = load ptr, ptr %4, align 8
  %21 = load i64, ptr %3, align 8
  %22 = add i64 %21, 1
  call void @llvm.memset.p0.i64(ptr align 1 %20, i8 0, i64 %22, i1 false)
  %23 = load ptr, ptr %4, align 8
  call void @free(ptr noundef %23) #9
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.3)
  %25 = call i32 (ptr, ...) @printf(ptr noundef @.str.4)
  %26 = call i32 @getchar()
  ret void
}

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #1

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #3

declare i32 @printf(ptr noundef, ...) #4

; Function Attrs: nounwind
declare i32 @getpid() #5

declare i32 @getchar() #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #6

; Function Attrs: nounwind
declare void @free(ptr noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  call void @handle_secret(ptr noundef @.str.5)
  ret i32 0
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #7 = { nounwind willreturn memory(read) }
attributes #8 = { nounwind allocsize(0) }
attributes #9 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
