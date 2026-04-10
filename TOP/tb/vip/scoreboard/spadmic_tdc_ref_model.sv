// =============================================================================
// SPADMIC VIP — TDC Reference Model
// Predicts expected TDC packet structure given config and injection.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_tdc_ref_model;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  // Predict expected word count for a TDC packet
  function automatic int unsigned predict_word_count(
    out_mode_e   mode,
    int unsigned hit_count
  );
    int unsigned words_per_hit;
    case (mode)
      OUT_MODE_RAW_FEATURES:  words_per_hit = 1;
      OUT_MODE_RAW_TIMESTAMP: words_per_hit = 1;
      OUT_MODE_FULL:          words_per_hit = 2;
      default:                words_per_hit = 1;
    endcase
    // header + subheader + hit_count×words_per_hit + EOC
    return 2 + hit_count * words_per_hit + 1;
  endfunction

  // Validate a captured TDC packet against expected structure
  function automatic bit validate_tdc_packet(
    logic [15:0]   words[$],
    int unsigned   expected_source,
    out_mode_e     expected_mode,
    int unsigned   expected_max_hits
  );
    if (words.size() < 3) begin
      $display("[TDC_REF] FAIL: packet too short (%0d words)", words.size());
      return 0;
    end

    // Check header marker
    if (!is_tdc_header(words[0])) begin
      $display("[TDC_REF] FAIL: word[0] is not a header (0x%04h)", words[0]);
      return 0;
    end

    // Check subheader marker
    if (!is_tdc_subheader(words[1])) begin
      $display("[TDC_REF] FAIL: word[1] is not a subheader (0x%04h)", words[1]);
      return 0;
    end

    // Check source tag in subheader
    if (words[1][5:4] != expected_source[1:0]) begin
      $display("[TDC_REF] FAIL: source tag %0d != expected %0d",
               words[1][5:4], expected_source);
      return 0;
    end

    // Check EOC at last word
    if (!is_tdc_eoc(words[words.size()-1])) begin
      $display("[TDC_REF] FAIL: last word is not EOC (0x%04h)",
               words[words.size()-1]);
      return 0;
    end

    // Validate hit count from header
    // Header bits [10:7] = hit_count
    begin
      int unsigned hc;
      int unsigned expected_wc;
      hc = words[0][10:7];
      if (hc > expected_max_hits) begin
        $display("[TDC_REF] FAIL: hit_count=%0d > max_hits=%0d", hc, expected_max_hits);
        return 0;
      end

      // Validate word count
      expected_wc = predict_word_count(expected_mode, hc);
      if (words.size() != expected_wc) begin
        $display("[TDC_REF] WARN: word count %0d != predicted %0d (mode=%s hits=%0d)",
                 words.size(), expected_wc, expected_mode.name(), hc);
      end
    end

    return 1;
  endfunction

endclass

`default_nettype wire
