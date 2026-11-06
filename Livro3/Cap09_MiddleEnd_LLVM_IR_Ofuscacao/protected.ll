; ModuleID = 'str_target.c'
source_filename = "str_target.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str_enc = private unnamed_addr constant [27 x i8] c"*662xmm#66#!)'0l!-/m '#!-,B"
@.str.1_enc = private unnamed_addr constant [35 x i8] c"\00'#0'0b';\08* \05!+\0D+\08\11\178\0Bs\0C+\08{l1'!0'6B"
@.str.2_enc = private unnamed_addr constant [5 x i8] c"\12\0D\11\16B"
@.str.3_enc = private unnamed_addr constant [22 x i8] c"oo|b\01-,'!6#,&-b'/bg1HB"
@.str.4_enc = private unnamed_addr constant [15 x i8] c"oo|b\16-)',xbg1HB"
@.str.5_enc = private unnamed_addr constant [17 x i8] c"oo|b\0F\81\EB6-&-xbg1HB"

; Function Attrs: nounwind uwtable
define dso_local void @connect() local_unnamed_addr #0 {
  %1 = alloca [27 x i8], align 1
  call void @__str_decrypt(ptr nonnull %1, ptr nonnull @.str_enc, i32 27, i8 66) #2
  %2 = alloca [35 x i8], align 1
  call void @__str_decrypt(ptr nonnull %2, ptr nonnull @.str.1_enc, i32 35, i8 66) #2
  %3 = alloca [5 x i8], align 1
  call void @__str_decrypt(ptr nonnull %3, ptr nonnull @.str.2_enc, i32 5, i8 66) #2
  %4 = alloca [22 x i8], align 1
  call void @__str_decrypt(ptr nonnull %4, ptr nonnull @.str.3_enc, i32 22, i8 66) #2
  %5 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) %4, ptr noundef nonnull %1)
  %6 = alloca [15 x i8], align 1
  call void @__str_decrypt(ptr nonnull %6, ptr nonnull @.str.4_enc, i32 15, i8 66) #2
  %7 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) %6, ptr noundef nonnull %2)
  %8 = alloca [17 x i8], align 1
  call void @__str_decrypt(ptr nonnull %8, ptr nonnull @.str.5_enc, i32 17, i8 66) #2
  %9 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) %8, ptr noundef nonnull %3)
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #1

; Function Attrs: nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #0 {
  tail call void @connect()
  ret i32 0
}

declare void @__str_decrypt(ptr, ptr, i32, i8) local_unnamed_addr

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (++20251212115320+2078da43e25a-1~exp1~20251212115344.67)"}
