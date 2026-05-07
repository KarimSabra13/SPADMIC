// =============================================================================
// SPADMIC VIP — Position Reference Model
// Predicts expected position packet content from line patterns + config.
// =============================================================================

class spadmic_pos_ref_model;

  function automatic logic [2:0] pkt_non_empty_mask(input logic [15:0] hdr);
    return hdr[11:9];
  endfunction

  function automatic logic [2:0] pkt_multi_cluster_mask(input logic [15:0] hdr);
    return hdr[8:6];
  endfunction

  function automatic logic pkt_overflow_any(input logic [15:0] hdr);
    return hdr[12];
  endfunction

  function automatic logic [1:0] axis_summary_id(input logic [15:0] word);
    return word[14:13];
  endfunction

  function automatic logic axis_summary_overflow(input logic [15:0] word);
    return word[12];
  endfunction

  function automatic logic [1:0] axis_summary_cluster_count(input logic [15:0] word);
    return word[11:10];
  endfunction

  function automatic logic axis_summary_empty(input logic [15:0] word);
    return word[9];
  endfunction

  // Software cluster-scan reference implementation
  function automatic void scan_axis(
    input  logic [SPADMIC_LINE_W-1:0] lines,
    input  int unsigned               gap_threshold,
    input  int unsigned               min_span,
    output spadmic_axis_clusters_t     result
  );
    int unsigned cluster_lo, cluster_hi;
    int unsigned gap_count;
    bit          in_cluster;
    int unsigned found_clusters;
    spadmic_cluster_t clusters[2];

    result       = '0;
    result.empty = 1'b1;
    in_cluster   = 1'b0;
    found_clusters = 0;
    clusters[0]  = '0;
    clusters[1]  = '0;

    for (int i = 0; i < SPADMIC_LINE_W; i++) begin
      if (lines[i]) begin
        result.empty = 1'b0;
        if (!in_cluster) begin
          in_cluster = 1'b1;
          cluster_lo = i;
          cluster_hi = i;
          gap_count  = 0;
        end else begin
          cluster_hi = i;
          gap_count  = 0;
        end
      end else if (in_cluster) begin
        gap_count++;
        if (gap_count >= gap_threshold) begin
          // Close cluster
          if ((cluster_hi - cluster_lo + 1) >= min_span) begin
            if (found_clusters < 2) begin
              clusters[found_clusters].valid = 1'b1;
              clusters[found_clusters].lo    = cluster_lo[SPADMIC_LINE_IDX_W-1:0];
              clusters[found_clusters].hi    = cluster_hi[SPADMIC_LINE_IDX_W-1:0];
              found_clusters++;
            end else begin
              result.overflow = 1'b1;
            end
          end
          in_cluster = 1'b0;
        end
      end
    end

    // Close any open cluster at the end
    if (in_cluster && (cluster_hi - cluster_lo + 1) >= min_span) begin
      if (found_clusters < 2) begin
        clusters[found_clusters].valid = 1'b1;
        clusters[found_clusters].lo    = cluster_lo[SPADMIC_LINE_IDX_W-1:0];
        clusters[found_clusters].hi    = cluster_hi[SPADMIC_LINE_IDX_W-1:0];
        found_clusters++;
      end else begin
        result.overflow = 1'b1;
      end
    end

    result.cluster_count = found_clusters[1:0];
    result.cluster0      = clusters[0];
    result.cluster1      = clusters[1];
  endfunction

  // Validate a captured position packet against expected content
  function automatic bit validate_pos_packet(
    logic [15:0] words[$],
    logic [SPADMIC_LINE_W-1:0] x_pattern,
    logic [SPADMIC_LINE_W-1:0] y_pattern,
    logic [SPADMIC_LINE_W-1:0] z_pattern,
    int unsigned gap_threshold,
    int unsigned min_span
  );
    if (words.size() != SPADMIC_POS_PKT_WORDS) begin
      $display("[POS_REF] FAIL: packet has %0d words (expected %0d)",
               words.size(), SPADMIC_POS_PKT_WORDS);
      return 0;
    end

    // Check header marker
    if (!is_tdc_header(words[0])) begin
      $display("[POS_REF] FAIL: word[0] is not a header (0x%04h)", words[0]);
      return 0;
    end

    // Check EOC at last word
    if (!is_tdc_eoc(words[words.size()-1])) begin
      $display("[POS_REF] FAIL: last word not EOC (0x%04h)", words[words.size()-1]);
      return 0;
    end

    // Check subheader source = POSITION
    if (words[1][5:4] != SPADMIC_SRC_POSITION) begin
      $display("[POS_REF] FAIL: subheader source=%0d != POSITION(%0d)",
               words[1][5:4], SPADMIC_SRC_POSITION);
      return 0;
    end

    if (words[1][11:9] != pkt_non_empty_mask(words[0])) begin
      $display("[POS_REF] FAIL: subheader qualifying mask %03b != header non-empty mask %03b",
               words[1][11:9], pkt_non_empty_mask(words[0]));
      return 0;
    end

    if (axis_summary_id(words[2]) != TDC_ID_X ||
        axis_summary_id(words[5]) != TDC_ID_Y ||
        axis_summary_id(words[8]) != TDC_ID_Z) begin
      $display("[POS_REF] FAIL: axis summary order/tag mismatch");
      return 0;
    end

    for (int axis = 0; axis < 3; axis++) begin
      automatic int summary_idx = 2 + axis * 3;
      automatic int cluster0_idx = summary_idx + 1;
      automatic int cluster1_idx = summary_idx + 2;
      logic [1:0] cluster_count;
      logic       cluster0_valid;
      logic       cluster1_valid;
      logic       expect_non_empty;
      logic       expect_multi;

      cluster_count   = axis_summary_cluster_count(words[summary_idx]);
      cluster0_valid  = words[cluster0_idx][0];
      cluster1_valid  = words[cluster1_idx][0];
      expect_non_empty = pkt_non_empty_mask(words[0])[axis];
      expect_multi     = pkt_multi_cluster_mask(words[0])[axis];

      if ((cluster_count != {1'b0, cluster0_valid} + {1'b0, cluster1_valid}) ||
          (axis_summary_empty(words[summary_idx]) != ~(cluster0_valid | cluster1_valid))) begin
        $display("[POS_REF] FAIL: axis %0d summary does not match cluster valid bits", axis);
        return 0;
      end

      if (expect_non_empty != ~axis_summary_empty(words[summary_idx])) begin
        $display("[POS_REF] FAIL: axis %0d header non-empty mask mismatch", axis);
        return 0;
      end

      if (expect_multi != (cluster_count > 2'd1)) begin
        $display("[POS_REF] FAIL: axis %0d multi-cluster mask mismatch", axis);
        return 0;
      end
    end

    if (pkt_overflow_any(words[0]) !=
        (axis_summary_overflow(words[2]) | axis_summary_overflow(words[5]) | axis_summary_overflow(words[8]))) begin
      $display("[POS_REF] FAIL: header overflow_any does not match per-axis overflow");
      return 0;
    end

    return 1;
  endfunction

  function automatic bit validate_raw_pos_packet(
    logic [15:0] words[$],
    logic [SPADMIC_LINE_W-1:0] x_pattern,
    logic [SPADMIC_LINE_W-1:0] y_pattern,
    logic [SPADMIC_LINE_W-1:0] z_pattern,
    bit                        check_payload
  );
    logic [2:0] expected_mask;

    if (words.size() != SPADMIC_POS_RAW_PKT_WORDS) begin
      $display("[POS_REF] FAIL: raw packet has %0d words (expected %0d)",
               words.size(), SPADMIC_POS_RAW_PKT_WORDS);
      return 0;
    end

    if (!is_spadmic_pos_raw_header(words[0])) begin
      $display("[POS_REF] FAIL: raw word[0] is not raw header (0x%04h)", words[0]);
      return 0;
    end

    if (!is_tdc_eoc(words[SPADMIC_POS_RAW_PKT_WORDS-1])) begin
      $display("[POS_REF] FAIL: raw final word is not EOC (0x%04h)",
               words[SPADMIC_POS_RAW_PKT_WORDS-1]);
      return 0;
    end

    if (check_payload) begin
      expected_mask = {|z_pattern, |y_pattern, |x_pattern};
      if (words[0][11:9] != expected_mask) begin
        $display("[POS_REF] FAIL: raw non-empty mask %03b != expected %03b",
                 words[0][11:9], expected_mask);
        return 0;
      end

      for (int idx = 0; idx < SPADMIC_POS_RAW_WORDS_PER_AXIS; idx++) begin
        if (words[1 + idx] != spadmic_pos_raw_word(x_pattern, idx)) begin
          $display("[POS_REF] FAIL: raw X word%0d 0x%04h != expected 0x%04h",
                   idx, words[1 + idx], spadmic_pos_raw_word(x_pattern, idx));
          return 0;
        end
        if (words[1 + SPADMIC_POS_RAW_WORDS_PER_AXIS + idx] != spadmic_pos_raw_word(y_pattern, idx)) begin
          $display("[POS_REF] FAIL: raw Y word%0d 0x%04h != expected 0x%04h",
                   idx, words[1 + SPADMIC_POS_RAW_WORDS_PER_AXIS + idx], spadmic_pos_raw_word(y_pattern, idx));
          return 0;
        end
        if (words[1 + (2 * SPADMIC_POS_RAW_WORDS_PER_AXIS) + idx] != spadmic_pos_raw_word(z_pattern, idx)) begin
          $display("[POS_REF] FAIL: raw Z word%0d 0x%04h != expected 0x%04h",
                   idx, words[1 + (2 * SPADMIC_POS_RAW_WORDS_PER_AXIS) + idx], spadmic_pos_raw_word(z_pattern, idx));
          return 0;
        end
      end
    end

    return 1;
  endfunction

endclass
