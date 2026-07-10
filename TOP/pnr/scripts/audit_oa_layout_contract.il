; Read-only OA layout audit. All inputs and the report path come from env.

procedure(spadmicAuditOALayout()
  let((libName cellName viewName reportPath cv fp box ll ur terms term pins)
    libName = getShellEnvVar("SPADMIC_OA_AUDIT_LIBRARY")
    cellName = getShellEnvVar("SPADMIC_OA_AUDIT_CELL")
    viewName = getShellEnvVar("SPADMIC_OA_AUDIT_VIEW")
    reportPath = getShellEnvVar("SPADMIC_OA_AUDIT_REPORT")
    when(viewName == nil || viewName == "" viewName = "layout")
    unless(libName && cellName && reportPath
      error("SPADMIC_OA_AUDIT_MISSING_ENV\n")
    )
    cv = dbOpenCellViewByType(libName cellName viewName "" "r")
    unless(cv error("SPADMIC_OA_AUDIT_OPEN_FAILED %s/%s/%s\n" libName cellName viewName))
    fp = outfile(reportPath "w")
    unless(fp error("SPADMIC_OA_AUDIT_REPORT_OPEN_FAILED %s\n" reportPath))
    fprintf(fp "LABEL=SPADMIC_OA_LAYOUT_CONTRACT\n")
    fprintf(fp "STATUS=PASS\n")
    fprintf(fp "LIBRARY=%s\nCELL=%s\nVIEW=%s\n" libName cellName viewName)
    box = cv~>bBox
    ll = car(box)
    ur = cadr(box)
    fprintf(fp "BBOX=%.6f %.6f %.6f %.6f\n" car(ll) cadr(ll) car(ur) cadr(ur))
    terms = cv~>terminals
    fprintf(fp "TERMINAL_COUNT=%d\n" length(terms))
    foreach(term terms
      pins = term~>pins
      fprintf(fp "PIN=%s|%s|%d\n" term~>name term~>direction length(pins))
    )
    close(fp)
    dbClose(cv)
    t
  )
)

spadmicAuditOALayout()
exit()
