; Read-only hierarchical METTP context probe around the selected I6 PG pair.
; The source cellView is opened with mode "r"; no OA write API is used.

procedure(spadmicCorridorText(value)
  if(value then
    let((text)
      text = if(stringp(value) then value else sprintf(nil "%L" value))
      rexCompile("[\t\n\r]")
      text = rexReplace(text " " 0)
      text
    )
  else
    "ABSENT"
  )
)

procedure(spadmicCorridorBox(box)
  if(box then
    sprintf(nil "%.6f\t%.6f\t%.6f\t%.6f"
      car(car(box)) cadr(car(box)) car(cadr(box)) cadr(cadr(box)))
  else
    "UNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN"
  )
)

procedure(spadmicCorridorNetName(object)
  if(object && object~>net && object~>net~>name then
    spadmicCorridorText(object~>net~>name)
  else
    "ABSENT"
  )
)

procedure(spadmicCorridorLayer(object)
  if(object && object~>layerName then
    spadmicCorridorText(object~>layerName)
  else
    "UNKNOWN"
  )
)

procedure(spadmicCorridorPurpose(object)
  if(object && object~>purpose then
    spadmicCorridorText(object~>purpose)
  else
    "UNKNOWN"
  )
)

procedure(spadmicCorridorLeaf(path)
  if(atom(path) then path else car(last(path)))
)

procedure(spadmicCorridorDepth(path)
  if(atom(path) then 0 else length(path) - 1)
)

procedure(spadmicCorridorTopInstance(path)
  let((entry object)
    if(atom(path) then
      "TOP"
    else
      entry = car(path)
      object = if(atom(entry) then entry else car(entry))
      if(object && object~>name then
        spadmicCorridorText(object~>name)
      else
        "UNKNOWN")
    )
  )
)

procedure(spadmicCorridorWriteIdentity(
    cv path libName cellName viewName sourcePath)
  let((fp box)
    fp = outfile(path "w")
    fprintf(fp "role\tlibrary\tcell\tview\tfilesystem_path\topen_status\tbbox\n")
    box = cv~>bBox
    fprintf(fp "spadmic2\t%s\t%s\t%s\t%s\tPASS\t%s\n"
      libName cellName viewName sourcePath
      if(box then
        sprintf(nil "%.6f %.6f %.6f %.6f"
          car(car(box)) cadr(car(box)) car(cadr(box)) cadr(cadr(box)))
      else
        "UNKNOWN"))
    close(fp)
  )
)

procedure(spadmicCorridorFindTarget(cv targetName)
  car(setof(inst cv~>instances inst~>name == targetName))
)

procedure(spadmicCorridorWriteTargetInstance(path inst)
  let((fp master)
    master = inst~>master
    fp = outfile(path "w")
    fprintf(fp "instance\tinstance_object_type\tmaster_library\tmaster_cell\tmaster_view\torient\ttransform\tllx\tlly\turx\tury\n")
    fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
      spadmicCorridorText(inst~>name)
      spadmicCorridorText(inst~>objType)
      spadmicCorridorText(master~>libName)
      spadmicCorridorText(master~>cellName)
      spadmicCorridorText(master~>viewName)
      spadmicCorridorText(inst~>orient)
      spadmicCorridorText(inst~>transform)
      spadmicCorridorBox(inst~>bBox))
    close(fp)
  )
)

procedure(spadmicCorridorWriteTargetPins(path inst)
  let((fp master transform term termName pin fig transformed emitted count)
    fp = outfile(path "w")
    fprintf(fp "instance\tterminal\tdirection\tnet\tshape_type\tlayer\tpurpose\tmaster_llx\tmaster_lly\tmaster_urx\tmaster_ury\tllx\tlly\turx\tury\ttransform_status\n")
    master = inst~>master
    transform = inst~>transform
    count = 0
    unless(transform
      error("SPADMIC_CORRIDOR_TARGET_TRANSFORM_UNAVAILABLE\n"))
    foreach(term master~>terminals
      termName = term~>name
      when(termName == "DVDD" || termName == "DVSS"
        emitted = nil
        foreach(pin term~>pins
          foreach(fig pin~>figs
            transformed = dbTransformBBox(fig~>bBox transform)
            fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tDB_INSTANCE_TRANSFORM\n"
              spadmicCorridorText(inst~>name)
              spadmicCorridorText(termName)
              spadmicCorridorText(term~>direction)
              spadmicCorridorNetName(term)
              spadmicCorridorText(fig~>objType)
              spadmicCorridorLayer(fig)
              spadmicCorridorPurpose(fig)
              spadmicCorridorBox(fig~>bBox)
              spadmicCorridorBox(transformed))
            emitted = t
            count = count + 1
          )
        )
        unless(emitted
          fprintf(fp "%s\t%s\t%s\t%s\tABSENT\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tNO_PIN_FIGURE\n"
            spadmicCorridorText(inst~>name)
            spadmicCorridorText(termName)
            spadmicCorridorText(term~>direction)
            spadmicCorridorNetName(term))
        )
      )
    )
    close(fp)
    count
  )
)

procedure(spadmicCorridorWriteHierarchy(path cv queryBox)
  let((fp overlaps overlap leaf transform transformed depth index
       shapeCount transformFailureCount pathText)
    fp = outfile(path "w")
    fprintf(fp "query_index\thierarchy_depth\ttop_instance\thierarchy_path\tshape_type\tnet\tlayer\tpurpose\ttransform_status\tmaster_llx\tmaster_lly\tmaster_urx\tmaster_ury\tllx\tlly\turx\tury\n")
    overlaps = dbGetTrueOverlaps(cv queryBox t 0:32 t)
    index = 0
    shapeCount = 0
    transformFailureCount = 0
    foreach(overlap overlaps
      index = index + 1
      leaf = spadmicCorridorLeaf(overlap)
      when(leaf && leaf~>bBox && leaf~>layerName
        depth = spadmicCorridorDepth(overlap)
        if(atom(overlap) then
          transform = nil
          transformed = leaf~>bBox
        else
          transform = dbGetHierPathTransform(overlap)
          transformed = if(transform then
            dbTransformBBox(leaf~>bBox transform)
          else
            nil)
        )
        unless(transformed
          transformFailureCount = transformFailureCount + 1
        )
        pathText = spadmicCorridorText(overlap)
        fprintf(fp "%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
          index
          depth
          spadmicCorridorTopInstance(overlap)
          pathText
          spadmicCorridorText(leaf~>objType)
          spadmicCorridorNetName(leaf)
          spadmicCorridorLayer(leaf)
          spadmicCorridorPurpose(leaf)
          if(atom(overlap) then
            "TOP_CELLVIEW_IDENTITY"
          else if(transform then
            "DB_GET_HIER_PATH_TRANSFORM"
          else
            "TRANSFORM_UNAVAILABLE"))
          spadmicCorridorBox(leaf~>bBox)
          spadmicCorridorBox(transformed))
        shapeCount = shapeCount + 1
      )
    )
    close(fp)
    list(length(overlaps) shapeCount transformFailureCount)
  )
)

procedure(spadmicCorridorProbeMain()
  let((outRoot libName cellName viewName sourcePath targetName cv target
       targetMaster expectedMaster queryBox pinCount hierarchyCounts statusFp
       windowLlx windowLly windowUrx windowUry)
    outRoot = getShellEnvVar("SPADMIC_CORRIDOR_PROBE_ROOT")
    libName = getShellEnvVar("SPADMIC_CORRIDOR_LIBRARY")
    cellName = getShellEnvVar("SPADMIC_CORRIDOR_CELL")
    viewName = getShellEnvVar("SPADMIC_CORRIDOR_VIEW")
    sourcePath = getShellEnvVar("SPADMIC_CORRIDOR_SOURCE_PATH")
    targetName = getShellEnvVar("SPADMIC_CORRIDOR_TARGET_INSTANCE")
    expectedMaster = getShellEnvVar("SPADMIC_CORRIDOR_TARGET_MASTER")
    when(viewName == nil || viewName == "" viewName = "layout")
    unless(outRoot && libName && cellName && sourcePath && targetName &&
           expectedMaster
      error("SPADMIC_CORRIDOR_PROBE_MISSING_ENV\n"))
    windowLlx = atof(getShellEnvVar("SPADMIC_CORRIDOR_WINDOW_LLX"))
    windowLly = atof(getShellEnvVar("SPADMIC_CORRIDOR_WINDOW_LLY"))
    windowUrx = atof(getShellEnvVar("SPADMIC_CORRIDOR_WINDOW_URX"))
    windowUry = atof(getShellEnvVar("SPADMIC_CORRIDOR_WINDOW_URY"))
    queryBox = list(windowLlx:windowLly windowUrx:windowUry)
    printf("SPADMIC_CORRIDOR_PROBE_PROGRESS=OPEN_SPADMIC2\n")
    cv = dbOpenCellViewByType(libName cellName viewName "" "r")
    unless(cv
      error("SPADMIC_CORRIDOR_PROBE_OPEN_FAILED %s/%s/%s\n"
        libName cellName viewName))
    target = spadmicCorridorFindTarget(cv targetName)
    unless(target
      error("SPADMIC_CORRIDOR_TARGET_INSTANCE_NOT_FOUND %s\n" targetName))
    targetMaster = target~>master
    unless(targetMaster &&
           targetMaster~>cellName == expectedMaster
      error("SPADMIC_CORRIDOR_TARGET_MASTER_MISMATCH %s\n"
        spadmicCorridorText(targetMaster~>cellName)))
    spadmicCorridorWriteIdentity(
      cv strcat(outRoot "/source_identity.tsv")
      libName cellName viewName sourcePath)
    spadmicCorridorWriteTargetInstance(
      strcat(outRoot "/target_instance.tsv") target)
    pinCount = spadmicCorridorWriteTargetPins(
      strcat(outRoot "/target_pg_pins.tsv") target)
    printf("SPADMIC_CORRIDOR_PROBE_PROGRESS=QUERY_HIERARCHY\n")
    hierarchyCounts = spadmicCorridorWriteHierarchy(
      strcat(outRoot "/corridor_hierarchical_shapes.tsv") cv queryBox)
    statusFp = outfile(
      strcat(outRoot "/corridor_query_status.rpt") "w")
    fprintf(statusFp "LABEL=SPADMIC2_SELECTED_I6_METTP_CORRIDOR_QUERY\n")
    fprintf(statusFp "STATUS=%s\n"
      if(caddr(hierarchyCounts) == 0 then "PASS" else "FAIL"))
    fprintf(statusFp "TARGET_INSTANCE=%s\n" targetName)
    fprintf(statusFp "TARGET_MASTER=%s/%s/%s\n"
      spadmicCorridorText(targetMaster~>libName)
      spadmicCorridorText(targetMaster~>cellName)
      spadmicCorridorText(targetMaster~>viewName))
    fprintf(statusFp "TARGET_ORIENT=%s\n"
      spadmicCorridorText(target~>orient))
    fprintf(statusFp "TARGET_PG_PIN_SHAPE_COUNT=%d\n" pinCount)
    fprintf(statusFp "QUERY_WINDOW_UM=%.6f %.6f %.6f %.6f\n"
      car(car(queryBox)) cadr(car(queryBox))
      car(cadr(queryBox)) cadr(cadr(queryBox)))
    fprintf(statusFp "DB_GET_TRUE_OVERLAPS_RESULT_COUNT=%d\n"
      car(hierarchyCounts))
    fprintf(statusFp "HIERARCHICAL_SHAPE_ROW_COUNT=%d\n"
      cadr(hierarchyCounts))
    fprintf(statusFp "HIERARCHICAL_TRANSFORM_FAILURE_COUNT=%d\n"
      caddr(hierarchyCounts))
    fprintf(statusFp "HIERARCHY_DEPTH=0:32\n")
    fprintf(statusFp "MOSAIC_ROW_COLUMN_ENUMERATION=YES\n")
    fprintf(statusFp "CORRIDOR_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION\n")
    close(statusFp)
    dbClose(cv)
    unless(caddr(hierarchyCounts) == 0
      error("SPADMIC_CORRIDOR_HIERARCHICAL_TRANSFORM_FAILURE\n"))
    printf("SPADMIC_CORRIDOR_PROBE_PROGRESS=COMPLETE\n")
    t
  )
)

let((outRoot runResult statusFp)
  outRoot = getShellEnvVar("SPADMIC_CORRIDOR_PROBE_ROOT")
  runResult = errset(spadmicCorridorProbeMain() t)
  when(outRoot
    statusFp = outfile(strcat(outRoot "/virtuoso_export_status.rpt") "w")
    when(statusFp
      fprintf(statusFp "LABEL=SPADMIC2_SELECTED_I6_METTP_CORRIDOR_VIRTUOSO_EXPORT\n")
      fprintf(statusFp "SOURCE_MUTATION_AUTHORIZED=NO\n")
      fprintf(statusFp "OA_EDIT_AUTHORIZED=NO\n")
      fprintf(statusFp "HIERARCHICAL_QUERY_POLICY=DB_GET_TRUE_OVERLAPS_DEPTH_0_32_WITH_ROW_COLUMN_ENUMERATION\n")
      fprintf(statusFp "HIERARCHICAL_TRANSFORM_POLICY=DB_GET_HIER_PATH_TRANSFORM\n")
      fprintf(statusFp "CORRIDOR_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION\n")
      if(runResult then
        fprintf(statusFp "STATUS=PASS\n")
      else
        fprintf(statusFp "STATUS=FAIL\n")
      )
      close(statusFp)
    )
  )
  if(runResult then
    printf("SPADMIC_CORRIDOR_PROBE_COMPLETION_STATUS=PASS\n")
  else
    printf("SPADMIC_CORRIDOR_PROBE_COMPLETION_STATUS=FAIL\n")
  )
  exit()
)
