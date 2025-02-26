; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -mattr=+v -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=riscv64 -mattr=+v -verify-machineinstrs < %s | FileCheck %s

define <4 x i64> @m2_splat_0(<4 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_0:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> poison, <4 x i32> <i32 0, i32 0, i32 0, i32 0>
  ret <4 x i64> %res
}

define <4 x i64> @m2_splat_in_chunks(<4 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_in_chunks:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vrgather.vi v11, v9, 0
; CHECK-NEXT:    vmv2r.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> poison, <4 x i32> <i32 0, i32 0, i32 2, i32 2>
  ret <4 x i64> %res
}

define <8 x i64> @m4_splat_in_chunks(<8 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m4_splat_in_chunks:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v12, v8, 0
; CHECK-NEXT:    vrgather.vi v13, v9, 0
; CHECK-NEXT:    vrgather.vi v14, v10, 0
; CHECK-NEXT:    vrgather.vi v15, v11, 1
; CHECK-NEXT:    vmv4r.v v8, v12
; CHECK-NEXT:    ret
  %res = shufflevector <8 x i64> %v1, <8 x i64> poison, <8 x i32> <i32 0, i32 0, i32 2, i32 2, i32 4, i32 4, i32 7, i32 7>
  ret <8 x i64> %res
}


define <4 x i64> @m2_splat_with_tail(<4 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_with_tail:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vmv1r.v v11, v9
; CHECK-NEXT:    vmv2r.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> poison, <4 x i32> <i32 0, i32 0, i32 2, i32 3>
  ret <4 x i64> %res
}

define <4 x i64> @m2_pair_swap_vl4(<4 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m2_pair_swap_vl4:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vslidedown.vi v11, v9, 1
; CHECK-NEXT:    vslideup.vi v11, v9, 1
; CHECK-NEXT:    vslidedown.vi v10, v8, 1
; CHECK-NEXT:    vslideup.vi v10, v8, 1
; CHECK-NEXT:    vmv2r.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> poison, <4 x i32> <i32 1, i32 0, i32 3, i32 2>
  ret <4 x i64> %res
}

define <8 x i32> @m2_pair_swap_vl8(<8 x i32> %v1) vscale_range(2,2) {
; RV32-LABEL: m2_pair_swap_vl8:
; RV32:       # %bb.0:
; RV32-NEXT:    li a0, 32
; RV32-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; RV32-NEXT:    vmv.v.x v10, a0
; RV32-NEXT:    li a0, 63
; RV32-NEXT:    vand.vx v12, v10, a0
; RV32-NEXT:    vsll.vv v12, v8, v12
; RV32-NEXT:    vrsub.vi v10, v10, 0
; RV32-NEXT:    vand.vx v10, v10, a0
; RV32-NEXT:    vsrl.vv v8, v8, v10
; RV32-NEXT:    vor.vv v8, v12, v8
; RV32-NEXT:    ret
;
; RV64-LABEL: m2_pair_swap_vl8:
; RV64:       # %bb.0:
; RV64-NEXT:    li a0, 32
; RV64-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; RV64-NEXT:    vsrl.vx v10, v8, a0
; RV64-NEXT:    vsll.vx v8, v8, a0
; RV64-NEXT:    vor.vv v8, v8, v10
; RV64-NEXT:    ret
  %res = shufflevector <8 x i32> %v1, <8 x i32> poison, <8 x i32> <i32 1, i32 0, i32 3, i32 2, i32 5, i32 4, i32 7, i32 6>
  ret <8 x i32> %res
}

define <4 x i64> @m2_splat_into_identity(<4 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_into_identity:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vmv1r.v v11, v9
; CHECK-NEXT:    vmv2r.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> poison, <4 x i32> <i32 0, i32 0, i32 2, i32 3>
  ret <4 x i64> %res
}

define <4 x i64> @m2_broadcast_i128(<4 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m2_broadcast_i128:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e8, m1, ta, ma
; CHECK-NEXT:    vmv1r.v v9, v8
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  ret <4 x i64> %res
}

define <8 x i64> @m4_broadcast_i128(<8 x i64> %v1) vscale_range(2,2) {
; CHECK-LABEL: m4_broadcast_i128:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e8, m1, ta, ma
; CHECK-NEXT:    vmv1r.v v9, v8
; CHECK-NEXT:    vmv1r.v v10, v8
; CHECK-NEXT:    vmv1r.v v11, v8
; CHECK-NEXT:    ret
  %res = shufflevector <8 x i64> %v1, <8 x i64> poison, <8 x i32> <i32 0, i32 1, i32 0, i32 1, i32 0, i32 1, i32 0, i32 1>
  ret <8 x i64> %res
}


define <4 x i64> @m2_splat_two_source(<4 x i64> %v1, <4 x i64> %v2) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_two_source:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v12, v8, 0
; CHECK-NEXT:    vrgather.vi v13, v11, 1
; CHECK-NEXT:    vmv2r.v v8, v12
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> %v2, <4 x i32> <i32 0, i32 0, i32 7, i32 7>
  ret <4 x i64> %res
}

define <4 x i64> @m2_splat_into_identity_two_source_v2_hi(<4 x i64> %v1, <4 x i64> %v2) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_into_identity_two_source_v2_hi:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vmv2r.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> %v2, <4 x i32> <i32 0, i32 0, i32 6, i32 7>
  ret <4 x i64> %res
}

define <4 x i64> @m2_splat_into_slide_two_source_v2_lo(<4 x i64> %v1, <4 x i64> %v2) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_into_slide_two_source_v2_lo:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v12, v8, 0
; CHECK-NEXT:    vmv1r.v v13, v10
; CHECK-NEXT:    vmv2r.v v8, v12
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> %v2, <4 x i32> <i32 0, i32 0, i32 4, i32 5>
  ret <4 x i64> %res
}

define <4 x i64> @m2_splat_into_slide_two_source(<4 x i64> %v1, <4 x i64> %v2) vscale_range(2,2) {
; CHECK-LABEL: m2_splat_into_slide_two_source:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e8, mf8, ta, ma
; CHECK-NEXT:    vmv.v.i v0, 12
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, mu
; CHECK-NEXT:    vrgather.vi v12, v8, 0
; CHECK-NEXT:    vslideup.vi v12, v10, 1, v0.t
; CHECK-NEXT:    vmv.v.v v8, v12
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %v1, <4 x i64> %v2, <4 x i32> <i32 0, i32 0, i32 5, i32 6>
  ret <4 x i64> %res
}
