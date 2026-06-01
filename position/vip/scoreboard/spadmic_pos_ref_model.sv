// =============================================================================
// SPADMIC VIP — Position Reference Model
// Predicts expected position packet content from line patterns + config.
// =============================================================================

class spadmic_pos_ref_model;

  function automatic logic [2:0] pkt_non_empty_mask(input logic [15:0] hdr);
    return hdr[12:10];
  endfunction

  function automatic logic [2:0] pkt_multi_cluster_mask(input logic [15:0] hdr);
    return is_spadmic_pos_compact_header(hdr) ? hdr[2:0] : 3'b000;
  endfunction

  function automatic logic pkt_overflow_any(input logic [15:0] hdr);
    return hdr[13];
  endfunction

  function automatic spadmic_pos_cluster_slot_mask_t pkt_cluster_slot_mask(input logic [15:0] hdr);
    return is_spadmic_pos_compact_header(hdr)
         ? spadmic_pos_cluster_slot_mask_t'(hdr[8:3])
         : '0;
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

  function automatic logic cluster_word_valid(input logic [15:0] word);
    return word[0];
  endfunction

  function automatic logic [SPADMIC_LINE_IDX_W-1:0] cluster_word_hi(input logic [15:0] word);
    return word[1 +: SPADMIC_LINE_IDX_W];
  endfunction

  function automatic logic [SPADMIC_LINE_IDX_W-1:0] cluster_word_lo(input logic [15:0] word);
    return word[1 + SPADMIC_LINE_IDX_W +: SPADMIC_LINE_IDX_W];
  endfunction

  function automatic logic cluster_word_reserved_clear(input logic [15:0] word);
    return word[NARROW_W-1 : 1 + (2 * SPADMIC_LINE_IDX_W)] == '0;
  endfunction

  function automatic logic [SPADMIC_LINE_IDX_W:0] cluster_span(input spadmic_cluster_t cluster);
    logic [SPADMIC_LINE_IDX_W:0] lo_ext;
    logic [SPADMIC_LINE_IDX_W:0] hi_ext;
    if (!cluster.valid)
      return '0;
    lo_ext = {1'b0, cluster.lo};
    hi_ext = {1'b0, cluster.hi};
    return hi_ext - lo_ext + 1'b1;
  endfunction

  function automatic spadmic_cluster_t filter_cluster(
    input spadmic_cluster_t cluster,
    input logic [SPADMIC_LINE_COUNT_W-1:0] min_span
  );
    spadmic_cluster_t filtered;
    filtered = cluster;
    if (!cluster.valid || (cluster_span(cluster) < min_span)) begin
      filtered.valid = 1'b0;
      filtered.lo    = '0;
      filtered.hi    = '0;
    end
    return filtered;
  endfunction

  function automatic bit cluster_word_matches(
    input logic [15:0]      word,
    input spadmic_cluster_t expected,
    input string            label
  );
    if (!cluster_word_reserved_clear(word)) begin
      $display("[POS_REF] FAIL: %s reserved bits are non-zero in 0x%04h", label, word);
      return 0;
    end
    if (cluster_word_valid(word) != expected.valid) begin
      $display("[POS_REF] FAIL: %s valid=%0b expected %0b",
               label, cluster_word_valid(word), expected.valid);
      return 0;
    end
    if (expected.valid
        && ((cluster_word_lo(word) != expected.lo) || (cluster_word_hi(word) != expected.hi))) begin
      $display("[POS_REF] FAIL: %s range=[%0d,%0d] expected [%0d,%0d]",
               label, cluster_word_lo(word), cluster_word_hi(word), expected.lo, expected.hi);
      return 0;
    end
    return 1;
  endfunction

  // Software cluster-scan reference implementation. Mirrors the RTL's raw scan
  // first, then applies the configured min-span filter.
  function automatic void scan_axis(
    input  logic [SPADMIC_LINE_W-1:0] lines,
    input  logic [SPADMIC_LINE_COUNT_W-1:0] gap_threshold,
    input  logic [SPADMIC_LINE_COUNT_W-1:0] min_span,
    output spadmic_axis_clusters_t     result
  );
    logic [SPADMIC_LINE_COUNT_W-1:0] gap_run;
    bit          in_cluster;
    int unsigned cluster_idx;
    spadmic_axis_clusters_t raw;

    raw       = '0;
    raw.empty = 1'b1;
    in_cluster = 1'b0;
    gap_run = 0;
    cluster_idx = 0;

    for (int i = 0; i < SPADMIC_LINE_W; i++) begin
      if (lines[i]) begin
        if (!in_cluster) begin
          if ((cluster_idx == 0) && !raw.cluster0.valid) begin
            raw.cluster0.valid = 1'b1;
            raw.cluster0.lo    = SPADMIC_LINE_IDX_W'(i);
            raw.cluster0.hi    = SPADMIC_LINE_IDX_W'(i);
          end else if ((cluster_idx == 0) && (gap_run >= gap_threshold)) begin
            cluster_idx = 1;
            if (!raw.cluster1.valid) begin
              raw.cluster1.valid = 1'b1;
              raw.cluster1.lo    = SPADMIC_LINE_IDX_W'(i);
              raw.cluster1.hi    = SPADMIC_LINE_IDX_W'(i);
            end
          end else if ((cluster_idx >= 1) && (gap_run >= gap_threshold)) begin
            raw.overflow = 1'b1;
          end else if (cluster_idx == 0) begin
            raw.cluster0.hi = SPADMIC_LINE_IDX_W'(i);
          end else if ((cluster_idx == 1) && !raw.overflow) begin
            raw.cluster1.hi = SPADMIC_LINE_IDX_W'(i);
          end
          in_cluster = 1'b1;
          gap_run = 0;
        end else begin
          gap_run = 0;
          if (cluster_idx == 0)
            raw.cluster0.hi = SPADMIC_LINE_IDX_W'(i);
          else if ((cluster_idx == 1) && !raw.overflow)
            raw.cluster1.hi = SPADMIC_LINE_IDX_W'(i);
        end
      end else if (in_cluster) begin
        gap_run++;
        if (gap_run >= gap_threshold)
          in_cluster = 1'b0;
      end
    end

    raw.empty = ~raw.cluster0.valid;
    raw.cluster_count = {1'b0, raw.cluster0.valid} + {1'b0, raw.cluster1.valid};

    result = '0;
    result.cluster0 = filter_cluster(raw.cluster0, min_span);
    result.cluster1 = filter_cluster(raw.cluster1, min_span);
    result.overflow = raw.overflow;
    result.empty    = ~(result.cluster0.valid | result.cluster1.valid);
    result.cluster_count = {1'b0, result.cluster0.valid} + {1'b0, result.cluster1.valid};
  endfunction

  // Validate a captured position packet against expected content
  function automatic bit validate_pos_packet(
    logic [15:0] words[$],
    logic [SPADMIC_LINE_W-1:0] x_pattern,
    logic [SPADMIC_LINE_W-1:0] y_pattern,
    logic [SPADMIC_LINE_W-1:0] z_pattern,
    logic [SPADMIC_LINE_COUNT_W-1:0] gap_threshold,
    logic [SPADMIC_LINE_COUNT_W-1:0] min_span
  );
    spadmic_axis_clusters_t expected_axis[3];
    spadmic_cluster_t expected_slots[SPADMIC_POS_CLUSTER_SLOT_COUNT];
    spadmic_pos_cluster_slot_mask_t expected_slot_mask;
    bit compact_packet;

    if (!is_spadmic_pos_cluster_header(words[0])) begin
      $display("[POS_REF] FAIL: word[0] is not a cluster position header (0x%04h)", words[0]);
      return 0;
    end

    if (!is_tdc_eoc(words[words.size()-1])) begin
      $display("[POS_REF] FAIL: last word not EOC (0x%04h)", words[words.size()-1]);
      return 0;
    end

    scan_axis(x_pattern, gap_threshold, min_span, expected_axis[0]);
    scan_axis(y_pattern, gap_threshold, min_span, expected_axis[1]);
    scan_axis(z_pattern, gap_threshold, min_span, expected_axis[2]);
    compact_packet = is_spadmic_pos_compact_header(words[0]);
    expected_slot_mask = spadmic_pos_cluster_slot_mask(
      expected_axis[0],
      expected_axis[1],
      expected_axis[2]
    );
    expected_slots[0] = expected_axis[0].cluster0;
    expected_slots[1] = expected_axis[0].cluster1;
    expected_slots[2] = expected_axis[1].cluster0;
    expected_slots[3] = expected_axis[1].cluster1;
    expected_slots[4] = expected_axis[2].cluster0;
    expected_slots[5] = expected_axis[2].cluster1;

    if (pkt_non_empty_mask(words[0]) != {
        !expected_axis[2].empty,
        !expected_axis[1].empty,
        !expected_axis[0].empty}) begin
      $display("[POS_REF] FAIL: header non-empty mask mismatch");
      return 0;
    }

    if (compact_packet) begin
      int word_idx;
      int expected_words;

      expected_words = 1 + int'(spadmic_pos_cluster_slot_count(expected_slot_mask)) + 1;
      if (words.size() != expected_words) begin
        $display("[POS_REF] FAIL: compact packet has %0d words (expected %0d)",
                 words.size(), expected_words);
        return 0;
      end

      if (pkt_cluster_slot_mask(words[0]) != expected_slot_mask) begin
        $display("[POS_REF] FAIL: compact slot mask 0x%0h expected 0x%0h",
                 pkt_cluster_slot_mask(words[0]), expected_slot_mask);
        return 0;
      end

      if (pkt_multi_cluster_mask(words[0]) != {
          (expected_axis[2].cluster_count > 2'd1),
          (expected_axis[1].cluster_count > 2'd1),
          (expected_axis[0].cluster_count > 2'd1)}) begin
        $display("[POS_REF] FAIL: compact multi-cluster mask mismatch");
        return 0;
      end

      word_idx = 1;
      for (int slot = 0; slot < SPADMIC_POS_CLUSTER_SLOT_COUNT; slot++) begin
        if (expected_slot_mask[slot]) begin
          if (!cluster_word_matches(words[word_idx], expected_slots[slot],
                                    $sformatf("compact slot%0d", slot)))
            return 0;
          word_idx++;
        end
      end
    end else if (words.size() != SPADMIC_POS_PKT_WORDS) begin
      $display("[POS_REF] FAIL: packet has %0d words (expected %0d)",
               words.size(), SPADMIC_POS_PKT_WORDS);
      return 0;
    end

    if (!compact_packet) begin
      for (int axis = 0; axis < 3; axis++) begin
        automatic int cluster0_idx = 1 + axis * 2;
        automatic int cluster1_idx = cluster0_idx + 1;
        logic [1:0] cluster_count;
        logic       cluster0_valid;
        logic       cluster1_valid;
        logic       expect_non_empty;
        spadmic_axis_clusters_t exp_axis;

        exp_axis = expected_axis[axis];

        cluster_count   = {1'b0, cluster_word_valid(words[cluster0_idx])}
                        + {1'b0, cluster_word_valid(words[cluster1_idx])};
        cluster0_valid  = words[cluster0_idx][0];
        cluster1_valid  = words[cluster1_idx][0];
        expect_non_empty = pkt_non_empty_mask(words[0])[axis];

        if (expect_non_empty != (cluster0_valid | cluster1_valid)) begin
          $display("[POS_REF] FAIL: axis %0d header non-empty mask mismatch", axis);
          return 0;
        end

        if ((cluster_count != exp_axis.cluster_count) ||
            ((cluster0_valid | cluster1_valid) != !exp_axis.empty)) begin
          $display("[POS_REF] FAIL: axis %0d cluster valid bits do not match expected filtered clusters", axis);
          return 0;
        end

        if (!cluster_word_matches(words[cluster0_idx], exp_axis.cluster0,
                                  $sformatf("axis%0d cluster0", axis)))
          return 0;
        if (!cluster_word_matches(words[cluster1_idx], exp_axis.cluster1,
                                  $sformatf("axis%0d cluster1", axis)))
          return 0;
      end
    end

    if (pkt_overflow_any(words[0]) !=
        (expected_axis[0].overflow | expected_axis[1].overflow | expected_axis[2].overflow)) begin
      $display("[POS_REF] FAIL: header overflow_any does not match expected per-axis overflow");
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
