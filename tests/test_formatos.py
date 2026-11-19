"""A text that takes values (%s, %d) is filled by string.format: a lone "%" in it breaks the fill and the game shows the
raw text, with its %s. Every "%" of such a text is a value or is written "%%"."""
import pathlib
import re
import unittest

LOCALES = (pathlib.Path(__file__).resolve().parent.parent / "Locales.lua").read_text(encoding="utf-8")
TEXT = re.compile(r'(\w+) = "((?:[^"\\]|\\.)*)"')
VALUE = re.compile(r"%(?:\.\d+f|\d*[sd])")
LONE = re.compile(r"%(?!%)")


class Formats(unittest.TestCase):
    def test_a_text_with_values_has_no_lone_percent(self):
        bad = []
        for key, text in TEXT.findall(LOCALES):
            if not VALUE.search(text):
                continue
            rest = VALUE.sub("", text).replace("%%", "")
            if LONE.search(rest):
                bad.append(f"{key}: {text}")
        self.assertEqual(bad, [])


if __name__ == "__main__":
    unittest.main()
