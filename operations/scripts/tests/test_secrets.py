import runpy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

render = runpy.run_path(str(Path(__file__).resolve().parents[1] / "secrets.py"))[
    "render"
]


class SecretRenderingTests(unittest.TestCase):
    def test_rendering_updates_is_idempotent_and_rejects_stale_references(self):
        name = "authentik_secret_key"
        version = f"{name}_0123456789ab"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            stack = root / "platform/app/stack.yml"
            stack.parent.mkdir(parents=True)
            with patch.dict(render.__globals__, ROOT=root):
                for previous in ("", f'    name: "{name}_OLDHASH"\n'):
                    with self.subTest(previous=previous):
                        stack.write_text(
                            f"secrets:\n  {name}:\n    external: true\n{previous}"
                            "  unmanaged:\n    external: true\n    name: keep_me\n"
                        )
                        render({name: version})
                        expected = (
                            f"secrets:\n  {name}:\n    external: true\n"
                            f'    name: "{version}"\n'
                            "  unmanaged:\n    external: true\n    name: keep_me\n"
                        )
                        self.assertEqual(stack.read_text(), expected)
                        render({name: version})
                        self.assertEqual(stack.read_text(), expected)

                reordered = (
                    f"secrets:\n  {name}:\n"
                    f'    name: "{name}_OLDHASH"\n    external: true\n'
                )
                stack.write_text(reordered)
                with self.assertRaisesRegex(RuntimeError, f".*{name}"):
                    render({name: version})
                self.assertEqual(stack.read_text(), reordered)


if __name__ == "__main__":
    unittest.main()
