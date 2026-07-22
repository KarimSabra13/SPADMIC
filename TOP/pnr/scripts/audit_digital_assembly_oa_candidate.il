; Read-only audit of the p03 OA candidate and SPADMIC2 target in one process.

procedure(spadmicOaCandidateWrite(cv path role)
  let((fp box ll ur term)
    fp = outfile(path "w")
    unless(fp error("SPADMIC_OA_CANDIDATE_REPORT_OPEN_FAILED %s\n" path))
    fprintf(fp "LABEL=SPADMIC_DIGITAL_ASSEMBLY_OA_READONLY_AUDIT\n")
    fprintf(fp "STATUS=PASS\n")
    fprintf(fp "ROLE=%s\n" role)
    fprintf(fp "LIBRARY=%s\nCELL=%s\nVIEW=%s\n"
      cv~>libName cv~>cellName cv~>viewName)
    box = cv~>bBox
    ll = car(box)
    ur = cadr(box)
    fprintf(fp "BBOX=%.6f %.6f %.6f %.6f\n"
      car(ll) cadr(ll) car(ur) cadr(ur))
    fprintf(fp "INSTANCE_COUNT=%d\n" length(cv~>instances))
    fprintf(fp "TERMINAL_COUNT=%d\n" length(cv~>terminals))
    foreach(term cv~>terminals
      fprintf(fp "PIN=%s|%s|%d\n"
        term~>name term~>direction length(term~>pins))
    )
    close(fp)
  )
)

procedure(spadmicAuditDigitalAssemblyCandidate()
  let((targetLib targetCell targetView sourceLib sourceCell sourceView
        targetReport sourceReport targetCv sourceCv)
    targetLib = getShellEnvVar("SPADMIC_OA_CANDIDATE_TARGET_LIBRARY")
    targetCell = getShellEnvVar("SPADMIC_OA_CANDIDATE_TARGET_CELL")
    targetView = getShellEnvVar("SPADMIC_OA_CANDIDATE_TARGET_VIEW")
    sourceLib = getShellEnvVar("SPADMIC_OA_CANDIDATE_SOURCE_LIBRARY")
    sourceCell = getShellEnvVar("SPADMIC_OA_CANDIDATE_SOURCE_CELL")
    sourceView = getShellEnvVar("SPADMIC_OA_CANDIDATE_SOURCE_VIEW")
    targetReport = getShellEnvVar("SPADMIC_OA_CANDIDATE_TARGET_REPORT")
    sourceReport = getShellEnvVar("SPADMIC_OA_CANDIDATE_SOURCE_REPORT")
    when(targetView == nil || targetView == "" targetView = "layout")
    when(sourceView == nil || sourceView == "" sourceView = "layout")
    unless(targetLib && targetCell && sourceLib && sourceCell && targetReport && sourceReport
      error("SPADMIC_OA_CANDIDATE_MISSING_ENV\n"))
    targetCv = dbOpenCellViewByType(targetLib targetCell targetView "" "r")
    unless(targetCv
      error("SPADMIC_OA_CANDIDATE_TARGET_OPEN_FAILED %s/%s/%s\n"
        targetLib targetCell targetView))
    sourceCv = dbOpenCellViewByType(sourceLib sourceCell sourceView "" "r")
    unless(sourceCv
      dbClose(targetCv)
      error("SPADMIC_OA_CANDIDATE_SOURCE_OPEN_FAILED %s/%s/%s\n"
        sourceLib sourceCell sourceView))
    spadmicOaCandidateWrite(targetCv targetReport "TARGET")
    spadmicOaCandidateWrite(sourceCv sourceReport "CANDIDATE")
    dbClose(sourceCv)
    dbClose(targetCv)
    t
  )
)

spadmicAuditDigitalAssemblyCandidate()
exit()
