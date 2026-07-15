#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = (
    REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_min_area_geometry_probe.py"
)
HEAD = "geometry-driver-head"
NETS = ("n_9677", "n_9693", "n_9696", "n_9697", "n_9706", "n_9721")
MARKER_HEADER = (
    "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
    "layer\ttype\tsubType\tmessage"
)


class AnalyzeTxPacketMinAreaGeometryProbeTest(unittest.TestCase):
    def write_verify(self, path: Path, count: int) -> None:
        path.write_text(f"Verification Complete : {count} Viols.  0 Wrngs.\n")

    def marker_rows(self, *, shifted_post: bool = False) -> list[str]:
        rows: list[str] = []
        for index, net in enumerate(NETS, start=1):
            llx = 100.0 + index + (0.01 if shifted_post and index == 1 else 0.0)
            lly = 200.0 + index
            urx = llx + 0.38
            ury = lly + 0.28
            message = (
                f"Regular Wire of Net {net} Actual: 0.10640000 "
                "Required: 0.20200000 Type: Minimum Area"
            )
            rows.append(
                f"{index}\th{index}\t{{{llx:.2f} {lly:.2f} {urx:.2f} {ury:.2f}}}\t"
                f"{llx:.2f}\t{lly:.2f}\t{urx:.2f}\t{ury:.2f}\t"
                f"{(llx + urx) / 2:.6f}\t{(lly + ury) / 2:.6f}\t"
                f"MET1\tGeometry\tMinimal_Area\t{message}"
            )
        return rows

    def write_fixture(self, root: Path, *, shifted_post: bool = False) -> tuple[Path, Path]:
        probe_root = root / "probe"
        reports = probe_root / "reports"
        reports.mkdir(parents=True)
        step19 = root / "step19.rpt"
        step19.write_text(
            "STATUS=PASS\n"
            "RESULT=ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED\n"
            "TRIAL_REVISION=R2\n"
            "TRIAL_PROCESS_STATUS=FAIL\n"
            "TRIAL_PROCESS_RESULT=ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT\n"
            "METHOD_STATUS=REJECTED_OR_INCOMPLETE\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "FINAL_DRC_VIOLATION_COUNT=6\n"
            "DRC_COUNT_SEQUENCE=6 6\n"
            "ITERATION_COUNT=1\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "FINAL_MARKER_DATABASE_TOTAL=27\n"
            "COMMAND_PASS_COUNT=22\n"
            "COMMAND_FAIL_COUNT=0\n"
            f"PRE_MIN_AREA_NETS={' '.join(NETS)}\n"
            f"FINAL_MIN_AREA_NETS={' '.join(NETS)}\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
            "ERROR_COUNT=0\n"
        )
        (probe_root / "context.rpt").write_text(
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"STEP19_ANALYSIS={step19}\n"
            f"HEAD={HEAD}\n"
            "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_READ_ONLY_LOCAL_GEOMETRY_PROBE\n"
            "DESIGN_MODIFICATION=NOT_RUN\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
        )

        for name in (
            "pre_probe",
            "post_probe",
        ):
            self.write_verify(reports / f"verify_drc_{name}.rpt", 6)
            self.write_verify(reports / f"verify_connectivity_regular_{name}.rpt", 0)
            self.write_verify(reports / f"verify_connectivity_special_{name}.rpt", 0)
        (reports / "drc_markers_pre_probe.tsv").write_text(
            MARKER_HEADER + "\n" + "\n".join(self.marker_rows()) + "\n"
        )
        (reports / "drc_markers_post_probe.tsv").write_text(
            MARKER_HEADER
            + "\n"
            + "\n".join(self.marker_rows(shifted_post=shifted_post))
            + "\n"
        )

        marker_geometry = [
            "net\tmarker_handle\tmarker_box\tllx\tlly\turx\tury\t"
            "actual_area_um2\trequired_area_um2\tadditional_area_um2\tmessage"
        ]
        topology = [
            "net\tmarker_box\tnet_handle_status\tnet_handle\twire_query_status\t"
            "wire_count\tlocal_wire_count\tvia_query_status\tvia_count\t"
            "local_via_count\tinst_term_query_status\tinst_term_count\t"
            "top_term_query_status\ttop_term_count\tpin_shape_row_count"
        ]
        local_wires = [
            "net\tmarker_box\twire_index\twire_handle\tlocal_relation\tbox_status\t"
            "box\tlayer_status\tlayer\tstatus_status\tstatus\tshape_status\tshape\t"
            "width_status\twidth\tlength_status\tlength\tpts_status\tpts"
        ]
        local_vias = [
            "net\tmarker_box\tvia_index\tvia_handle\tlocal_relation\tbox_status\t"
            "box\tname_status\tname\tcut_layer_status\tcut_layer\t"
            "bottom_layer_status\tbottom_layer\ttop_layer_status\ttop_layer\t"
            "point_status\tpoint\tstatus_status\tstatus\torient_status\torient"
        ]
        inst_terms = [
            "net\tinst_term_handle\tname_status\tname\tinst_status\tinst\t"
            "cell_status\tcell\tterm_status\tterm\tdirection_status\tdirection\t"
            "inst_box_status\tinst_box\tinst_pt_status\tinst_pt\torient_status\t"
            "orient\tpoint_status\tpoint\tavg_point_status\tavg_point"
        ]
        pin_shapes = [
            "net\tinst_term_handle\tinst\tcell\tterm\tpin_shape_handle\t"
            "layer_status\tlayer\trect_status\trect\ttype_status\ttype\t"
            "name_status\tname\tcoordinate_space"
        ]
        top_terms = [
            "net\ttop_term_handle\tname_status\tname\tdirection_status\t"
            "direction\tpoint_status\tpoint\tpin_shape_count"
        ]
        for index, net in enumerate(NETS, start=1):
            llx = 100.0 + index
            lly = 200.0 + index
            urx = llx + 0.38
            ury = lly + 0.28
            box = f"{{{llx:.2f} {lly:.2f} {urx:.2f} {ury:.2f}}}"
            message = (
                f"Regular Wire of Net {net} Actual: 0.10640000 "
                "Required: 0.20200000 Type: Minimum Area"
            )
            marker_geometry.append(
                f"{net}\th{index}\t{box}\t{llx:.2f}\t{lly:.2f}\t{urx:.2f}\t"
                f"{ury:.2f}\t0.10640000\t0.20200000\t0.09560000\t{message}"
            )
            topology.append(
                f"{net}\t{box}\tPASS\tnh{index}\tPASS\t4\t1\tPASS\t1\t1\t"
                "PASS\t1\tPASS\t0\t1"
            )
            local_wires.append(
                f"{net}\t{box}\t1\twh{index}\tINTERSECTS_MARKER\tPASS\t{box}\t"
                "PASS\tMET1\tPASS\trouted\tPASS\twire\tPASS\t0.28\tPASS\t"
                "0.38\tPASS\t{100.0 200.0 100.38 200.0}"
            )
            local_vias.append(
                f"{net}\t{box}\t1\tvh{index}\tINTERSECTS_MARKER\tPASS\t{box}\t"
                "PASS\tVIA12\tPASS\tVIA1\tPASS\tMET1\tPASS\tMET2\tPASS\t"
                "{100.2 200.1}\tPASS\trouted\tPASS\tR0"
            )
            inst_terms.append(
                f"{net}\tith{index}\tPASS\tD\tPASS\tu{index}\tPASS\tCELLX1\t"
                "PASS\tD\tPASS\tinput\tPASS\t{99 199 101 201}\tPASS\t"
                "{99 199}\tPASS\tR0\tPASS\t{100 200}\tPASS\t{100 200}"
            )
            pin_shapes.append(
                f"{net}\tith{index}\tu{index}\tCELLX1\tD\tph{index}\tPASS\tMET1\t"
                "PASS\t{0.1 0.2 0.5 0.48}\tPASS\trect\tPASS\tD\t"
                "MASTER_LOCAL_REQUIRES_INSTANCE_TRANSFORM"
            )
        (reports / "min_area_marker_geometry.tsv").write_text(
            "\n".join(marker_geometry) + "\n"
        )
        (reports / "min_area_net_topology.tsv").write_text("\n".join(topology) + "\n")
        (reports / "min_area_local_wires.tsv").write_text(
            "\n".join(local_wires) + "\n"
        )
        (reports / "min_area_local_vias.tsv").write_text("\n".join(local_vias) + "\n")
        (reports / "min_area_inst_terms.tsv").write_text("\n".join(inst_terms) + "\n")
        (reports / "min_area_pin_shapes.tsv").write_text("\n".join(pin_shapes) + "\n")
        (reports / "min_area_top_terms.tsv").write_text("\n".join(top_terms) + "\n")
        (reports / "min_area_raw_queries.rpt").write_text("STATUS=CAPTURED\n")

        for name in (
            "net",
            "wire",
            "instTerm",
            "inst",
            "term",
            "pin",
            "pinShape",
            "marker",
            "layerShape",
            "shape",
            "viaInst",
        ):
            (reports / f"dbschema_{name}.rpt").write_text(f"SCHEMA={name}\n")
        for name in (
            "editAddRoute",
            "editCommitRoute",
            "setEditMode",
            "uiSetTool",
            "add_shape",
            "create_shape",
        ):
            (reports / f"man_{name}.rpt").write_text(f"HELP={name}\n")

        (reports / "min_area_geometry_probe_status.rpt").write_text(
            "LABEL=SPADMIC_OOC_MIN_AREA_GEOMETRY_PROBE\n"
            "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_READ_ONLY_LOCAL_GEOMETRY_PROBE\n"
            "DESIGN_MODIFICATION=NOT_RUN\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
            "RESTORE_DESIGN=PASS\n"
            "STATUS=PASS\n"
            "RESULT=MIN_AREA_LOCAL_GEOMETRY_EVIDENCE_CAPTURED\n"
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"STEP19_ANALYSIS={step19}\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "PRE_DRC_MARKER_COUNT=6\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            f"PRE_MIN_AREA_NETS={' '.join(NETS)}\n"
            "POST_DRC_VIOLATION_COUNT=6\n"
            "POST_DRC_MARKER_COUNT=6\n"
            "POST_MARKER_DATABASE_TOTAL=27\n"
            "POST_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0\n"
            "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            f"POST_MIN_AREA_NETS={' '.join(NETS)}\n"
            "SCHEMA_PASS_COUNT=11\n"
            "SCHEMA_FAIL_COUNT=0\n"
            "SCHEMA_net_STATUS=PASS\n"
            "SCHEMA_wire_STATUS=PASS\n"
            "SCHEMA_instTerm_STATUS=PASS\n"
            "SCHEMA_inst_STATUS=PASS\n"
            "SCHEMA_term_STATUS=PASS\n"
            "SCHEMA_pin_STATUS=PASS\n"
            "SCHEMA_pinShape_STATUS=PASS\n"
            "HELP_PASS_COUNT=6\n"
            "HELP_UNAVAILABLE_COUNT=0\n"
            "QUERY_PASS_COUNT=100\n"
            "QUERY_FAIL_COUNT=12\n"
            "NET_HANDLE_PASS_COUNT=6\n"
            "WIRE_QUERY_PASS_NET_COUNT=6\n"
            "LOCAL_WIRE_NET_COUNT=6\n"
            "LOCAL_WIRE_ROW_COUNT=6\n"
            "WIRE_CONTEXT_ROW_COUNT=6\n"
            "VIA_QUERY_PASS_NET_COUNT=6\n"
            "LOCAL_VIA_NET_COUNT=6\n"
            "LOCAL_VIA_ROW_COUNT=6\n"
            "VIA_CONTEXT_ROW_COUNT=6\n"
            "INST_TERM_NET_COUNT=6\n"
            "INST_TERM_ROW_COUNT=6\n"
            "TOP_TERM_ROW_COUNT=0\n"
            "PIN_SHAPE_NET_COUNT=6\n"
            "PIN_SHAPE_ROW_COUNT=6\n"
            "TOPOLOGY_CAPTURE_STATUS="
            "COMPLETE_LOCAL_WIRES_TERMINALS_AND_MASTER_PIN_SHAPES\n"
            "NEXT_METHOD_DECISION="
            "REVIEW_LOCAL_WIRE_AND_TERMINAL_GEOMETRY_BEFORE_DIRECT_PATCH_TRIAL\n"
        )
        return probe_root, step19

    def run_analyzer(self, probe_root: Path, step19: Path, report: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--probe-root",
                str(probe_root),
                "--step19-analysis",
                str(step19),
                "--report-driver-head",
                HEAD,
                "--report",
                str(report),
            ],
            cwd=REPO,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def test_complete_geometry_capture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe_root, step19 = self.write_fixture(root)
            report = root / "analysis.rpt"
            result = self.run_analyzer(probe_root, step19, report)
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn("STATUS=PASS", text)
            self.assertIn("RESULT=MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED", text)
            self.assertIn("LOCAL_GEOMETRY_CAPTURE_STATUS=COMPLETE_FOR_ALL_SIX_NETS", text)
            self.assertIn(
                "MARKER_SIGNATURE_STABILITY=PASS_IDENTICAL_BEFORE_AND_AFTER_QUERY_PROBE",
                text,
            )
            self.assertIn("DIRECT_GEOMETRY_TRIAL_DECISION=BLOCKED_PENDING_OPERATOR_REVIEW", text)
            self.assertIn("PVS_DECISION=DO_NOT_RUN", text)

    def test_marker_change_fails_read_only_invariant(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe_root, step19 = self.write_fixture(root, shifted_post=True)
            report = root / "analysis.rpt"
            result = self.run_analyzer(probe_root, step19, report)
            self.assertEqual(result.returncode, 8, result.stdout)
            text = report.read_text()
            self.assertIn("STATUS=FAIL", text)
            self.assertIn("marker_signature_changed_across_read_only_probe", text)


if __name__ == "__main__":
    unittest.main()
