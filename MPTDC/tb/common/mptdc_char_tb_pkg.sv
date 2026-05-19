// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Characterization Collateral
// File    : mptdc_char_tb_pkg.sv
// Purpose : Shared helpers for large MPTDC characterization testbenches.
// =============================================================================
`timescale 1ps/1ps

package mptdc_char_tb_pkg;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  localparam int CHAR_PULSE_W_PS = 1000;
  localparam int CHAR_PACKET_TIMEOUT_CYC = 200_000;
  localparam int CHAR_MAX_PACKET_WORDS = 128;
  localparam int CHAR_PKT_BITS = CHAR_MAX_PACKET_WORDS * NARROW_W;

  function automatic int unsigned char_lcg_next(input int unsigned state);
    return state * 32'd1664525 + 32'd1013904223;
  endfunction

  function automatic int char_rand_range(
    input int unsigned raw,
    input int          lo,
    input int          hi
  );
    int span;
    begin
      span = (hi >= lo) ? (hi - lo + 1) : 1;
      return lo + int'(raw % span);
    end
  endfunction

  function automatic int char_tuple_code(
    input int nslow,
    input int nfast_hit,
    input int ns,
    input int nf,
    input int slow_boundary_inc
  );
    return (((((nslow * 128) + nfast_hit) * int'(NE) + ns) * int'(NE) + nf) * 2)
           + slow_boundary_inc;
  endfunction

  function automatic int char_scalar_bin(input int signed t_raw_ps);
    if (t_raw_ps < 0)
      return -1;
    return t_raw_ps / int'(DELTA_LSB);
  endfunction

  function automatic string char_bool_str(input bit value);
    return value ? "1" : "0";
  endfunction

  task automatic char_write_header(input int fd, input string extra_cols);
    begin
      $fwrite(fd,
        "stage_id,config_id,seed,trial_id,conv_id,hit_idx,Tref_ps,start_time_ps,stop_time_ps,accepted,rejected,ctx_id,hit_count,flags,phase0_snap,slow_boundary_inc,nslow,nfast_hit,ns,nf,t_raw_ps,tuple_code,scalar_bin,max_hits,input_sel,out_mode");
      if (extra_cols != "")
        $fwrite(fd, ",%s", extra_cols);
      $fwrite(fd, "\n");
    end
  endtask

  task automatic char_vip_write_header(input int fd, input string extra_cols = "");
    begin
      $fwrite(fd,
        "schema_version,test_name,seed,config_id,stage,train_valid_split,attempt_id,event_id,conv_id,ctx_id,hit_idx,t_start_fs,t_stop_fs,true_dt_fs,t_start_ps,t_stop_ps,true_dt_ps,accepted,rejected,reject_reason,close_reason,max_hits,out_mode,input_sel,nslow,nfast_hit,ns,nf,ns_inf,nf_inf,phase0_snap,slow_boundary_inc,hit_count,flags,t_raw_ps,reconstructed_time_pre_cal_ps,reconstructed_time_post_cal_ps,residual_pre_cal_ps,residual_post_cal_ps");
      if (extra_cols != "")
        $fwrite(fd, ",%s", extra_cols);
      $fwrite(fd, "\n");
    end
  endtask

  task automatic char_vip_write_jsonl_event(
    input int     fd,
    input string  test_name,
    input int     seed,
    input string  stage,
    input string  split,
    input int     attempt_id,
    input int     event_id,
    input int     accepted,
    input int     rejected,
    input string  reject_reason,
    input longint start_time_ps,
    input longint stop_time_ps,
    input int     max_hits,
    input int     input_sel,
    input int     out_mode
  );
    longint start_fs;
    longint stop_fs;
    longint dt_ps;
    begin
      start_fs = start_time_ps * 1000;
      stop_fs  = stop_time_ps * 1000;
      dt_ps    = (stop_time_ps >= start_time_ps) ? (stop_time_ps - start_time_ps) : -1;
      $fwrite(fd,
        "{\"schema_version\":1,\"test_name\":\"%s\",\"seed\":%0d,\"stage\":\"%s\",\"train_valid_split\":\"%s\",\"attempt_id\":%0d,\"event_id\":%0d,\"accepted\":%0d,\"rejected\":%0d,\"reject_reason\":\"%s\",\"t_start_fs\":%0d,\"t_stop_fs\":%0d,\"true_dt_fs\":%0d,\"t_start_ps\":%0d,\"t_stop_ps\":%0d,\"true_dt_ps\":%0d,\"max_hits\":%0d,\"input_sel\":%0d,\"out_mode\":%0d}\n",
        test_name, seed, stage, split, attempt_id, event_id, accepted, rejected,
        reject_reason, start_fs, stop_fs, dt_ps * 1000, start_time_ps,
        stop_time_ps, dt_ps, max_hits, input_sel, out_mode);
    end
  endtask

  task automatic char_write_summary_row(
    input int    fd,
    input int    stage_id,
    input int    config_id,
    input int    seed,
    input int    trial_id,
    input int    conv_id,
    input int    tref_ps,
    input longint start_time_ps,
    input longint stop_time_ps,
    input bit    accepted,
    input bit    rejected,
    input int    max_hits,
    input int    input_sel,
    input int    out_mode,
    input string extra = ""
  );
    begin
      $fwrite(fd,
        "%0d,%0d,%0d,%0d,%0d,-1,%0d,%0d,%0d,%0d,%0d,-1,0,0,0,0,0,0,0,0,0,-1,-1,%0d,%0d,%0d",
        stage_id, config_id, seed, trial_id, conv_id, tref_ps, start_time_ps,
        stop_time_ps, accepted, rejected, max_hits, input_sel, out_mode);
      if (extra != "")
        $fwrite(fd, ",%s", extra);
      $fwrite(fd, "\n");
    end
  endtask

  task automatic char_collect_packet_timeout(
    ref logic                    clk,
    ref logic                    valid,
    ref logic                    ready,
    ref logic [NARROW_W-1:0]    data,
    output logic [CHAR_PKT_BITS-1:0] words_flat,
    output int                   word_count,
    output bit                   ok,
    input int                    timeout_cycles = CHAR_PACKET_TIMEOUT_CYC
  );
    logic [NARROW_W-1:0] w;
    int cyc;
    begin
      words_flat = '0;
      word_count = 0;
      ok = 1'b0;
      ready = 1'b1;
      cyc = 0;

      while (cyc < timeout_cycles) begin
        @(posedge clk);
        cyc++;
        if (valid && ready) begin
          w = data;
          if (is_header(w)) begin
            if (word_count < CHAR_MAX_PACKET_WORDS)
              words_flat[word_count*NARROW_W +: NARROW_W] = w;
            word_count++;
            break;
          end
        end
      end

      if (word_count == 0)
      begin
        ready = 1'b0;
        return;
      end

      while (cyc < timeout_cycles) begin
        @(posedge clk);
        cyc++;
        if (valid && ready) begin
          w = data;
          if (word_count < CHAR_MAX_PACKET_WORDS)
            words_flat[word_count*NARROW_W +: NARROW_W] = w;
          word_count++;
          if (is_eoc(w)) begin
            ok = 1'b1;
            @(posedge clk);
            ready = 1'b0;
            return;
          end
        end
      end
      ready = 1'b0;
    end
  endtask

  task automatic char_configure(
    ref logic                   clk,
    ref logic                   csr_valid,
    ref logic                   csr_write,
    ref logic [CSR_ADDR_W-1:0] csr_addr,
    ref logic [CSR_DATA_W-1:0] csr_wdata,
    input int                   max_hits,
    input int                   input_sel,
    input int                   out_mode,
    input int                   wdt_ctx,
    input int                   wdt_global
  );
    logic [CSR_DATA_W-1:0] mode_word;
    begin
      mode_word = {28'd0, out_mode[1:0], input_sel[0], 1'b0};
      tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata, CSR_CTRL, 32'h0);
      tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata, CSR_MODE, mode_word);
      tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata,
                   CSR_MAX_HITS, {28'd0, max_hits[3:0]});
      tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata,
                   CSR_WDT_CTX, {16'd0, wdt_ctx[15:0]});
      tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata,
                   CSR_WDT_GLOBAL, {16'd0, wdt_global[15:0]});
    end
  endtask

  task automatic char_arm(
    ref logic                   clk,
    ref logic                   csr_valid,
    ref logic                   csr_write,
    ref logic [CSR_ADDR_W-1:0] csr_addr,
    ref logic [CSR_DATA_W-1:0] csr_wdata
  );
    tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata, CSR_CTRL, 32'h1);
  endtask

  task automatic char_disarm(
    ref logic                   clk,
    ref logic                   csr_valid,
    ref logic                   csr_write,
    ref logic [CSR_ADDR_W-1:0] csr_addr,
    ref logic [CSR_DATA_W-1:0] csr_wdata
  );
    tb_csr_write(clk, csr_valid, csr_write, csr_addr, csr_wdata, CSR_CTRL, 32'h0);
  endtask

  task automatic char_csr_read(
    ref logic                   clk,
    ref logic                   csr_valid,
    ref logic                   csr_write,
    ref logic [CSR_ADDR_W-1:0] csr_addr,
    ref logic [CSR_DATA_W-1:0] csr_wdata,
    ref logic                   csr_rvalid,
    ref logic [CSR_DATA_W-1:0] csr_rdata,
    input logic [CSR_ADDR_W-1:0] addr,
    output logic [CSR_DATA_W-1:0] data
  );
    tb_csr_read(clk, csr_valid, csr_write, csr_addr, csr_wdata,
                csr_rvalid, csr_rdata, addr, data);
  endtask

  task automatic char_inject_pair(
    ref logic start_spad,
    ref logic stop_spad,
    ref logic cal_start,
    ref logic cal_stop,
    input int input_sel,
    input int delay_ps,
    output longint start_time_ps,
    output longint stop_time_ps
  );
    begin
      if (input_sel == int'(INPUT_CAL)) begin
        cal_start = 1'b1;
        start_time_ps = longint'($realtime);
        #(CHAR_PULSE_W_PS);
        cal_start = 1'b0;
        #(delay_ps);
        cal_stop = 1'b1;
        stop_time_ps = longint'($realtime);
        #(CHAR_PULSE_W_PS);
        cal_stop = 1'b0;
      end else begin
        start_spad = 1'b1;
        start_time_ps = longint'($realtime);
        #(CHAR_PULSE_W_PS);
        start_spad = 1'b0;
        #(delay_ps);
        stop_spad = 1'b1;
        stop_time_ps = longint'($realtime);
        #(CHAR_PULSE_W_PS);
        stop_spad = 1'b0;
      end
    end
  endtask

  task automatic char_write_packet_rows(
    input int fd,
    input int stage_id,
    input int config_id,
    input int seed, trial_id, tref_ps,
    input [63:0] start_time_ps, stop_time_ps,
    input int accepted_i, rejected_i, max_hits, input_sel, out_mode, word_count,
    input [CHAR_PKT_BITS-1:0] words_flat,
    input string extra = ""
  );
    int idx;
    int eoc_id;
    int hdr_hit_count;
    int hdr_ctx_id;
    int hdr_phase0;
    int hdr_boundary_inc;
    int hdr_flags;
    int nslow_i;
    int nfast_hit_i;
    int ns_i;
    int nf_i;
    int signed t_raw_ps_i;
    int tuple_code_i;
    int scalar_bin_i;
    int hits_found;
    int error_count;
    logic [NARROW_W-1:0] word0;
    logic [NARROW_W-1:0] word_last;
    logic [NARROW_W-1:0] word_idx;
    logic [NARROW_W-1:0] word_idx1;
    logic [NARROW_W-1:0] word_idx2;
    tb_hit_features_t hf;
    begin
      hits_found = 0;
      error_count = 0;
      word0 = words_flat[0 +: NARROW_W];
      word_last = (word_count > 0)
                ? words_flat[(word_count - 1)*NARROW_W +: NARROW_W]
                : '0;
      if (word_count < 2 || !is_header(word0) || !is_eoc(word_last)) begin
        error_count++;
        char_write_summary_row(fd, stage_id, config_id, seed, trial_id, -1, tref_ps,
                               start_time_ps, stop_time_ps, accepted_i, rejected_i,
                               max_hits, input_sel, out_mode, extra);
        return;
      end

      hdr_hit_count = header_hit_count(word0);
      hdr_ctx_id = header_ctx_id(word0);
      hdr_phase0 = header_phase0(word0);
      hdr_boundary_inc = header_boundary_inc(word0);
      hdr_flags = header_flags(word0);
      eoc_id = eoc_conv_id(word_last);
      idx = 1;

      if (hdr_hit_count == 0) begin
        char_write_summary_row(fd, stage_id, config_id, seed, trial_id, eoc_id, tref_ps,
                               start_time_ps, stop_time_ps, accepted_i, rejected_i,
                               max_hits, input_sel, out_mode, extra);
        return;
      end

      while (idx < word_count) begin
        word_idx = words_flat[idx*NARROW_W +: NARROW_W];
        if (is_eoc(word_idx))
          break;
        if (idx + 1 >= word_count) begin
          error_count++;
          break;
        end

        word_idx1 = words_flat[(idx + 1)*NARROW_W +: NARROW_W];
        hf = parse_hit_features(word_idx, word_idx1);
        nslow_i = hf.nslow;
        nfast_hit_i = hf.nfast;
        ns_i = hf.ns;
        nf_i = hf.nf;

        if (out_mode == int'(OUT_MODE_FULL) && (idx + 2 < word_count)) begin
          word_idx2 = words_flat[(idx + 2)*NARROW_W +: NARROW_W];
          t_raw_ps_i = $signed(word_idx2);
          idx += 3;
        end else begin
          t_raw_ps_i = vernier_tconv_ps(hf.nslow, hf.nfast, hf.ns, hf.nf,
                                        logic'(hdr_boundary_inc));
          idx += 2;
        end

        tuple_code_i = char_tuple_code(nslow_i, nfast_hit_i, ns_i, nf_i,
                                       hdr_boundary_inc);
        scalar_bin_i = char_scalar_bin(t_raw_ps_i);

        $fwrite(fd,
          "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
          stage_id, config_id, seed, trial_id, eoc_id, hits_found, tref_ps,
          start_time_ps, stop_time_ps, accepted_i, rejected_i, hdr_ctx_id,
          hdr_hit_count, hdr_flags, hdr_phase0, hdr_boundary_inc, nslow_i,
          nfast_hit_i, ns_i, nf_i, t_raw_ps_i, tuple_code_i, scalar_bin_i,
          max_hits, input_sel, out_mode);
        if (extra != "")
          $fwrite(fd, ",%s", extra);
        $fwrite(fd, "\n");
        hits_found++;
      end
    end
  endtask

endpackage
