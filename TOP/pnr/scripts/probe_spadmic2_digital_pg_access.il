; Read-only SPADMIC2 DVDD/DVSS physical-access probe.
; The source cellView is opened with mode "r"; no OA write API is used.

procedure(spadmicPgText(value)
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

procedure(spadmicPgBox(box)
  if(box then
    sprintf(nil "%.6f\t%.6f\t%.6f\t%.6f"
      car(car(box)) cadr(car(box)) car(cadr(box)) cadr(cadr(box)))
  else
    "UNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN"
  )
)

procedure(spadmicPgLayer(fig)
  if(fig && fig~>layerName then spadmicPgText(fig~>layerName) else "UNKNOWN")
)

procedure(spadmicPgPurpose(fig)
  if(fig && fig~>purpose then spadmicPgText(fig~>purpose) else "UNKNOWN")
)

procedure(spadmicPgNetName(object)
  if(object && object~>net && object~>net~>name then
    spadmicPgText(object~>net~>name)
  else
    "ABSENT"
  )
)

procedure(spadmicPgMatchesSupply(value)
  let((localVdd localVss chipVdd chipVss)
    localVdd = getShellEnvVar("SPADMIC_PG_LOCAL_VDD")
    localVss = getShellEnvVar("SPADMIC_PG_LOCAL_VSS")
    chipVdd = getShellEnvVar("SPADMIC_PG_CHIP_VDD")
    chipVss = getShellEnvVar("SPADMIC_PG_CHIP_VSS")
    value &&
      (value == localVdd ||
       value == localVss ||
       value == chipVdd ||
       value == chipVss)
  )
)

procedure(spadmicPgWriteIdentity(cv path libName cellName viewName sourcePath)
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

procedure(spadmicPgWriteSupplyNets(cv path)
  let((fp net)
    fp = outfile(path "w")
    fprintf(fp "net\ttop_terminal_count\tinstance_terminal_count\n")
    foreach(net cv~>nets
      when(spadmicPgMatchesSupply(net~>name)
        fprintf(fp "%s\t%d\t%d\n"
          spadmicPgText(net~>name)
          length(net~>terminals)
          length(net~>instTerms))
      )
    )
    close(fp)
  )
)

procedure(spadmicPgWriteSupplyTopTerminals(cv path)
  let((fp term termName netName pin fig emitted)
    fp = outfile(path "w")
    fprintf(fp "terminal\tdirection\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(term cv~>terminals
      termName = term~>name
      netName = if(term~>net then term~>net~>name else nil)
      when(spadmicPgMatchesSupply(termName) ||
           spadmicPgMatchesSupply(netName)
        emitted = nil
        foreach(pin term~>pins
          foreach(fig pin~>figs
            fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\n"
              spadmicPgText(termName)
              spadmicPgText(term~>direction)
              spadmicPgNetName(term)
              spadmicPgLayer(fig)
              spadmicPgPurpose(fig)
              spadmicPgBox(fig~>bBox))
            emitted = t
          )
        )
        unless(emitted
          fprintf(fp "%s\t%s\t%s\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\n"
            spadmicPgText(termName)
            spadmicPgText(term~>direction)
            spadmicPgNetName(term))
        )
      )
    )
    close(fp)
  )
)

procedure(spadmicPgWriteSupplyTopShapes(cv path)
  let((fp shape netName)
    fp = outfile(path "w")
    fprintf(fp "shape_type\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(shape cv~>shapes
      netName = if(shape~>net then shape~>net~>name else nil)
      when(spadmicPgMatchesSupply(netName)
        fprintf(fp "%s\t%s\t%s\t%s\t%s\n"
          spadmicPgText(shape~>objType)
          spadmicPgNetName(shape)
          spadmicPgLayer(shape)
          spadmicPgPurpose(shape)
          spadmicPgBox(shape~>bBox))
      )
    )
    close(fp)
  )
)

procedure(spadmicPgConnectedNetName(inst termName)
  let((netName instTerm)
    netName = nil
    foreach(instTerm inst~>instTerms
      when(instTerm~>term &&
           instTerm~>term~>name == termName &&
           instTerm~>net &&
           instTerm~>net~>name
        netName = instTerm~>net~>name
      )
    )
    netName
  )
)

procedure(spadmicPgWriteSupplyInstancePins(cv path)
  let((fp inst master term termName netName pin fig transformed emitted)
    fp = outfile(path "w")
    fprintf(fp "instance\tmaster_library\tmaster_cell\tmaster_view\torient\tterminal\tdirection\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(inst cv~>instances
      master = inst~>master
      when(master
        foreach(term master~>terminals
          termName = term~>name
          netName = spadmicPgConnectedNetName(inst termName)
          when(spadmicPgMatchesSupply(termName) ||
               spadmicPgMatchesSupply(netName)
            emitted = nil
            foreach(pin term~>pins
              foreach(fig pin~>figs
                transformed = dbTransformBBox(fig~>bBox inst~>transform)
                fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
                  spadmicPgText(inst~>name)
                  spadmicPgText(master~>libName)
                  spadmicPgText(master~>cellName)
                  spadmicPgText(master~>viewName)
                  spadmicPgText(inst~>orient)
                  spadmicPgText(termName)
                  spadmicPgText(term~>direction)
                  spadmicPgText(netName)
                  spadmicPgLayer(fig)
                  spadmicPgPurpose(fig)
                  spadmicPgBox(transformed))
                emitted = t
              )
            )
            unless(emitted
              fprintf(fp "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tABSENT\tABSENT\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\n"
                spadmicPgText(inst~>name)
                spadmicPgText(master~>libName)
                spadmicPgText(master~>cellName)
                spadmicPgText(master~>viewName)
                spadmicPgText(inst~>orient)
                spadmicPgText(termName)
                spadmicPgText(term~>direction)
                spadmicPgText(netName))
            )
          )
        )
      )
    )
    close(fp)
  )
)

procedure(spadmicPgWriteDirectMettpShapes(cv path)
  let((fp shape)
    fp = outfile(path "w")
    fprintf(fp "shape_type\tnet\tlayer\tpurpose\tllx\tlly\turx\tury\n")
    foreach(shape cv~>shapes
      when(shape~>layerName == "METTP"
        fprintf(fp "%s\t%s\t%s\t%s\t%s\n"
          spadmicPgText(shape~>objType)
          spadmicPgNetName(shape)
          spadmicPgLayer(shape)
          spadmicPgPurpose(shape)
          spadmicPgBox(shape~>bBox))
      )
    )
    close(fp)
  )
)

procedure(spadmicPgProbeMain()
  let((outRoot libName cellName viewName sourcePath cv)
    outRoot = getShellEnvVar("SPADMIC_PG_PROBE_ROOT")
    libName = getShellEnvVar("SPADMIC_PG_PROBE_LIBRARY")
    cellName = getShellEnvVar("SPADMIC_PG_PROBE_CELL")
    viewName = getShellEnvVar("SPADMIC_PG_PROBE_VIEW")
    sourcePath = getShellEnvVar("SPADMIC_PG_SOURCE_PATH")
    when(viewName == nil || viewName == "" viewName = "layout")
    unless(outRoot && libName && cellName && sourcePath
      error("SPADMIC_PG_PROBE_MISSING_ENV\n"))
    printf("SPADMIC_PG_PROBE_PROGRESS=OPEN_SPADMIC2\n")
    cv = dbOpenCellViewByType(libName cellName viewName "" "r")
    unless(cv
      error("SPADMIC_PG_PROBE_OPEN_FAILED %s/%s/%s\n"
        libName cellName viewName))
    spadmicPgWriteIdentity(
      cv strcat(outRoot "/source_identity.tsv")
      libName cellName viewName sourcePath)
    printf("SPADMIC_PG_PROBE_PROGRESS=WRITE_SUPPLY_EVIDENCE\n")
    spadmicPgWriteSupplyNets(cv strcat(outRoot "/supply_nets.tsv"))
    spadmicPgWriteSupplyTopTerminals(
      cv strcat(outRoot "/supply_top_terminals.tsv"))
    spadmicPgWriteSupplyTopShapes(
      cv strcat(outRoot "/supply_top_shapes.tsv"))
    spadmicPgWriteSupplyInstancePins(
      cv strcat(outRoot "/supply_instance_pins.tsv"))
    spadmicPgWriteDirectMettpShapes(
      cv strcat(outRoot "/direct_mettp_shapes.tsv"))
    dbClose(cv)
    printf("SPADMIC_PG_PROBE_PROGRESS=COMPLETE\n")
    t
  )
)

let((outRoot runResult statusFp)
  outRoot = getShellEnvVar("SPADMIC_PG_PROBE_ROOT")
  runResult = errset(spadmicPgProbeMain() t)
  when(outRoot
    statusFp = outfile(strcat(outRoot "/virtuoso_export_status.rpt") "w")
    when(statusFp
      fprintf(statusFp "LABEL=SPADMIC2_DIGITAL_PG_ACCESS_VIRTUOSO_EXPORT\n")
      fprintf(statusFp "SOURCE_MUTATION_AUTHORIZED=NO\n")
      fprintf(statusFp "OA_EDIT_AUTHORIZED=NO\n")
      fprintf(statusFp "INSTANCE_TERMINAL_ENUMERATION_POLICY=MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY\n")
      if(runResult then
        fprintf(statusFp "STATUS=PASS\n")
      else
        fprintf(statusFp "STATUS=FAIL\n")
      )
      close(statusFp)
    )
  )
  if(runResult then
    printf("SPADMIC_PG_PROBE_COMPLETION_STATUS=PASS\n")
  else
    printf("SPADMIC_PG_PROBE_COMPLETION_STATUS=FAIL\n")
  )
  exit()
)
