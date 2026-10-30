# make_topojson.py : builds a TopoJSON of the LGA polygons for Power BI's Shape Map. Pure Python, no packages.
# Usage:  py scripts/make_topojson.py raw/grid3_nga_boundary_vacclgas.shp powerbi/lga_three_states.topojson
# Why: Power BI draws custom maps from TopoJSON. Each LGA is keyed by `lgacode`, which matches gold.dim_lga_geo.lgacode.
import struct, json, sys
from pathlib import Path
KEEP = {"lagos", "oyo", "ondo"}          # states in scope
TOL = 0.0004                              # simplification tolerance in degrees (about 45 m)

def read_dbf(p):
    f = open(p, "rb").read()
    n = struct.unpack("<I", f[4:8])[0]; hl = struct.unpack("<H", f[8:10])[0]; rl = struct.unpack("<H", f[10:12])[0]
    fields, i = [], 32
    while f[i] != 0x0D:
        fields.append((f[i:i+11].split(b"\0")[0].decode(), f[i+16])); i += 32
    rows = []
    for k in range(n):
        r = f[hl + k*rl: hl + (k+1)*rl]; off = 1; rec = {}
        for name, ln in fields:
            rec[name] = r[off:off+ln].decode("utf-8", "replace").strip(); off += ln
        rows.append(rec)
    return rows

def read_shp(p):
    f = open(p, "rb").read(); pos = 100; shapes = []
    while pos < len(f):
        clen = struct.unpack(">i", f[pos+4:pos+8])[0] * 2; body = f[pos+8: pos+8+clen]; pos += 8 + clen
        t = struct.unpack("<i", body[:4])[0]
        if t == 0: shapes.append([]); continue
        np_, npt = struct.unpack("<ii", body[36:44])
        parts = list(struct.unpack(f"<{np_}i", body[44:44+4*np_])) + [npt]
        pts = struct.unpack(f"<{2*npt}d", body[44+4*np_: 44+4*np_+16*npt])
        xy = [(pts[2*i], pts[2*i+1]) for i in range(npt)]
        shapes.append([xy[parts[j]:parts[j+1]] for j in range(np_)])
    return shapes

def dp(points, tol):                       # Douglas-Peucker, iterative
    if len(points) < 5: return points
    keep = [False]*len(points); keep[0] = keep[-1] = True; stack = [(0, len(points)-1)]
    while stack:
        a, b = stack.pop(); (x1, y1), (x2, y2) = points[a], points[b]
        dx, dy = x2-x1, y2-y1; d2 = dx*dx + dy*dy; best, idx = -1, -1
        for i in range(a+1, b):
            x, y = points[i]
            if d2 == 0: dist = ((x-x1)**2 + (y-y1)**2) ** .5
            else: dist = abs(dy*(x-x1) - dx*(y-y1)) / d2 ** .5
            if dist > best: best, idx = dist, i
        if best > tol: keep[idx] = True; stack += [(a, idx), (idx, b)]
    return [p for p, k in zip(points, keep) if k]

def area(r): return sum(r[i][0]*r[i+1][1] - r[i+1][0]*r[i][1] for i in range(len(r)-1)) / 2

def main(shp, out):
    shp = Path(shp); attrs = read_dbf(shp.with_suffix(".dbf")); shapes = read_shp(shp)
    arcs, geoms = [], []
    for a, rings in zip(attrs, shapes):
        if a["statename"].lower() not in KEEP or not rings: continue
        polys = []
        for ring in rings:
            r = dp(ring, TOL)
            if len(r) < 4: continue
            arcs.append([[round(x, 5), round(y, 5)] for x, y in r]); idx = len(arcs) - 1
            if area(r) < 0 or not polys: polys.append([[idx]])      # clockwise = exterior ring (shapefile convention)
            else: polys[-1].append([idx])                             # hole
        g = {"type": "Polygon", "arcs": polys[0]} if len(polys) == 1 else {"type": "MultiPolygon", "arcs": polys}
        g["properties"] = {"lgacode": a["lgacode"], "lganame": a["lganame"], "statename": a["statename"]}
        geoms.append(g)
    topo = {"type": "Topology", "objects": {"lgas": {"type": "GeometryCollection", "geometries": geoms}}, "arcs": arcs}
    Path(out).write_text(json.dumps(topo, separators=(",", ":")))
    print(len(geoms), "LGAs,", len(arcs), "arcs,", round(Path(out).stat().st_size/1024), "KB ->", out)

if __name__ == "__main__": main(sys.argv[1], sys.argv[2])
