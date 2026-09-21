"""Regression tests for DSN nesting; run with python3 scripts/test_export_dsn.py."""
import pathlib
import tempfile
import unittest

from export_dsn import (replace_planes, scope_spans, validate, real_plane_fills,
                        bridge_split_pads)

try:
    import pcbnew
except ImportError:
    pcbnew = None


class ExportStructureTests(unittest.TestCase):
    def test_replace_planes_preserves_keepouts_and_scopes(self):
        source = '''(pcb "board (prototype)"
  (parser
    (string_quote ")
  )
  (resolution um 10)
  (unit um)
  (structure
    (plane GND (rect B.Cu 0 0 100 100))
    (keepout obstacle (rect F.Cu 10 10 20 20))
    (rule (clearance 150))
  )
  (placement)
  (library)
  (network)
  (wiring)
)'''
        fill = '(plane GND (polygon B.Cu 0 0 0 100 0 100 100) (window (rect B.Cu 10 10 20 20)))'
        result = replace_planes(source, fill)
        paths = [p for p, _, _ in scope_spans(result)]
        self.assertEqual(paths.count(('pcb', 'structure', 'plane')), 1)
        self.assertIn(('pcb', 'structure', 'plane', 'window'), paths)
        self.assertIn('(keepout obstacle (rect F.Cu 10 10 20 20))', result)
        self.assertIn('(rule (clearance 150))', result)
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'board.dsn'
            path.write_text(result)
            self.assertEqual(validate(path), [])
            path.write_text(source[:-1] + fill + ')')
            self.assertIn('plane outside pcb/structure', validate(path))

    def test_filled_polygon_hole_is_a_child_of_plane(self):
        class Point:
            x = 1000
            y = 2000

        class Polygons:
            def CloneDropTriangulation(self): return self
            def Unfracture(self): pass
            def OutlineCount(self): return 1
            def Outline(self, _): return self
            def PointCount(self): return 4
            def CPoint(self, _): return Point()
            def HoleCount(self, _): return 1
            def Hole(self, *_): return self

        class Zone:
            def GetIsRuleArea(self): return False
            def IsOnCopperLayer(self): return True
            def GetNetname(self): return 'GND'
            def GetLayerSet(self): return self
            def CuStack(self): return [0]
            def GetFilledPolysList(self, _): return Polygons()

        class Board:
            def Zones(self): return [Zone()]
            def GetLayerName(self, _): return 'F.Cu'

        fills, count = real_plane_fills(Board(), None)
        self.assertEqual(count, 1)
        paths = [p for p, _, _ in scope_spans(fills)]
        self.assertIn(('plane', 'window'), paths)
        self.assertNotIn(('window',), paths)


@unittest.skipIf(pcbnew is None, 'KiCad bindings required for native pad geometry')
class SplitPadGeometryTests(unittest.TestCase):
    def setUp(self):
        p = pcbnew
        self.board = p.BOARD()
        self.net = p.NETINFO_ITEM(self.board, '/GND')
        self.board.Add(self.net)
        self.fp = p.FOOTPRINT(self.board)
        self.fp.SetReference('J1')
        self.board.Add(self.fp)

    def pad(self, at, size, shape):
        p = pcbnew
        pad = p.PAD(self.fp)
        pad.SetNumber('2')
        pad.SetAttribute(p.PAD_ATTRIB_SMD)
        pad.SetShape(shape)
        layers = p.LSET()
        layers.AddLayer(p.F_Cu)
        pad.SetLayerSet(layers)
        pad.SetSize(p.VECTOR2I(p.FromMM(size[0]), p.FromMM(size[1])))
        pad.SetPosition(p.VECTOR2I(p.FromMM(at[0]), p.FromMM(at[1])))
        pad.SetNetCode(self.net.GetNetCode())
        self.fp.Add(pad)
        return pad

    def test_separated_bnc_shell_pads_are_never_bridged(self):
        for xy in ((-5,-5),(-5,5),(5,-5),(5,5)):
            self.pad(xy, (2,2), pcbnew.PAD_SHAPE_CIRCLE)
        self.assertEqual(bridge_split_pads(self.board, pcbnew), ([], 0))

    def test_thermal_array_centres_inside_exposed_pad_are_bridged(self):
        self.pad((0,0), (5,5), pcbnew.PAD_SHAPE_RECT)
        for xy in ((-1,0),(1,0)):
            self.pad(xy, (.7,.7), pcbnew.PAD_SHAPE_CIRCLE)
        wires, count = bridge_split_pads(self.board, pcbnew)
        self.assertEqual(count, 2)
        self.assertTrue(all('(type protect)' in w for w in wires))

    def test_different_net_never_bridged(self):
        self.pad((0,0), (5,5), pcbnew.PAD_SHAPE_RECT)
        pad = self.pad((1,0), (.7,.7), pcbnew.PAD_SHAPE_CIRCLE)
        pad.SetNetCode(0)
        self.assertEqual(bridge_split_pads(self.board, pcbnew), ([], 0))


if __name__ == '__main__':
    unittest.main()
