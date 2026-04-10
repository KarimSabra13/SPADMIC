// =============================================================================
// SPADMIC VIP — Position Reference Model
// Predicts expected position packet content from line patterns + config.
// =============================================================================

class spadmic_pos_ref_model;

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

    return 1;
  endfunction

endclass

