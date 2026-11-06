; ModuleID = 'asan_demo.c'
source_filename = "asan_demo.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

$asan.module_ctor = comdat any

$asan.module_dtor = comdat any

$.str.023bc9703322a32dda45f4cd0f6d41a8 = comdat any

$sink = comdat any

@.str = internal constant { [34 x i8], [62 x i8] } { [34 x i8] c"este texto tem mais de 16 bytes!!\00", [62 x i8] zeroinitializer }, comdat($.str.023bc9703322a32dda45f4cd0f6d41a8), align 32
@sink = dso_local global { i32, [28 x i8] } zeroinitializer, comdat, align 32
@__asan_option_detect_stack_use_after_return = external global i32
@___asan_gen_stack = private unnamed_addr constant [15 x i8] c"1 32 8 5 local\00", align 1
@___asan_gen_global = private unnamed_addr constant [5 x i8] c".str\00", align 1
@___asan_gen_module = private constant [12 x i8] c"asan_demo.c\00", align 1
@___asan_gen_global.1 = private unnamed_addr constant [5 x i8] c"sink\00", align 1
@__odr_asan_gen_sink = global i8 0, align 1
@__asan_global_.str = private global { i64, i64, i64, i64, i64, i64, i64, i64 } { i64 ptrtoint (ptr @0 to i64), i64 34, i64 96, i64 ptrtoint (ptr @___asan_gen_global to i64), i64 ptrtoint (ptr @___asan_gen_module to i64), i64 0, i64 0, i64 -1 }, section "asan_globals", comdat($.str.023bc9703322a32dda45f4cd0f6d41a8), !associated !0
@__asan_global_sink = private global { i64, i64, i64, i64, i64, i64, i64, i64 } { i64 ptrtoint (ptr @1 to i64), i64 4, i64 32, i64 ptrtoint (ptr @___asan_gen_global.1 to i64), i64 ptrtoint (ptr @___asan_gen_module to i64), i64 0, i64 0, i64 ptrtoint (ptr @__odr_asan_gen_sink to i64) }, section "asan_globals", comdat($sink), !associated !1
@llvm.compiler.used = appending global [4 x ptr] [ptr @.str, ptr @sink, ptr @__asan_global_.str, ptr @__asan_global_sink], section "llvm.metadata"
@___asan_globals_registered = common hidden global i64 0
@__start_asan_globals = extern_weak hidden global i64
@__stop_asan_globals = extern_weak hidden global i64
@llvm.used = appending global [2 x ptr] [ptr @asan.module_ctor, ptr @asan.module_dtor], section "llvm.metadata"
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 1, ptr @asan.module_ctor, ptr @asan.module_ctor }]
@llvm.global_dtors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 1, ptr @asan.module_dtor, ptr @asan.module_dtor }]

@0 = private alias { [34 x i8], [62 x i8] }, ptr @.str
@1 = private alias { i32, [28 x i8] }, ptr @sink

; Function Attrs: noinline nounwind optnone sanitize_address uwtable
define dso_local void @heap_overflow() #0 {
entry:
  %buf = alloca ptr, align 8, !annotation !9
  call void @llvm.lifetime.start.p0(i64 8, ptr %buf) #6
  %call = call noalias ptr @malloc(i64 noundef 16) #7
  store ptr %call, ptr %buf, align 8
  %0 = load ptr, ptr %buf, align 8
  %call1 = call ptr @strcpy(ptr noundef %0, ptr noundef @.str) #8
  %1 = load ptr, ptr %buf, align 8
  %arrayidx = getelementptr inbounds i8, ptr %1, i64 0
  %2 = ptrtoint ptr %arrayidx to i64
  %3 = lshr i64 %2, 3
  %4 = add i64 %3, 2147450880
  %5 = inttoptr i64 %4 to ptr
  %6 = load i8, ptr %5, align 1
  %7 = icmp ne i8 %6, 0
  br i1 %7, label %8, label %13, !prof !11

8:                                                ; preds = %entry
  %9 = and i64 %2, 7
  %10 = trunc i64 %9 to i8
  %11 = icmp sge i8 %10, %6
  br i1 %11, label %12, label %13

12:                                               ; preds = %8
  call void @__asan_report_load1(i64 %2) #9
  unreachable

13:                                               ; preds = %8, %entry
  %14 = load i8, ptr %arrayidx, align 1
  %conv = sext i8 %14 to i32
  store volatile i32 %conv, ptr @sink, align 4
  %15 = load ptr, ptr %buf, align 8
  call void @free(ptr noundef %15) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr %buf) #6
  ret void
}

; Function Attrs: nobuiltin nocallback nofree nosync nounwind willreturn
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #2

; Function Attrs: nounwind
declare ptr @strcpy(ptr noundef, ptr noundef) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #3

; Function Attrs: nobuiltin nocallback nofree nosync nounwind willreturn
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: noinline nounwind optnone sanitize_address uwtable
define dso_local void @use_after_free() #0 {
entry:
  %buf = alloca ptr, align 8, !annotation !9
  call void @llvm.lifetime.start.p0(i64 8, ptr %buf) #6
  %call = call noalias ptr @malloc(i64 noundef 32) #7
  store ptr %call, ptr %buf, align 8
  %0 = load ptr, ptr %buf, align 8
  call void @free(ptr noundef %0) #6
  %1 = load ptr, ptr %buf, align 8
  %arrayidx = getelementptr inbounds i8, ptr %1, i64 0
  %2 = ptrtoint ptr %arrayidx to i64
  %3 = lshr i64 %2, 3
  %4 = add i64 %3, 2147450880
  %5 = inttoptr i64 %4 to ptr
  %6 = load i8, ptr %5, align 1
  %7 = icmp ne i8 %6, 0
  br i1 %7, label %8, label %13, !prof !11

8:                                                ; preds = %entry
  %9 = and i64 %2, 7
  %10 = trunc i64 %9 to i8
  %11 = icmp sge i8 %10, %6
  br i1 %11, label %12, label %13

12:                                               ; preds = %8
  call void @__asan_report_store1(i64 %2) #9
  unreachable

13:                                               ; preds = %8, %entry
  store i8 88, ptr %arrayidx, align 1
  %14 = load ptr, ptr %buf, align 8
  %arrayidx1 = getelementptr inbounds i8, ptr %14, i64 0
  %15 = ptrtoint ptr %arrayidx1 to i64
  %16 = lshr i64 %15, 3
  %17 = add i64 %16, 2147450880
  %18 = inttoptr i64 %17 to ptr
  %19 = load i8, ptr %18, align 1
  %20 = icmp ne i8 %19, 0
  br i1 %20, label %21, label %26, !prof !11

21:                                               ; preds = %13
  %22 = and i64 %15, 7
  %23 = trunc i64 %22 to i8
  %24 = icmp sge i8 %23, %19
  br i1 %24, label %25, label %26

25:                                               ; preds = %21
  call void @__asan_report_load1(i64 %15) #9
  unreachable

26:                                               ; preds = %21, %13
  %27 = load i8, ptr %arrayidx1, align 1
  %conv = sext i8 %27 to i32
  store volatile i32 %conv, ptr @sink, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr %buf) #6
  ret void
}

; Function Attrs: noinline nounwind optnone sanitize_address uwtable
define dso_local void @stack_overflow() #0 {
entry:
  %asan_local_stack_base = alloca i64, align 8
  %0 = load i32, ptr @__asan_option_detect_stack_use_after_return, align 4
  %1 = icmp ne i32 %0, 0
  br i1 %1, label %2, label %4

2:                                                ; preds = %entry
  %3 = call i64 @__asan_stack_malloc_0(i64 64)
  br label %4

4:                                                ; preds = %entry, %2
  %5 = phi i64 [ 0, %entry ], [ %3, %2 ]
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %4
  %MyAlloca = alloca i8, i64 64, align 32
  %8 = ptrtoint ptr %MyAlloca to i64
  br label %9

9:                                                ; preds = %4, %7
  %10 = phi i64 [ %5, %4 ], [ %8, %7 ]
  store i64 %10, ptr %asan_local_stack_base, align 8
  %11 = add i64 %10, 32
  %12 = inttoptr i64 %11 to ptr
  %13 = inttoptr i64 %10 to ptr
  store i64 1102416563, ptr %13, align 8
  %14 = add i64 %10, 8
  %15 = inttoptr i64 %14 to ptr
  store i64 ptrtoint (ptr @___asan_gen_stack to i64), ptr %15, align 8
  %16 = add i64 %10, 16
  %17 = inttoptr i64 %16 to ptr
  store i64 ptrtoint (ptr @stack_overflow to i64), ptr %17, align 8
  %18 = lshr i64 %10, 3
  %19 = add i64 %18, 2147450880
  %20 = add i64 %19, 0
  %21 = inttoptr i64 %20 to ptr
  store i64 -868082052615769615, ptr %21, align 1
  %22 = add i64 %19, 4
  %23 = inttoptr i64 %22 to ptr
  store i8 0, ptr %23, align 1
  call void @llvm.lifetime.start.p0(i64 8, ptr %12) #6
  %arrayidx = getelementptr inbounds [8 x i8], ptr %12, i64 0, i64 10
  %24 = ptrtoint ptr %arrayidx to i64
  %25 = lshr i64 %24, 3
  %26 = add i64 %25, 2147450880
  %27 = inttoptr i64 %26 to ptr
  %28 = load i8, ptr %27, align 1
  %29 = icmp ne i8 %28, 0
  br i1 %29, label %30, label %35, !prof !11

30:                                               ; preds = %9
  %31 = and i64 %24, 7
  %32 = trunc i64 %31 to i8
  %33 = icmp sge i8 %32, %28
  br i1 %33, label %34, label %35

34:                                               ; preds = %30
  call void @__asan_report_store1(i64 %24) #9
  unreachable

35:                                               ; preds = %30, %9
  store i8 -1, ptr %arrayidx, align 1
  %arrayidx1 = getelementptr inbounds [8 x i8], ptr %12, i64 0, i64 10
  %36 = ptrtoint ptr %arrayidx1 to i64
  %37 = lshr i64 %36, 3
  %38 = add i64 %37, 2147450880
  %39 = inttoptr i64 %38 to ptr
  %40 = load i8, ptr %39, align 1
  %41 = icmp ne i8 %40, 0
  br i1 %41, label %42, label %47, !prof !11

42:                                               ; preds = %35
  %43 = and i64 %36, 7
  %44 = trunc i64 %43 to i8
  %45 = icmp sge i8 %44, %40
  br i1 %45, label %46, label %47

46:                                               ; preds = %42
  call void @__asan_report_load1(i64 %36) #9
  unreachable

47:                                               ; preds = %42, %35
  %48 = load i8, ptr %arrayidx1, align 1
  %conv = sext i8 %48 to i32
  store volatile i32 %conv, ptr @sink, align 4
  %49 = add i64 %19, 4
  %50 = inttoptr i64 %49 to ptr
  store i8 -8, ptr %50, align 1
  call void @llvm.lifetime.end.p0(i64 8, ptr %12) #6
  store i64 1172321806, ptr %13, align 8
  %51 = icmp ne i64 %5, 0
  br i1 %51, label %52, label %59

52:                                               ; preds = %47
  %53 = add i64 %19, 0
  %54 = inttoptr i64 %53 to ptr
  store i64 -723401728380766731, ptr %54, align 1
  %55 = add i64 %5, 56
  %56 = inttoptr i64 %55 to ptr
  %57 = load i64, ptr %56, align 8
  %58 = inttoptr i64 %57 to ptr
  store i8 0, ptr %58, align 1
  br label %62

59:                                               ; preds = %47
  %60 = add i64 %19, 0
  %61 = inttoptr i64 %60 to ptr
  store i64 0, ptr %61, align 1
  br label %62

62:                                               ; preds = %59, %52
  ret void
}

; Function Attrs: noinline nounwind optnone sanitize_address uwtable
define dso_local i32 @main(i32 noundef %argc, ptr noundef %argv) #0 {
entry:
  %retval = alloca i32, align 4, !annotation !12
  %argc.addr = alloca i32, align 4, !annotation !14
  %argv.addr = alloca ptr, align 8, !annotation !16
  store i32 0, ptr %retval, align 4
  store i32 %argc, ptr %argc.addr, align 4
  store ptr %argv, ptr %argv.addr, align 8
  %0 = load i32, ptr %argc.addr, align 4
  %cmp = icmp slt i32 %0, 2
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  store i32 1, ptr %retval, align 4
  br label %return

if.end:                                           ; preds = %entry
  %1 = load ptr, ptr %argv.addr, align 8
  %arrayidx = getelementptr inbounds ptr, ptr %1, i64 1
  %2 = ptrtoint ptr %arrayidx to i64
  %3 = lshr i64 %2, 3
  %4 = add i64 %3, 2147450880
  %5 = inttoptr i64 %4 to ptr
  %6 = load i8, ptr %5, align 1
  %7 = icmp ne i8 %6, 0
  br i1 %7, label %8, label %9

8:                                                ; preds = %if.end
  call void @__asan_report_load8(i64 %2) #9
  unreachable

9:                                                ; preds = %if.end
  %10 = load ptr, ptr %arrayidx, align 8
  %arrayidx1 = getelementptr inbounds i8, ptr %10, i64 0
  %11 = ptrtoint ptr %arrayidx1 to i64
  %12 = lshr i64 %11, 3
  %13 = add i64 %12, 2147450880
  %14 = inttoptr i64 %13 to ptr
  %15 = load i8, ptr %14, align 1
  %16 = icmp ne i8 %15, 0
  br i1 %16, label %17, label %22, !prof !11

17:                                               ; preds = %9
  %18 = and i64 %11, 7
  %19 = trunc i64 %18 to i8
  %20 = icmp sge i8 %19, %15
  br i1 %20, label %21, label %22

21:                                               ; preds = %17
  call void @__asan_report_load1(i64 %11) #9
  unreachable

22:                                               ; preds = %17, %9
  %23 = load i8, ptr %arrayidx1, align 1
  %conv = sext i8 %23 to i32
  switch i32 %conv, label %sw.epilog [
    i32 49, label %sw.bb
    i32 50, label %sw.bb2
    i32 51, label %sw.bb3
  ]

sw.bb:                                            ; preds = %22
  call void @heap_overflow()
  br label %sw.epilog

sw.bb2:                                           ; preds = %22
  call void @use_after_free()
  br label %sw.epilog

sw.bb3:                                           ; preds = %22
  call void @stack_overflow()
  br label %sw.epilog

sw.epilog:                                        ; preds = %22, %sw.bb3, %sw.bb2, %sw.bb
  store i32 0, ptr %retval, align 4
  br label %return

return:                                           ; preds = %sw.epilog, %if.then
  %24 = load i32, ptr %retval, align 4
  ret i32 %24
}

declare void @__asan_report_load_n(i64, i64)

declare void @__asan_loadN(i64, i64)

declare void @__asan_report_load1(i64)

declare void @__asan_load1(i64)

declare void @__asan_report_load2(i64)

declare void @__asan_load2(i64)

declare void @__asan_report_load4(i64)

declare void @__asan_load4(i64)

declare void @__asan_report_load8(i64)

declare void @__asan_load8(i64)

declare void @__asan_report_load16(i64)

declare void @__asan_load16(i64)

declare void @__asan_report_store_n(i64, i64)

declare void @__asan_storeN(i64, i64)

declare void @__asan_report_store1(i64)

declare void @__asan_store1(i64)

declare void @__asan_report_store2(i64)

declare void @__asan_store2(i64)

declare void @__asan_report_store4(i64)

declare void @__asan_store4(i64)

declare void @__asan_report_store8(i64)

declare void @__asan_store8(i64)

declare void @__asan_report_store16(i64)

declare void @__asan_store16(i64)

declare void @__asan_report_exp_load_n(i64, i64, i32)

declare void @__asan_exp_loadN(i64, i64, i32)

declare void @__asan_report_exp_load1(i64, i32)

declare void @__asan_exp_load1(i64, i32)

declare void @__asan_report_exp_load2(i64, i32)

declare void @__asan_exp_load2(i64, i32)

declare void @__asan_report_exp_load4(i64, i32)

declare void @__asan_exp_load4(i64, i32)

declare void @__asan_report_exp_load8(i64, i32)

declare void @__asan_exp_load8(i64, i32)

declare void @__asan_report_exp_load16(i64, i32)

declare void @__asan_exp_load16(i64, i32)

declare void @__asan_report_exp_store_n(i64, i64, i32)

declare void @__asan_exp_storeN(i64, i64, i32)

declare void @__asan_report_exp_store1(i64, i32)

declare void @__asan_exp_store1(i64, i32)

declare void @__asan_report_exp_store2(i64, i32)

declare void @__asan_exp_store2(i64, i32)

declare void @__asan_report_exp_store4(i64, i32)

declare void @__asan_exp_store4(i64, i32)

declare void @__asan_report_exp_store8(i64, i32)

declare void @__asan_exp_store8(i64, i32)

declare void @__asan_report_exp_store16(i64, i32)

declare void @__asan_exp_store16(i64, i32)

declare ptr @__asan_memmove(ptr, ptr, i64)

declare ptr @__asan_memcpy(ptr, ptr, i64)

declare ptr @__asan_memset(ptr, i32, i64)

declare void @__asan_handle_no_return()

declare void @__sanitizer_ptr_cmp(i64, i64)

declare void @__sanitizer_ptr_sub(i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.amdgcn.is.shared(ptr) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.amdgcn.is.private(ptr) #4

declare i64 @__asan_stack_malloc_0(i64)

declare void @__asan_stack_free_0(i64, i64)

declare i64 @__asan_stack_malloc_1(i64)

declare void @__asan_stack_free_1(i64, i64)

declare i64 @__asan_stack_malloc_2(i64)

declare void @__asan_stack_free_2(i64, i64)

declare i64 @__asan_stack_malloc_3(i64)

declare void @__asan_stack_free_3(i64, i64)

declare i64 @__asan_stack_malloc_4(i64)

declare void @__asan_stack_free_4(i64, i64)

declare i64 @__asan_stack_malloc_5(i64)

declare void @__asan_stack_free_5(i64, i64)

declare i64 @__asan_stack_malloc_6(i64)

declare void @__asan_stack_free_6(i64, i64)

declare i64 @__asan_stack_malloc_7(i64)

declare void @__asan_stack_free_7(i64, i64)

declare i64 @__asan_stack_malloc_8(i64)

declare void @__asan_stack_free_8(i64, i64)

declare i64 @__asan_stack_malloc_9(i64)

declare void @__asan_stack_free_9(i64, i64)

declare i64 @__asan_stack_malloc_10(i64)

declare void @__asan_stack_free_10(i64, i64)

declare void @__asan_poison_stack_memory(i64, i64)

declare void @__asan_unpoison_stack_memory(i64, i64)

declare void @__asan_set_shadow_00(i64, i64)

declare void @__asan_set_shadow_01(i64, i64)

declare void @__asan_set_shadow_02(i64, i64)

declare void @__asan_set_shadow_03(i64, i64)

declare void @__asan_set_shadow_04(i64, i64)

declare void @__asan_set_shadow_05(i64, i64)

declare void @__asan_set_shadow_06(i64, i64)

declare void @__asan_set_shadow_07(i64, i64)

declare void @__asan_set_shadow_f1(i64, i64)

declare void @__asan_set_shadow_f2(i64, i64)

declare void @__asan_set_shadow_f3(i64, i64)

declare void @__asan_set_shadow_f5(i64, i64)

declare void @__asan_set_shadow_f8(i64, i64)

declare void @__asan_alloca_poison(i64, i64)

declare void @__asan_allocas_unpoison(i64, i64)

declare void @__asan_before_dynamic_init(i64)

declare void @__asan_after_dynamic_init()

declare void @__asan_register_globals(i64, i64)

declare void @__asan_unregister_globals(i64, i64)

declare void @__asan_register_image_globals(i64)

declare void @__asan_unregister_image_globals(i64)

declare void @__asan_register_elf_globals(i64, i64, i64)

declare void @__asan_unregister_elf_globals(i64, i64, i64)

declare void @__asan_init()

; Function Attrs: nounwind uwtable
define internal void @asan.module_ctor() #5 comdat {
  call void @__asan_init()
  call void @__asan_version_mismatch_check_v8()
  call void @__asan_register_elf_globals(i64 ptrtoint (ptr @___asan_globals_registered to i64), i64 ptrtoint (ptr @__start_asan_globals to i64), i64 ptrtoint (ptr @__stop_asan_globals to i64))
  ret void
}

declare void @__asan_version_mismatch_check_v8()

; Function Attrs: nounwind uwtable
define internal void @asan.module_dtor() #5 comdat {
  call void @__asan_unregister_elf_globals(i64 ptrtoint (ptr @___asan_globals_registered to i64), i64 ptrtoint (ptr @__start_asan_globals to i64), i64 ptrtoint (ptr @__stop_asan_globals to i64))
  ret void
}

attributes #0 = { noinline nounwind optnone sanitize_address uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nobuiltin nocallback nofree nosync nounwind willreturn }
attributes #2 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" }
attributes #6 = { nounwind }
attributes #7 = { nounwind allocsize(0) }
attributes #8 = { nobuiltin nounwind }
attributes #9 = { nomerge }

!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = !{ptr @.str}
!1 = !{ptr @sink}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"PIE Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = !{i32 4, !"nosanitize_address", i32 1}
!8 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
!9 = !{!10}
!10 = !{!"alloca_name_altered", !"buf"}
!11 = !{!"branch_weights", i32 1, i32 1048575}
!12 = !{!13}
!13 = !{!"alloca_name_altered", !"retval"}
!14 = !{!15}
!15 = !{!"alloca_name_altered", !"argc.addr"}
!16 = !{!17}
!17 = !{!"alloca_name_altered", !"argv.addr"}
