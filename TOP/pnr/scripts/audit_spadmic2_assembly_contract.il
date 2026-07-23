; Read-only SPADMIC2/matrice5 extraction for digital-assembly planning.
; Every database is opened with mode "r" and no OA save API is used.

procedure(spadmicAuditText(value)
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

procedure(spadmicAuditBox(box)
  if(box then
    sprintf(nil "%.6f\t%.6f\t%.6f\t%.6f"
      car(car(box)) cadr(car(box)) car(cadr(box)) cadr(cadr(box)))
  else
    "UNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN"
  )
)

procedure(spadmicAuditLayer(fig)
  if(fig && fig~>layerName then spadmicAuditText(fig~>layerName) else "UNKNOWN")
)

procedure(spadmicAuditPurpose(fig)
  if(fig && fig~>purpose then spadmicAuditText(fig~>purpose) else "UNKNOWN")
)

procedure(spadmicAuditNetName(object)
  if(object && object~>net && object~>net~>name then
    spadmicAuditText(object~>net~>name)
  else
    "ABSENT"
  )
)

procedure(spadmicAuditWriteIdentity(fp role libName cellName viewName path cv)
  fprintf(fp "%s\t%s\t%s\t%s\t%s\tPASS\t%s\n"
    role libName cellName viewName path
    if(cv~>bBox then
      sprintf(nil "%.6f %.6f %.6f %.6f"
        car(car(cv~>bBox)) cadr(car(cv~>bBox))
        car(cadr(cv~>bBox)) cadr(cadr(cv~>bBox)))
    else "UNKNOWN"))
)

procedure(spadmicAuditWriteInstances(cv path)
  let((fp inst master box)
    fp = outfile(path "w")
    fprintf(fp "instance\tmaster_library\tmaster_cell\tmaster_view\torient\tllx\tlly\turx\tury\n")
    foreach(inst cv~>instances
      master = inst~>master
      box = inst~>bBox
      fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\n"
        spadmicAuditText(inst~>name)
        if(master then spadmicAuditText(master~>libName) else "ABSENT")
        if(master then spadmicAuditText(master~>cellName) else "ABSENT")
        if(master then spadmicAuditText(master~>viewName) else "ABSENT")
        spadmicAuditText(inst~>orient)
        spadmicAuditBox(box))
    )
    close(fp)
  )
)

procedure(spadmicAuditWriteInstancePins(cv path targetLib targetCell targetView)
  let((fp inst master instTerm term pin fig transformed emitted)
    fp = outfile(path "w")
    fprintf(fp "instance\tterminal\tdirection\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(inst cv~>instances
      master = inst~>master
      when(master &&
           master~>libName == targetLib &&
           master~>cellName == targetCell &&
           master~>viewName == targetView
        foreach(instTerm inst~>instTerms
          term = instTerm~>term
          emitted = nil
          when(term
            foreach(pin term~>pins
              foreach(fig pin~>figs
                transformed = dbTransformBBox(fig~>bBox inst~>transform)
                fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
                  spadmicAuditText(inst~>name)
                  spadmicAuditText(term~>name)
                  spadmicAuditText(term~>direction)
                  spadmicAuditNetName(instTerm)
                  spadmicAuditLayer(fig)
                  spadmicAuditPurpose(fig)
                  spadmicAuditBox(transformed))
                emitted = t
              )
            )
          )
          unless(emitted
            fprintf(fp "%s\t%s\t%s\t%s\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\n"
              spadmicAuditText(inst~>name)
              if(term then spadmicAuditText(term~>name) else "ABSENT")
              if(term then spadmicAuditText(term~>direction) else "ABSENT")
              spadmicAuditNetName(instTerm))
          )
        )
      )
    )
    close(fp)
  )
)

procedure(spadmicAuditWriteTopTerminals(cv path)
  let((fp term pin fig emitted)
    fp = outfile(path "w")
    fprintf(fp "terminal\tdirection\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(term cv~>terminals
      emitted = nil
      foreach(pin term~>pins
        foreach(fig pin~>figs
          fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\n"
            spadmicAuditText(term~>name)
            spadmicAuditText(term~>direction)
            spadmicAuditNetName(term)
            spadmicAuditLayer(fig)
            spadmicAuditPurpose(fig)
            spadmicAuditBox(fig~>bBox))
          emitted = t
        )
      )
      unless(emitted
        fprintf(fp "%s\t%s\t%s\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\n"
          spadmicAuditText(term~>name)
          spadmicAuditText(term~>direction)
          spadmicAuditNetName(term))
      )
    )
    close(fp)
  )
)

procedure(spadmicAuditWriteTopShapes(cv path)
  let((fp shape)
    fp = outfile(path "w")
    fprintf(fp "shape_type\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(shape cv~>shapes
      fprintf(fp "%s\t%s\t%s\t%s\t%s\n"
        spadmicAuditText(shape~>objType)
        spadmicAuditNetName(shape)
        spadmicAuditLayer(shape)
        spadmicAuditPurpose(shape)
        spadmicAuditBox(shape~>bBox))
    )
    close(fp)
  )
)

procedure(spadmicAuditWriteNets(cv path)
  let((fp net)
    fp = outfile(path "w")
    fprintf(fp "net\ttop_terminal_count\tinstance_terminal_count\n")
    foreach(net cv~>nets
      fprintf(fp "%s\t%d\t%d\n"
        spadmicAuditText(net~>name)
        length(net~>terminals)
        length(net~>instTerms))
    )
    close(fp)
  )
)

procedure(spadmicAuditOne(role libName cellName viewName filesystemPath outRoot identityFp)
  let((cv prefix)
    printf("SPADMIC_OA_AUDIT_PROGRESS=OPEN_%s\n" role)
    cv = dbOpenCellViewByType(libName cellName viewName "" "r")
    unless(cv
      fprintf(identityFp "%s\t%s\t%s\t%s\t%s\tFAIL\tUNKNOWN\n"
        role libName cellName viewName filesystemPath)
      error("SPADMIC_ASSEMBLY_OA_OPEN_FAILED %s/%s/%s\n" libName cellName viewName)
    )
    spadmicAuditWriteIdentity(identityFp role libName cellName viewName filesystemPath cv)
    prefix = strcat(outRoot "/" role)
    if(role == "spadmic2" then
      printf("SPADMIC_OA_AUDIT_PROGRESS=WRITE_SPADMIC2_TOP_CONTRACT\n")
      spadmicAuditWriteInstances(cv strcat(prefix "_instances.tsv"))
      spadmicAuditWriteInstancePins(
        cv strcat(prefix "_instance_pins.tsv")
        getShellEnvVar("SPADMIC_OA_MATRIX_LIBRARY")
        getShellEnvVar("SPADMIC_OA_MATRIX_CELL")
        getShellEnvVar("SPADMIC_OA_MATRIX_VIEW"))
      spadmicAuditWriteTopShapes(cv strcat(prefix "_top_shapes.tsv"))
    else
      unless(role == "matrice5"
        dbClose(cv)
        error("SPADMIC_ASSEMBLY_OA_UNKNOWN_AUDIT_ROLE %s\n" role))
      printf("SPADMIC_OA_AUDIT_PROGRESS=WRITE_MATRICE5_TOP_TERMINALS\n")
      spadmicAuditWriteTopTerminals(cv strcat(prefix "_top_terminals.tsv"))
    )
    dbClose(cv)
    printf("SPADMIC_OA_AUDIT_PROGRESS=COMPLETE_%s\n" role)
  )
)

procedure(spadmicAuditAssemblyMain()
  let((outRoot role identityPath identityFp topView matrixView)
    outRoot = getShellEnvVar("SPADMIC_OA_ASSEMBLY_AUDIT_ROOT")
    unless(outRoot error("SPADMIC_OA_ASSEMBLY_AUDIT_ROOT is required\n"))
    role = getShellEnvVar("SPADMIC_OA_AUDIT_ROLE")
    unless(role == "spadmic2" || role == "matrice5"
      error("SPADMIC_OA_AUDIT_ROLE must be spadmic2 or matrice5\n"))
    topView = getShellEnvVar("SPADMIC_OA_TOP_VIEW")
    matrixView = getShellEnvVar("SPADMIC_OA_MATRIX_VIEW")
    when(topView == nil || topView == "" topView = "layout")
    when(matrixView == nil || matrixView == "" matrixView = "layout")
    identityPath = strcat(outRoot "/" role "_source_identity.tsv")
    identityFp = outfile(identityPath "w")
    fprintf(identityFp "role\tlibrary\tcell\tview\tfilesystem_path\topen_status\tbbox\n")
    if(role == "spadmic2" then
      spadmicAuditOne(
        role
        getShellEnvVar("SPADMIC_OA_TOP_LIBRARY")
        getShellEnvVar("SPADMIC_OA_TOP_CELL")
        topView
        getShellEnvVar("SPADMIC_OA_TOP_PATH")
        outRoot identityFp)
    else
      spadmicAuditOne(
        role
        getShellEnvVar("SPADMIC_OA_MATRIX_LIBRARY")
        getShellEnvVar("SPADMIC_OA_MATRIX_CELL")
        matrixView
        getShellEnvVar("SPADMIC_OA_MATRIX_PATH")
        outRoot identityFp)
    )
    close(identityFp)
    t
  )
)

let((outRoot role runResult statusPath statusFp)
  outRoot = getShellEnvVar("SPADMIC_OA_ASSEMBLY_AUDIT_ROOT")
  role = getShellEnvVar("SPADMIC_OA_AUDIT_ROLE")
  runResult = errset(spadmicAuditAssemblyMain() t)
  when(outRoot && role
    statusPath = strcat(outRoot "/" role "_virtuoso_export_status.rpt")
    statusFp = outfile(statusPath "w")
    when(statusFp
      fprintf(statusFp "LABEL=SPADMIC_OA_ROLE_VIRTUOSO_EXPORT\n")
      fprintf(statusFp "ROLE=%s\n" role)
      if(runResult then
        fprintf(statusFp "STATUS=PASS\n")
      else
        fprintf(statusFp "STATUS=FAIL\n")
      )
      close(statusFp)
    )
  )
  if(runResult then
    printf("SPADMIC_OA_AUDIT_COMPLETION_STATUS=PASS\n")
  else
    printf("SPADMIC_OA_AUDIT_COMPLETION_STATUS=FAIL\n")
  )
  exit()
)
