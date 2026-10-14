import importlib.util, os, unittest
p = os.path.join(os.path.dirname(__file__), "..", "qs-rss-report.py")
spec = importlib.util.spec_from_file_location("rep", p)
rep = importlib.util.module_from_spec(spec); spec.loader.exec_module(rep)


def line(up, anon, pid=1, rss=None, fds=60):
    return (f"2026-10-14T00:00:00-03:00 qs-rss rss={rss or anon + 100}MB anon={anon}MB shared=70MB "
            f"cgroup={anon + 120}MB threads=14 fds={fds} up={up}s pid={pid}")


class Report(unittest.TestCase):
    def run_rows(self, lines, **kw):
        return rep.report(rep.parse(lines), **kw)

    def test_flat_session_is_flat(self):
        lines = [line(600 + i * 120, 300 + (i % 3)) for i in range(120)]   # 4 h
        rows, bad = self.run_rows(lines)
        self.assertFalse(bad)
        self.assertEqual(rows[0][-1], "flat")

    def test_linear_growth_is_flagged(self):
        lines = [line(600 + i * 120, 200 + int(i * 120 / 3600 * 50)) for i in range(120)]   # 50 MB/h
        rows, bad = self.run_rows(lines)
        self.assertTrue(bad)
        self.assertEqual(rows[0][-1], "GROWING")
        self.assertAlmostEqual(rows[0][3], 50, delta=3)

    def test_warmup_is_ignored(self):
        # fast fill in the first 10 minutes, then flat
        lines = [line(i * 60, 150 + min(i, 10) * 5) for i in range(1, 11)]
        lines += [line(600 + i * 120, 200) for i in range(120)]
        rows, bad = self.run_rows(lines)
        self.assertFalse(bad)

    def test_short_window_is_not_a_verdict(self):
        lines = [line(700 + i * 120, 200 + i * 5) for i in range(5)]
        rows, bad = self.run_rows(lines)
        self.assertFalse(bad)
        self.assertEqual(rows[0][-1], "too short")

    def test_pids_are_separated_and_junk_skipped(self):
        lines = ["garbage", "2026-10-14T00:00:00-03:00 qs-rss not running"]
        lines += [line(700 + i * 120, 200, pid=1) for i in range(60)]
        lines += [line(700 + i * 120, 400, pid=2) for i in range(60)]
        rows, _ = self.run_rows(lines)
        self.assertEqual([r[0] for r in rows], ["1", "2"])
        self.assertEqual([r[4] for r in rows], [200, 400])


if __name__ == "__main__":
    unittest.main()
