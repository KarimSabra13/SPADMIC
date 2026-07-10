import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "audit_innovus_gds_export.py"
SPEC = importlib.util.spec_from_file_location("audit_innovus_gds_export", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class InnovusGdsAuditTest(unittest.TestCase):
    def test_mapped_streamout_accepts_symlinked_map_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            real = root / "real"
            real.mkdir()
            alias = root / "alias"
            alias.symlink_to(real, target_is_directory=True)
            stream_map = real / "pnr_streamout.map"
            stream_map.write_text("map\n")
            merge_gds = real / "stdcells.gds"
            merge_gds.write_bytes(b"gds")
            output_gds = root / "block.gds"
            output_gds.write_bytes(b"gds")
            log = (
                f"<CMD> streamOut {output_gds} -libName DesignLib "
                f"-mapFile {alias / stream_map.name} "
                f"-merge {{{alias / merge_gds.name}}}\n"
            )

            mapped, merged = MODULE.mapped_streamout_command(
                log, output_gds, stream_map, merge_gds
            )

            self.assertTrue(mapped)
            self.assertTrue(merged)

    def test_wrong_map_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output_gds = root / "block.gds"
            output_gds.write_bytes(b"gds")
            expected_map = root / "expected.map"
            expected_map.write_text("expected\n")
            wrong_map = root / "wrong.map"
            wrong_map.write_text("wrong\n")
            log = f"<CMD> streamOut {output_gds} -mapFile {wrong_map}\n"

            mapped, _ = MODULE.mapped_streamout_command(
                log, output_gds, expected_map
            )

            self.assertFalse(mapped)


if __name__ == "__main__":
    unittest.main()
