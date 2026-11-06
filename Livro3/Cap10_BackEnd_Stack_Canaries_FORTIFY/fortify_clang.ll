; ModuleID = 'fortify_basics.c'
source_filename = "fortify_basics.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@stderr = external local_unnamed_addr global ptr, align 8
@.str = private unnamed_addr constant [56 x i8] c"uso: %s <modo> <input>\0A  modos: safe | wrapper | decay\0A\00", align 1
@.str.1 = private unnamed_addr constant [5 x i8] c"safe\00", align 1
@.str.2 = private unnamed_addr constant [8 x i8] c"wrapper\00", align 1
@.str.3 = private unnamed_addr constant [6 x i8] c"decay\00", align 1
@.str.4 = private unnamed_addr constant [20 x i8] c"modo inv\C3\A1lido: %s\0A\00", align 1

; Function Attrs: nofree nounwind uwtable
define dso_local void @safe(ptr noundef %0) local_unnamed_addr #0 {
  %2 = alloca [32 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #8
  %3 = call ptr @__strcpy_chk(ptr noundef nonnull %2, ptr noundef %0, i64 noundef 32) #8
  %4 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %2)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #8
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nofree nounwind uwtable
define dso_local void @wrapper_vuln(ptr noundef %0, ptr noundef %1) local_unnamed_addr #0 {
  %3 = tail call ptr @strcpy(ptr noundef nonnull dereferenceable(1) %0, ptr noundef nonnull dereferenceable(1) %1)
  ret void
}

; Function Attrs: nofree nounwind uwtable
define dso_local void @wrapper(ptr noundef %0) local_unnamed_addr #0 {
  %2 = alloca [32 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #8
  %3 = call ptr @__strcpy_chk(ptr noundef nonnull %2, ptr noundef %0, i64 noundef 32) #8
  %4 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %2)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #8
  ret void
}

; Function Attrs: nofree nounwind uwtable
define dso_local void @decay_vuln(ptr noundef %0, ptr noundef %1) local_unnamed_addr #0 {
  %3 = tail call ptr @strcpy(ptr noundef nonnull dereferenceable(1) %0, ptr noundef nonnull dereferenceable(1) %1)
  ret void
}

; Function Attrs: nofree nounwind uwtable
define dso_local void @decay(ptr noundef %0) local_unnamed_addr #0 {
  %2 = alloca [32 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #8
  %3 = call ptr @__strcpy_chk(ptr noundef nonnull %2, ptr noundef %0, i64 noundef 32) #8
  %4 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %2)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #8
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local range(i32 0, 2) i32 @main(i32 noundef %0, ptr noundef readonly captures(none) %1) local_unnamed_addr #3 {
  %3 = alloca [32 x i8], align 16
  %4 = alloca [32 x i8], align 16
  %5 = alloca [32 x i8], align 16
  %6 = icmp slt i32 %0, 3
  br i1 %6, label %7, label %10

7:                                                ; preds = %2
  %8 = load ptr, ptr @stderr, align 8, !tbaa !5
  %9 = load ptr, ptr %1, align 8, !tbaa !10
  tail call void (ptr, i64, ptr, ...) @_ZL7fprintfP8_IO_FILEU17pass_object_size1PKcz(ptr noundef %8, i64 poison, ptr noundef nonnull @.str, ptr noundef %9)
  br label %34

10:                                               ; preds = %2
  %11 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %12 = load ptr, ptr %11, align 8, !tbaa !10
  %13 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %14 = load ptr, ptr %13, align 8, !tbaa !10
  %15 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(5) @.str.1) #9
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %20

17:                                               ; preds = %10
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #8
  %18 = call ptr @__strcpy_chk(ptr noundef nonnull %5, ptr noundef %14, i64 noundef 32) #8
  %19 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %5)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #8
  br label %34

20:                                               ; preds = %10
  %21 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(8) @.str.2) #9
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %26

23:                                               ; preds = %20
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #8
  %24 = call ptr @__strcpy_chk(ptr noundef nonnull %4, ptr noundef %14, i64 noundef 32) #8
  %25 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %4)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #8
  br label %34

26:                                               ; preds = %20
  %27 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(6) @.str.3) #9
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %32

29:                                               ; preds = %26
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #8
  %30 = call ptr @__strcpy_chk(ptr noundef nonnull %3, ptr noundef %14, i64 noundef 32) #8
  %31 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %3)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #8
  br label %34

32:                                               ; preds = %26
  %33 = load ptr, ptr @stderr, align 8, !tbaa !5
  tail call void (ptr, i64, ptr, ...) @_ZL7fprintfP8_IO_FILEU17pass_object_size1PKcz(ptr noundef %33, i64 poison, ptr noundef nonnull @.str.4, ptr noundef nonnull %12)
  br label %34

34:                                               ; preds = %32, %23, %29, %17, %7
  %35 = phi i32 [ 1, %7 ], [ 1, %32 ], [ 0, %23 ], [ 0, %29 ], [ 0, %17 ]
  ret i32 %35
}

; Function Attrs: nounwind uwtable
define internal void @_ZL7fprintfP8_IO_FILEU17pass_object_size1PKcz(ptr noalias noundef nonnull %0, i64 %1, ptr noalias noundef %2, ...) unnamed_addr #3 {
  %4 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #8
  call void @llvm.va_start.p0(ptr nonnull %4)
  %5 = call i32 @__vfprintf_chk(ptr noundef nonnull %0, i32 noundef 1, ptr noundef %2, ptr noundef nonnull %4) #8
  call void @llvm.va_end.p0(ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #8
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i32 @strcmp(ptr noundef captures(none), ptr noundef captures(none)) local_unnamed_addr #4

; Function Attrs: nofree nounwind
declare ptr @__strcpy_chk(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #5

declare i32 @__vfprintf_chk(ptr noundef, i32 noundef, ptr noundef, ptr noundef) local_unnamed_addr #6

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @strcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none)) #7

attributes #0 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #6 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #8 = { nounwind }
attributes #9 = { nounwind willreturn memory(read) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"p1 _ZTS8_IO_FILE", !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"p1 omnipotent char", !7, i64 0}
