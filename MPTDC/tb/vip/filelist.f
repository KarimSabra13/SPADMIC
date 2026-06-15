// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb/vip/filelist.f
// Purpose : Compile order for retained VIP interfaces and package collateral.
// Author  : Karim Sabra
// Notes   : Keep the shared tb package first, then interfaces, then the VIP
//           package.
// =============================================================================

+incdir+tb/vip/interfaces
+incdir+tb/vip/pkg

// Shared testbench package
tb/common/mptdc_tb_pkg.sv

// VIP interfaces
tb/vip/interfaces/mptdc_csr_if.sv
tb/vip/interfaces/mptdc_async_io_if.sv
tb/vip/interfaces/mptdc_ref_stop_if.sv
tb/vip/interfaces/mptdc_narrow_if.sv

// VIP package
tb/vip/pkg/mptdc_vip_pkg.sv
