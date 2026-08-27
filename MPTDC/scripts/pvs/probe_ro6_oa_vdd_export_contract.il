; Read-only RO_tune6 OA terminal and label probe.
; The cellView is opened with mode "r" and no OA write API is used.

procedure(mptdcRo6ProbeText(value)
  if(value then
    let((text)
      text = if(stringp(value) then value else sprintf(nil "%L" value))
      rexCompile("[\t\n\r]")
      rexReplace(text " " 0)
    )
  else
    "ABSENT"
  )
)

procedure(mptdcRo6ProbeBox(box)
  if(box then
    sprintf(nil "%.6f\t%.6f\t%.6f\t%.6f"
      car(car(box)) cadr(car(box)) car(cadr(box)) cadr(cadr(box)))
  else
    "UNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN"
  )
)

procedure(mptdcRo6ProbeLayer(object)
  if(object && object~>layerName then
    mptdcRo6ProbeText(object~>layerName)
  else
    "UNKNOWN"
  )
)

procedure(mptdcRo6ProbePurpose(object)
  if(object && object~>purpose then
    mptdcRo6ProbeText(object~>purpose)
  else
    "UNKNOWN"
  )
)

procedure(mptdcRo6ProbeNetName(object)
  if(object && object~>net && object~>net~>name then
    mptdcRo6ProbeText(object~>net~>name)
  else
    "ABSENT"
  )
)

procedure(mptdcRo6ProbeShapeText(object)
  let((attempt value)
    value = nil
    when(object
      attempt = errset(object~>theLabel nil)
      when(attempt value = car(attempt))
      unless(value
        attempt = errset(object~>text nil)
        when(attempt value = car(attempt))
      )
      unless(value
        attempt = errset(object~>value nil)
        when(attempt value = car(attempt))
      )
    )
    mptdcRo6ProbeText(value)
  )
)

procedure(mptdcRo6ProbeMatchesSupply(value)
  value && member(value list("VDD" "VSS" "vdd!" "gnd!"))
)

procedure(mptdcRo6ProbeBoxOverlaps(box target)
  box && target &&
    car(car(box)) < car(cadr(target)) &&
    car(car(target)) < car(cadr(box)) &&
    cadr(car(box)) < cadr(cadr(target)) &&
    cadr(car(target)) < cadr(cadr(box))
)

procedure(mptdcRo6WriteCellSummary(cv path libName cellName viewName)
  let((fp term box)
    fp = outfile(path "w")
    unless(fp error("MPTDC_RO6_OA_PROBE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "STEP=RO6_OA_VDD_EXPORT_PROBE\n")
    fprintf(fp "OA_OPEN_MODE=READ_ONLY\n")
    fprintf(fp "OA_EDIT_AUTHORIZED=NO\n")
    fprintf(fp "LIBRARY=%s\n" libName)
    fprintf(fp "CELL=%s\n" cellName)
    fprintf(fp "VIEW=%s\n" viewName)
    box = cv~>bBox
    fprintf(fp "BBOX=%s\n" mptdcRo6ProbeBox(box))
    fprintf(fp "TERMINAL_COUNT=%d\n" length(cv~>terminals))
    foreach(term cv~>terminals
      fprintf(fp "TERMINAL_NAME=%s\n" mptdcRo6ProbeText(term~>name))
    )
    close(fp)
  )
)

procedure(mptdcRo6WriteTerminalFigures(cv path)
  let((fp term pin fig pinIndex figIndex emitted)
    fp = outfile(path "w")
    unless(fp error("MPTDC_RO6_OA_PROBE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "terminal\tdirection\tnet\tpin_index\tfig_index\tobj_type\tlayer\tpurpose\tllx\tlly\turx\tury\ttext\n")
    foreach(term cv~>terminals
      pinIndex = 0
      emitted = nil
      foreach(pin term~>pins
        figIndex = 0
        foreach(fig pin~>figs
          fprintf(fp "%s\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n"
            mptdcRo6ProbeText(term~>name)
            mptdcRo6ProbeText(term~>direction)
            mptdcRo6ProbeNetName(term)
            pinIndex
            figIndex
            mptdcRo6ProbeText(fig~>objType)
            mptdcRo6ProbeLayer(fig)
            mptdcRo6ProbePurpose(fig)
            mptdcRo6ProbeBox(fig~>bBox)
            mptdcRo6ProbeShapeText(fig))
          figIndex = figIndex + 1
          emitted = t
        )
        unless(pin~>figs
          fprintf(fp "%s\t%s\t%s\t%d\t-1\tABSENT\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tABSENT\n"
            mptdcRo6ProbeText(term~>name)
            mptdcRo6ProbeText(term~>direction)
            mptdcRo6ProbeNetName(term)
            pinIndex)
          emitted = t
        )
        pinIndex = pinIndex + 1
      )
      unless(emitted
        fprintf(fp "%s\t%s\t%s\t-1\t-1\tABSENT\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tABSENT\n"
          mptdcRo6ProbeText(term~>name)
          mptdcRo6ProbeText(term~>direction)
          mptdcRo6ProbeNetName(term))
      )
    )
    close(fp)
  )
)

procedure(mptdcRo6WriteLabelShapes(cv path)
  let((fp shape text)
    fp = outfile(path "w")
    unless(fp error("MPTDC_RO6_OA_PROBE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "obj_type\ttext\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(shape cv~>shapes
      when(shape~>objType == "label" || shape~>objType == "textDisplay"
        text = mptdcRo6ProbeShapeText(shape)
        fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\n"
          mptdcRo6ProbeText(shape~>objType)
          text
          mptdcRo6ProbeNetName(shape)
          mptdcRo6ProbeLayer(shape)
          mptdcRo6ProbePurpose(shape)
          mptdcRo6ProbeBox(shape~>bBox))
      )
    )
    close(fp)
  )
)

procedure(mptdcRo6WriteSupplyNets(cv path)
  let((fp net)
    fp = outfile(path "w")
    unless(fp error("MPTDC_RO6_OA_PROBE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "net\ttop_terminal_count\tinstance_terminal_count\n")
    foreach(net cv~>nets
      when(mptdcRo6ProbeMatchesSupply(net~>name)
        fprintf(fp "%s\t%d\t%d\n"
          mptdcRo6ProbeText(net~>name)
          length(net~>terminals)
          length(net~>instTerms))
      )
    )
    close(fp)
  )
)

procedure(mptdcRo6WriteSupplyTopShapes(cv path)
  let((fp shape netName)
    fp = outfile(path "w")
    unless(fp error("MPTDC_RO6_OA_PROBE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "obj_type\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\ttext\n")
    foreach(shape cv~>shapes
      netName = if(shape~>net then shape~>net~>name else nil)
      when(mptdcRo6ProbeMatchesSupply(netName)
        fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\n"
          mptdcRo6ProbeText(shape~>objType)
          mptdcRo6ProbeNetName(shape)
          mptdcRo6ProbeLayer(shape)
          mptdcRo6ProbePurpose(shape)
          mptdcRo6ProbeBox(shape~>bBox)
          mptdcRo6ProbeShapeText(shape))
      )
    )
    close(fp)
  )
)

procedure(mptdcRo6WriteVddCandidateShapes(cv path)
  let((fp shape goldenVddBox)
    ; MPTDC/docs/pnr/generated/20260630_mptdc_ro_lef_access_patch_nofiller_v1_evidence/lef/GOLDEN_RO_tune6.lef
    goldenVddBox = list(list(-66.670 -71.560) list(-61.525 -68.325))
    fp = outfile(path "w")
    unless(fp error("MPTDC_RO6_OA_PROBE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "obj_type\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\ttext\n")
    foreach(shape cv~>shapes
      when(mptdcRo6ProbeBoxOverlaps(shape~>bBox goldenVddBox)
        fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\n"
          mptdcRo6ProbeText(shape~>objType)
          mptdcRo6ProbeNetName(shape)
          mptdcRo6ProbeLayer(shape)
          mptdcRo6ProbePurpose(shape)
          mptdcRo6ProbeBox(shape~>bBox)
          mptdcRo6ProbeShapeText(shape))
      )
    )
    close(fp)
  )
)

procedure(mptdcRo6OaVddProbeMain()
  let((outRoot libName cellName viewName cv)
    outRoot = getShellEnvVar("MPTDC_RO6_OA_PROBE_ROOT")
    libName = getShellEnvVar("MPTDC_RO6_OA_PROBE_LIBRARY")
    cellName = getShellEnvVar("MPTDC_RO6_OA_PROBE_CELL")
    viewName = getShellEnvVar("MPTDC_RO6_OA_PROBE_VIEW")
    when(viewName == nil || viewName == "" viewName = "layout")
    unless(outRoot && libName && cellName
      error("MPTDC_RO6_OA_PROBE_MISSING_ENV\n"))

    printf("MPTDC_RO6_OA_PROBE_PROGRESS=OPEN_READ_ONLY\n")
    cv = dbOpenCellViewByType(libName cellName viewName "" "r")
    unless(cv
      error("MPTDC_RO6_OA_PROBE_OPEN_FAILED %s/%s/%s\n"
        libName cellName viewName))

    mptdcRo6WriteCellSummary(
      cv strcat(outRoot "/oa_ro6_cell_summary.rpt")
      libName cellName viewName)
    mptdcRo6WriteTerminalFigures(
      cv strcat(outRoot "/oa_ro6_terminal_pin_figs.tsv"))
    mptdcRo6WriteLabelShapes(
      cv strcat(outRoot "/oa_ro6_label_shapes.tsv"))
    mptdcRo6WriteSupplyNets(
      cv strcat(outRoot "/oa_ro6_supply_nets.tsv"))
    mptdcRo6WriteSupplyTopShapes(
      cv strcat(outRoot "/oa_ro6_supply_top_shapes.tsv"))
    mptdcRo6WriteVddCandidateShapes(
      cv strcat(outRoot "/oa_ro6_vdd_candidate_shapes.tsv"))
    dbClose(cv)
    printf("MPTDC_RO6_OA_PROBE_PROGRESS=COMPLETE\n")
    t
  )
)

let((outRoot runResult statusFp)
  outRoot = getShellEnvVar("MPTDC_RO6_OA_PROBE_ROOT")
  runResult = errset(mptdcRo6OaVddProbeMain() t)
  when(outRoot
    statusFp = outfile(strcat(outRoot "/oa_ro6_probe_status.rpt") "w")
    when(statusFp
      fprintf(statusFp "STEP=RO6_OA_VDD_EXPORT_PROBE\n")
      fprintf(statusFp "OA_OPEN_MODE=READ_ONLY\n")
      fprintf(statusFp "OA_EDIT_AUTHORIZED=NO\n")
      if(runResult then
        fprintf(statusFp "OA_PROBE_STATUS=PASS\n")
      else
        fprintf(statusFp "OA_PROBE_STATUS=FAIL\n")
      )
      close(statusFp)
    )
  )
  if(runResult then
    printf("MPTDC_RO6_OA_PROBE_COMPLETION_STATUS=PASS\n")
  else
    printf("MPTDC_RO6_OA_PROBE_COMPLETION_STATUS=FAIL\n")
  )
  exit()
)
