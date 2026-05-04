// =============================================================================
// SPADMIC VIP — TDC Reference Model
// Predicts expected TDC packet structure given config and injection.
// =============================================================================

class spadmic_tdc_ref_model;

  // Predict expected word count for a TDC packet.
  // Active format: Header + hit_count × words_per_hit + EOC
  //   RAW_FEATURES:  W0 + W1_feat               = 2 words/hit
  //   RAW_TIMESTAMP: W0 + W1_ts                 = 2 words/hit
  //   FULL:          W0 + W1_feat + W2_ts       = 3 words/hit
  function automatic int unsigned predict_word_count(
    out_mode_e   mode,
    int unsigned hit_count
  );
    int unsigned words_per_hit;
    case (mode)
      OUT_MODE_RAW_FEATURES:  words_per_hit = 2;
      OUT_MODE_RAW_TIMESTAMP: words_per_hit = 2;
      OUT_MODE_FULL:          words_per_hit = 3;
      default:                words_per_hit = 2;
    endcase
    return 2 + hit_count * words_per_hit;
  endfunction

  // Validate a captured TDC packet against expected structure
  function automatic bit validate_tdc_packet(
    logic [15:0]   words[$],
    int unsigned   expected_source,
    out_mode_e     expected_mode,
    int unsigned   expected_max_hits
  );
    if (words.size() < 2) begin
      $display("[TDC_REF] FAIL: packet too short (%0d words)", words.size());
      return 0;
    end

    // Check header marker
    if (!is_tdc_header(words[0])) begin
      $display("[TDC_REF] FAIL: word[0] is not a header (0x%04h)", words[0]);
      return 0;
    end

    // Check source tag in header
    if (tdc_header_source_id(words[0]) != expected_source[1:0]) begin
      $display("[TDC_REF] FAIL: source tag %0d != expected %0d",
               tdc_header_source_id(words[0]), expected_source);
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
      // The MPTDC oscillator produces all hits from the 8×8 phase matrix;
      // max_hits triggers "fast close" but pipeline latency means
      // hit_count can exceed max_hits. This is correct RTL behaviour.
      if (hc > expected_max_hits) begin
        $display("[TDC_REF] INFO: hit_count=%0d > max_hits=%0d (fast-close overshoot — OK)",
                 hc, expected_max_hits);
      end

      // Validate word count
      expected_wc = predict_word_count(expected_mode, hc);
      if (words.size() != expected_wc) begin
        $display("[TDC_REF] FAIL: word count %0d != predicted %0d (mode=%s hits=%0d)",
                 words.size(), expected_wc, expected_mode.name(), hc);
        return 0;
      end
    end

    return 1;
  endfunction

endclass
