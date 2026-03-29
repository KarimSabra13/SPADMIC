// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb/vip/filelist.f
// Purpose : Compile order for the VIP interfaces, package, and harness.
// Author  : Karim Sabra
// Notes   : Keep the shared tb package first, then interfaces, then the VIP
//           package, and finally the top-level harness.
// =============================================================================

+incdir+tb/vip/interfaces
+incdir+tb/vip/pkg
+incdir+tb/tests

// Shared testbench package
tb/common/mptdc_tb_pkg.sv

// VIP interfaces
tb/vip/interfaces/mptdc_csr_if.sv
tb/vip/interfaces/mptdc_async_io_if.sv
tb/vip/interfaces/mptdc_narrow_if.sv

// VIP package and harness
tb/vip/pkg/mptdc_vip_pkg.sv
tb/tests/mptdc_vip_tb.sv
