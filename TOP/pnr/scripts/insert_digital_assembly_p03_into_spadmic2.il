; Insert one reviewed p03 assembly OA cell into SPADMIC2 after backup.
; The caller must verify the external authorization manifest before Virtuoso.

procedure(spadmicOaText(value)
  if(value then
    let((text)
      text = if(stringp(value) then value else sprintf(nil "%L" value))
      rexReplace(text "[\t\n\r]" " " 0)
    )
  else
    "ABSENT"
  )
)

procedure(spadmicAssemblyCellAllowed(cellName)
  member(cellName list(
    "spadmic_digital_assembly_v1_p00_tx"
    "spadmic_digital_assembly_v1_p01_position"
    "spadmic_digital_assembly_v1_p02_event_control"
    "spadmic_digital_assembly_v1_p03_matrix_interface"))
)

procedure(spadmicInsertAssemblyP03()
  let((targetLib targetCell targetView sourceLib sourceCell sourceView
        reportPath authorization instanceName cv master conflicts assemblyInsts
        oldCount removedCount newInst finalAssembly finalExact fp)
    targetLib = getShellEnvVar("SPADMIC_OA_INSERT_TARGET_LIBRARY")
    targetCell = getShellEnvVar("SPADMIC_OA_INSERT_TARGET_CELL")
    targetView = getShellEnvVar("SPADMIC_OA_INSERT_TARGET_VIEW")
    sourceLib = getShellEnvVar("SPADMIC_OA_INSERT_SOURCE_LIBRARY")
    sourceCell = getShellEnvVar("SPADMIC_OA_INSERT_SOURCE_CELL")
    sourceView = getShellEnvVar("SPADMIC_OA_INSERT_SOURCE_VIEW")
    reportPath = getShellEnvVar("SPADMIC_OA_INSERT_REPORT")
    authorization = getShellEnvVar("SPADMIC_OA_INSERT_AUTHORIZATION")
    instanceName = getShellEnvVar("SPADMIC_OA_INSERT_INSTANCE_NAME")
    when(targetView == nil || targetView == "" targetView = "layout")
    when(sourceView == nil || sourceView == "" sourceView = "layout")
    when(instanceName == nil || instanceName == "" instanceName = "I_digital_assembly_p03")
    unless(authorization == "EXACT_P03_BACKUP_REVIEWED"
      error("SPADMIC_OA_INSERT_AUTHORIZATION_REJECTED\n"))
    unless(targetLib && targetCell && sourceLib && sourceCell && reportPath
      error("SPADMIC_OA_INSERT_MISSING_ENV\n"))
    unless(sourceCell == "spadmic_digital_assembly_v1_p03_matrix_interface"
      error("SPADMIC_OA_INSERT_SOURCE_CELL_REJECTED %s\n" sourceCell))

    master = dbOpenCellViewByType(sourceLib sourceCell sourceView "" "r")
    unless(master
      error("SPADMIC_OA_INSERT_SOURCE_OPEN_FAILED %s/%s/%s\n"
        sourceLib sourceCell sourceView))
    cv = dbOpenCellViewByType(targetLib targetCell targetView "" "a")
    unless(cv
      dbClose(master)
      error("SPADMIC_OA_INSERT_TARGET_OPEN_FAILED %s/%s/%s\n"
        targetLib targetCell targetView))

    conflicts = setof(inst cv~>instances inst~>name == instanceName)
    foreach(inst conflicts
      unless(inst~>master &&
             inst~>master~>libName == sourceLib &&
             spadmicAssemblyCellAllowed(inst~>master~>cellName)
        dbClose(cv)
        dbClose(master)
        error("SPADMIC_OA_INSERT_NAME_COLLISION %s\n" instanceName))
    )

    assemblyInsts = setof(inst cv~>instances
      inst~>master &&
      inst~>master~>libName == sourceLib &&
      spadmicAssemblyCellAllowed(inst~>master~>cellName))
    oldCount = length(assemblyInsts)
    when(oldCount > 1
      dbClose(cv)
      dbClose(master)
      error("SPADMIC_OA_INSERT_MULTIPLE_EXISTING_ASSEMBLIES %d\n" oldCount))
    removedCount = 0
    foreach(inst assemblyInsts
      dbDeleteObject(inst)
      removedCount = removedCount + 1
    )

    newInst = dbCreateInst(cv master instanceName list(0.0 0.0) "R0")
    unless(newInst
      dbClose(cv)
      dbClose(master)
      error("SPADMIC_OA_INSERT_CREATE_FAILED\n"))
    unless(dbSave(cv)
      dbClose(cv)
      dbClose(master)
      error("SPADMIC_OA_INSERT_SAVE_FAILED\n"))

    finalAssembly = setof(inst cv~>instances
      inst~>master &&
      inst~>master~>libName == sourceLib &&
      spadmicAssemblyCellAllowed(inst~>master~>cellName))
    finalExact = setof(inst finalAssembly
      inst~>master~>cellName == sourceCell &&
      inst~>name == instanceName &&
      inst~>orient == "R0")
    unless(length(finalAssembly) == 1 && length(finalExact) == 1
      dbClose(cv)
      dbClose(master)
      error("SPADMIC_OA_INSERT_POSTCHECK_FAILED assemblies=%d exact=%d\n"
        length(finalAssembly) length(finalExact)))

    fp = outfile(reportPath "w")
    unless(fp
      dbClose(cv)
      dbClose(master)
      error("SPADMIC_OA_INSERT_REPORT_OPEN_FAILED %s\n" reportPath))
    fprintf(fp "LABEL=SPADMIC_DIGITAL_ASSEMBLY_P03_OA_INSERTION\n")
    fprintf(fp "STATUS=PASS\n")
    fprintf(fp "RESULT=EXACT_P03_INSTANCE_INSERTED\n")
    fprintf(fp "TARGET=%s/%s/%s\n" targetLib targetCell targetView)
    fprintf(fp "SOURCE=%s/%s/%s\n" sourceLib sourceCell sourceView)
    fprintf(fp "INSTANCE=%s\n" instanceName)
    fprintf(fp "ORIGIN_UM=0.000000 0.000000\n")
    fprintf(fp "ORIENT=R0\n")
    fprintf(fp "PREEXISTING_ALLOWLISTED_ASSEMBLY_COUNT=%d\n" oldCount)
    fprintf(fp "REMOVED_ALLOWLISTED_ASSEMBLY_COUNT=%d\n" removedCount)
    fprintf(fp "NONALLOWLIST_INSTANCE_REMOVAL_COUNT=0\n")
    fprintf(fp "CREATED_INSTANCE_COUNT=1\n")
    fprintf(fp "FINAL_ALLOWLISTED_ASSEMBLY_COUNT=%d\n" length(finalAssembly))
    fprintf(fp "FINAL_EXACT_P03_INSTANCE_COUNT=%d\n" length(finalExact))
    fprintf(fp "FULL_TOP_GDS_EXPORT_STATUS=NOT_RUN\n")
    fprintf(fp "FULL_TOP_PVS_BASE_DRC_STATUS=NOT_RUN\n")
    fprintf(fp "FULL_TOP_PVS_DENSITY_DRC_STATUS=NOT_RUN\n")
    fprintf(fp "FULL_TOP_PVS_LVS_STATUS=NOT_RUN\n")
    fprintf(fp "SIGNOFF_READY=NO\n")
    close(fp)
    dbClose(cv)
    dbClose(master)
    t
  )
)

spadmicInsertAssemblyP03()
exit()
