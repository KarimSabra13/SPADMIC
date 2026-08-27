; Attach the existing RO_tune6 VDD METTP pin shape and add one VDD label.
; The caller must create and verify an immutable OA backup before this script.

procedure(mptdcRo6RepairText(value)
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

procedure(mptdcRo6RepairBoxEquals(box expected)
  box && expected &&
    abs(car(car(box)) - car(car(expected))) <= 0.000001 &&
    abs(cadr(car(box)) - cadr(car(expected))) <= 0.000001 &&
    abs(car(cadr(box)) - car(cadr(expected))) <= 0.000001 &&
    abs(cadr(cadr(box)) - cadr(cadr(expected))) <= 0.000001
)

procedure(mptdcRo6RepairShapeText(object)
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
    mptdcRo6RepairText(value)
  )
)

procedure(mptdcRo6RepairFigOwnedByAnyPin(cv targetFig)
  let((found)
    found = nil
    foreach(term cv~>terminals
      foreach(pin term~>pins
        foreach(fig pin~>figs
          when(fig == targetFig found = t)
        )
      )
    )
    found
  )
)

procedure(mptdcRo6RepairPinOwnsFig(pin targetFig)
  let((found)
    found = nil
    foreach(fig pin~>figs
      when(fig == targetFig found = t)
    )
    found
  )
)

procedure(mptdcRo6VddPinLabelRepairMain()
  let((libName cellName viewName reportPath authorization cv vddNet vddTerm
        vssTerm vddAliasTerm gndAliasTerm targetBox targetShapes targetFig
        preTerminalCount preShapeCount preInstanceCount preVddPinCount
        preVddLabelCount preVddAliasPinCount preGndAliasPinCount
        createdPin createdLabel postVddLabels postVddPinCount postShapeCount
        postInstanceCount postTerminalCount fp)
    libName = getShellEnvVar("MPTDC_RO6_OA_REPAIR_LIBRARY")
    cellName = getShellEnvVar("MPTDC_RO6_OA_REPAIR_CELL")
    viewName = getShellEnvVar("MPTDC_RO6_OA_REPAIR_VIEW")
    reportPath = getShellEnvVar("MPTDC_RO6_OA_REPAIR_REPORT")
    authorization = getShellEnvVar("MPTDC_RO6_OA_REPAIR_AUTHORIZATION")
    when(viewName == nil || viewName == "" viewName = "layout")
    unless(authorization == "EXACT_RO6_VDD_METTP_PIN_LABEL_BACKUP_VERIFIED"
      error("MPTDC_RO6_OA_VDD_REPAIR_AUTHORIZATION_REJECTED\n"))
    unless(libName && cellName && reportPath
      error("MPTDC_RO6_OA_VDD_REPAIR_MISSING_ENV\n"))
    unless(libName == "Prj_xh018_ksabra" && cellName == "RO_tune6" &&
           viewName == "layout"
      error("MPTDC_RO6_OA_VDD_REPAIR_TARGET_REJECTED %s/%s/%s\n"
        libName cellName viewName))

    targetBox = list(list(-68.700 -31.950) list(-66.670 -30.115))
    cv = dbOpenCellViewByType(libName cellName viewName "" "a")
    unless(cv
      error("MPTDC_RO6_OA_VDD_REPAIR_OPEN_FAILED %s/%s/%s\n"
        libName cellName viewName))

    vddNet = dbFindNetByName(cv "VDD")
    vddTerm = dbFindTermByName(cv "VDD")
    vssTerm = dbFindTermByName(cv "VSS")
    vddAliasTerm = dbFindTermByName(cv "vdd!")
    gndAliasTerm = dbFindTermByName(cv "gnd!")
    unless(vddNet && vddTerm && vddTerm~>net == vddNet &&
           vddTerm~>direction == "inputOutput"
      error("MPTDC_RO6_OA_VDD_REPAIR_VDD_TERM_NET_CONTRACT_FAILED\n"))
    unless(vssTerm && length(vssTerm~>pins) == 2
      error("MPTDC_RO6_OA_VDD_REPAIR_VSS_CONTRACT_FAILED\n"))
    unless(vddAliasTerm && gndAliasTerm &&
           length(vddAliasTerm~>pins) == 0 && length(gndAliasTerm~>pins) == 0
      error("MPTDC_RO6_OA_VDD_REPAIR_EMPTY_ALIAS_CONTRACT_FAILED\n"))

    preTerminalCount = length(cv~>terminals)
    preShapeCount = length(cv~>shapes)
    preInstanceCount = length(cv~>instances)
    preVddPinCount = length(vddTerm~>pins)
    preVddAliasPinCount = length(vddAliasTerm~>pins)
    preGndAliasPinCount = length(gndAliasTerm~>pins)
    preVddLabelCount = length(setof(shape cv~>shapes
      (shape~>objType == "label" || shape~>objType == "textDisplay") &&
      mptdcRo6RepairShapeText(shape) == "VDD"))
    unless(preTerminalCount == 21 && preVddPinCount == 0 &&
           preVddLabelCount == 0
      error("MPTDC_RO6_OA_VDD_REPAIR_PRECONDITION_FAILED terms=%d pins=%d labels=%d\n"
        preTerminalCount preVddPinCount preVddLabelCount))

    targetShapes = setof(shape cv~>shapes
      shape~>objType == "rect" &&
      shape~>net == vddNet &&
      shape~>layerName == "METTP" &&
      shape~>purpose == "pin" &&
      mptdcRo6RepairBoxEquals(shape~>bBox targetBox))
    unless(length(targetShapes) == 1
      error("MPTDC_RO6_OA_VDD_REPAIR_TARGET_SHAPE_COUNT=%d\n"
        length(targetShapes)))
    targetFig = car(targetShapes)
    when(mptdcRo6RepairFigOwnedByAnyPin(cv targetFig)
      error("MPTDC_RO6_OA_VDD_REPAIR_TARGET_ALREADY_PIN_OWNED\n"))

    createdPin = dbCreatePin(vddNet targetFig nil vddTerm)
    unless(createdPin && mptdcRo6RepairPinOwnsFig(createdPin targetFig)
      error("MPTDC_RO6_OA_VDD_REPAIR_PIN_ATTACH_FAILED\n"))
    createdLabel = dbCreateLabel(
      cv list("MET3" "TEXT") list(-67.685 -31.0325)
      "VDD" "centerCenter" "R0" "roman" 0.100)
    unless(createdLabel
      error("MPTDC_RO6_OA_VDD_REPAIR_LABEL_CREATE_FAILED\n"))

    postVddPinCount = length(vddTerm~>pins)
    postVddLabels = setof(shape cv~>shapes
      (shape~>objType == "label" || shape~>objType == "textDisplay") &&
      mptdcRo6RepairShapeText(shape) == "VDD")
    postShapeCount = length(cv~>shapes)
    postInstanceCount = length(cv~>instances)
    postTerminalCount = length(cv~>terminals)
    unless(postVddPinCount == 1 && length(postVddLabels) == 1 &&
           postShapeCount == preShapeCount + 1 &&
           postInstanceCount == preInstanceCount &&
           postTerminalCount == preTerminalCount &&
           length(vddAliasTerm~>pins) == preVddAliasPinCount &&
           length(gndAliasTerm~>pins) == preGndAliasPinCount
      error("MPTDC_RO6_OA_VDD_REPAIR_IN_MEMORY_POSTCHECK_FAILED\n"))
    unless(dbSave(cv)
      error("MPTDC_RO6_OA_VDD_REPAIR_SAVE_FAILED\n"))

    fp = outfile(reportPath "w")
    unless(fp
      error("MPTDC_RO6_OA_VDD_REPAIR_REPORT_OPEN_FAILED %s\n" reportPath))
    fprintf(fp "STEP=RO6_OA_VDD_PIN_LABEL_REPAIR\n")
    fprintf(fp "STATUS=PASS\n")
    fprintf(fp "TARGET=%s/%s/%s\n" libName cellName viewName)
    fprintf(fp "TARGET_NET=VDD\n")
    fprintf(fp "TARGET_LAYER=METTP\n")
    fprintf(fp "TARGET_PURPOSE=pin\n")
    fprintf(fp "TARGET_BOX=-68.700000,-31.950000,-66.670000,-30.115000\n")
    fprintf(fp "LABEL_LAYER=MET3\n")
    fprintf(fp "LABEL_PURPOSE=TEXT\n")
    fprintf(fp "LABEL_TEXT=VDD\n")
    fprintf(fp "LABEL_ORIGIN=-67.685000,-31.032500\n")
    fprintf(fp "PRE_TERMINAL_COUNT=%d\n" preTerminalCount)
    fprintf(fp "POST_TERMINAL_COUNT=%d\n" postTerminalCount)
    fprintf(fp "PRE_SHAPE_COUNT=%d\n" preShapeCount)
    fprintf(fp "POST_SHAPE_COUNT=%d\n" postShapeCount)
    fprintf(fp "PRE_INSTANCE_COUNT=%d\n" preInstanceCount)
    fprintf(fp "POST_INSTANCE_COUNT=%d\n" postInstanceCount)
    fprintf(fp "PRE_VDD_PIN_COUNT=%d\n" preVddPinCount)
    fprintf(fp "POST_VDD_PIN_COUNT=%d\n" postVddPinCount)
    fprintf(fp "PRE_VDD_LABEL_COUNT=%d\n" preVddLabelCount)
    fprintf(fp "POST_VDD_LABEL_COUNT=%d\n" length(postVddLabels))
    fprintf(fp "CREATED_METAL_SHAPE_COUNT=0\n")
    fprintf(fp "DELETED_OBJECT_COUNT=0\n")
    fprintf(fp "MOVED_OBJECT_COUNT=0\n")
    fprintf(fp "RENAMED_NET_COUNT=0\n")
    fprintf(fp "RENAMED_TERMINAL_COUNT=0\n")
    fprintf(fp "GLOBAL_ALIAS_EDIT_COUNT=0\n")
    fprintf(fp "SCHEMATIC_EDIT_COUNT=0\n")
    fprintf(fp "OA_REPAIR_STATUS=PASS\n")
    close(fp)
    dbClose(cv)
    t
  )
)

let((reportPath statusPath result statusFp)
  reportPath = getShellEnvVar("MPTDC_RO6_OA_REPAIR_REPORT")
  statusPath = getShellEnvVar("MPTDC_RO6_OA_REPAIR_STATUS")
  result = errset(mptdcRo6VddPinLabelRepairMain() t)
  when(statusPath
    statusFp = outfile(statusPath "w")
    when(statusFp
      fprintf(statusFp "STEP=RO6_OA_VDD_PIN_LABEL_REPAIR\n")
      if(result then
        fprintf(statusFp "OA_REPAIR_STATUS=PASS\n")
      else
        fprintf(statusFp "OA_REPAIR_STATUS=FAIL\n")
      )
      close(statusFp)
    )
  )
  if(result then
    printf("MPTDC_RO6_OA_VDD_REPAIR_COMPLETION_STATUS=PASS\n")
  else
    printf("MPTDC_RO6_OA_VDD_REPAIR_COMPLETION_STATUS=FAIL\n")
  )
  exit()
)
