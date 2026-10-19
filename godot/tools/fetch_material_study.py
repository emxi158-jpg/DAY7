"""Download only nine 2K CC0 PBR maps from their official asset URLs."""
from pathlib import Path
import urllib.request,concurrent.futures,json,hashlib

out=Path(__file__).resolve().parents[1]/'samples'/'material_study'/'textures'
out.mkdir(parents=True,exist_ok=True)
assets={'brown_leather':['albedo','nor_gl','rough'],'white_plaster_02':['diff','nor_gl','rough'],'floor_tiles_08':['diff','nor_gl','rough']}
def fetch(item):
    asset,kind=item
    name=f'{asset}_{kind}_2k.jpg'
    url=f'https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/{asset}/{name}'
    path=out/name
    if not path.exists():
        with urllib.request.urlopen(url,timeout=30) as response:path.write_bytes(response.read())
    data=path.read_bytes()
    print('MAP',name,len(data),flush=True)
    return {'file':name,'url':url,'asset_page':f'https://polyhaven.com/a/{asset}','license':'CC0','sha256':hashlib.sha256(data).hexdigest()}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    records=list(pool.map(fetch,[(a,k) for a,ks in assets.items() for k in ks]))
(out.parent/'sources.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('TOTAL_BYTES',sum((out/r['file']).stat().st_size for r in records))
