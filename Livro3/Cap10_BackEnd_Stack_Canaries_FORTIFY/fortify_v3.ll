; ModuleID = 'fortify_basics.c'
source_filename = "fortify_basics.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@g_buf = dso_local local_unnamed_addr global ptr null, align 8
@stderr = external local_unnamed_addr global ptr, align 8
@.str = private unnamed_addr constant [56 x i8] c"uso: %s <modo> <input>\0A  modos: safe | wrapper | decay\0A\00", align 1
@.str.1 = private unnamed_addr constant [5 x i8] c"safe\00", align 1
@.str.2 = private unnamed_addr constant [8 x i8] c"wrapper\00", align 1
@.str.3 = private unnamed_addr constant [6 x i8] c"decay\00", align 1
@.str.4 = private unnamed_addr constant [8 x i8] c"dynamic\00", align 1
@.str.5 = private unnamed_addr constant [6 x i8] c"ghost\00", align 1
@.str.6 = private unnamed_addr constant [20 x i8] c"modo inv\C3\A1lido: %s\0A\00", align 1

; Function Attrs: nofree nounwind uwtable
define dso_local void @safe(ptr noundef %0) local_unnamed_addr #0 {
  %2 = alloca [32 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #11
  %3 = call ptr @__strcpy_chk(ptr noundef nonnull %2, ptr noundef %0, i64 noundef 32) #11
  %4 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %2)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #11
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
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #11
  %3 = call ptr @__strcpy_chk(ptr noundef nonnull %2, ptr noundef %0, i64 noundef 32) #11
  %4 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %2)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #11
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
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #11
  %3 = call ptr @__strcpy_chk(ptr noundef nonnull %2, ptr noundef %0, i64 noundef 32) #11
  %4 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %2)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #11
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local void @dynamic_check(ptr noundef %0, i64 noundef %1) local_unnamed_addr #3 {
  %3 = tail call noalias ptr @malloc(i64 noundef %1) #12
  %4 = icmp eq ptr %3, null
  br i1 %4, label %9, label %5

5:                                                ; preds = %2
  %6 = icmp ne i64 %1, -1
  tail call void @llvm.assume(i1 %6)
  %7 = tail call ptr @__strcpy_chk(ptr noundef nonnull %3, ptr noundef %0, i64 noundef %1) #11
  %8 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) %3)
  tail call void @free(ptr noundef nonnull %3) #11
  br label %9

9:                                                ; preds = %5, %2
  ret void
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #5

; Function Attrs: nofree nounwind uwtable
define dso_local void @ghost_check(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load ptr, ptr @g_buf, align 8, !tbaa !5
  %3 = tail call ptr @strcpy(ptr noundef nonnull dereferenceable(1) %2, ptr noundef nonnull dereferenceable(1) %0)
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
  %8 = load ptr, ptr @stderr, align 8, !tbaa !10
  %9 = load ptr, ptr %1, align 8, !tbaa !5
  tail call void (ptr, i64, ptr, ...) @_ZL7fprintfP8_IO_FILEU25pass_dynamic_object_size1PKcz(ptr noundef %8, i64 poison, ptr noundef nonnull @.str, ptr noundef %9)
  br label %49

10:                                               ; preds = %2
  %11 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %12 = load ptr, ptr %11, align 8, !tbaa !5
  %13 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %14 = load ptr, ptr %13, align 8, !tbaa !5
  %15 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(5) @.str.1) #13
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %20

17:                                               ; preds = %10
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #11
  %18 = call ptr @__strcpy_chk(ptr noundef nonnull %5, ptr noundef %14, i64 noundef 32) #11
  %19 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %5)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #11
  br label %49

20:                                               ; preds = %10
  %21 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(8) @.str.2) #13
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %26

23:                                               ; preds = %20
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #11
  %24 = call ptr @__strcpy_chk(ptr noundef nonnull %4, ptr noundef %14, i64 noundef 32) #11
  %25 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %4)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #11
  br label %49

26:                                               ; preds = %20
  %27 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(6) @.str.3) #13
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %32

29:                                               ; preds = %26
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #11
  %30 = call ptr @__strcpy_chk(ptr noundef nonnull %3, ptr noundef %14, i64 noundef 32) #11
  %31 = call i32 @puts(ptr noundef nonnull dereferenceable(1) %3)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #11
  br label %49

32:                                               ; preds = %26
  %33 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(8) @.str.4) #13
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %35, label %41

35:                                               ; preds = %32
  %36 = tail call noalias dereferenceable_or_null(32) ptr @malloc(i64 noundef 32) #12
  %37 = icmp eq ptr %36, null
  br i1 %37, label %49, label %38

38:                                               ; preds = %35
  %39 = tail call ptr @__strcpy_chk(ptr noundef nonnull %36, ptr noundef %14, i64 noundef 32) #11
  %40 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) %36)
  tail call void @free(ptr noundef nonnull %36) #11
  br label %49

41:                                               ; preds = %32
  %42 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %12, ptr noundef nonnull dereferenceable(6) @.str.5) #13
  %43 = icmp eq i32 %42, 0
  br i1 %43, label %44, label %47

44:                                               ; preds = %41
  %45 = tail call noalias dereferenceable_or_null(32) ptr @malloc(i64 noundef 32) #12
  store ptr %45, ptr @g_buf, align 8, !tbaa !5
  %46 = tail call ptr @__strcpy_chk(ptr noundef %45, ptr noundef %14, i64 noundef 32) #11
  br label %49

47:                                               ; preds = %41
  %48 = load ptr, ptr @stderr, align 8, !tbaa !10
  tail call void (ptr, i64, ptr, ...) @_ZL7fprintfP8_IO_FILEU25pass_dynamic_object_size1PKcz(ptr noundef %48, i64 poison, ptr noundef nonnull @.str.6, ptr noundef nonnull %12)
  br label %49

49:                                               ; preds = %38, %35, %47, %23, %44, %29, %17, %7
  %50 = phi i32 [ 1, %7 ], [ 1, %47 ], [ 0, %23 ], [ 0, %44 ], [ 0, %29 ], [ 0, %17 ], [ 0, %35 ], [ 0, %38 ]
  ret i32 %50
}

; Function Attrs: nounwind uwtable
define internal void @_ZL7fprintfP8_IO_FILEU25pass_dynamic_object_size1PKcz(ptr noalias noundef nonnull %0, i64 %1, ptr noalias noundef %2, ...) unnamed_addr #3 {
  %4 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #11
  call void @llvm.va_start.p0(ptr nonnull %4)
  %5 = call i32 @__vfprintf_chk(ptr noundef nonnull %0, i32 noundef 2, ptr noundef %2, ptr noundef nonnull %4) #11
  call void @llvm.va_end.p0(ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #11
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i32 @strcmp(ptr noundef captures(none), ptr noundef captures(none)) local_unnamed_addr #6

; Function Attrs: nofree nounwind
declare ptr @__strcpy_chk(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #7

declare i32 @__vfprintf_chk(ptr noundef, i32 noundef, ptr noundef, ptr noundef) local_unnamed_addr #8

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #7

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #9

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @strcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none)) #10

attributes #0 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #8 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #10 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #11 = { nounwind }
attributes #12 = { nounwind allocsize(0) }
attributes #13 = { nounwind willreturn memory(read) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"p1 omnipotent char", !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"p1 _ZTS8_IO_FILE", !7, i64 0}
