// =============================================================================
// SPADMIC VIP — Fault/Corner Coverage
// Tracks error injection, fault observation, and corner-case scenarios.
// =============================================================================

`ifdef SPADMIC_ENABLE_FUNC_COV

class spadmic_fault_cov;

  logic [7:0] access_cause;
  logic       access_is_write;
  logic [6:0] page_fault_summary;
  logic       reset_during_traffic;
  logic       csr_error_seen;

  covergroup cg_fault;
    cp_access_cause: coverpoint access_cause {
      bins none = {CSR_CAUSE_NONE};
      bins misaligned = {CSR_CAUSE_MISALIGNED};
      bins unmapped = {CSR_CAUSE_UNMAPPED};
      bins read_only_write = {CSR_CAUSE_READ_ONLY_WRITE};
      bins invalid_value = {CSR_CAUSE_INVALID_VALUE};
      bins unsafe_write = {CSR_CAUSE_UNSAFE_WRITE};
      bins incomplete_write = {CSR_CAUSE_INCOMPLETE_WRITE};
      bins i2c_reset_abort = {CSR_CAUSE_I2C_RESET_ABORT};
      illegal_bins unknown = default;
    }
    cp_access_is_write: coverpoint access_is_write;
    cp_page_fault_summary: coverpoint page_fault_summary {
      bins none = {7'b0};
      bins access_only = {7'b0000001};
      bins block_fault = {[7'b0000010:7'b1111111]};
    }
    cp_reset_during: coverpoint reset_during_traffic;
    cp_csr_error: coverpoint csr_error_seen;

    cx_cause_x_direction: cross cp_access_cause, cp_access_is_write;
  endgroup

  function new();
    cg_fault = new();
  endfunction

  function void sample(
    logic [7:0] cause,
    logic is_write,
    logic [6:0] page_faults,
    logic rst_traffic,
    logic csr_error
  );
    access_cause = cause;
    access_is_write = is_write;
    page_fault_summary = page_faults;
    reset_during_traffic = rst_traffic;
    csr_error_seen = csr_error;
    cg_fault.sample();
  endfunction

  function void report();
    $display("[FAULT_COV] Coverage: %.1f%%", cg_fault.get_coverage());
  endfunction

endclass

`endif
