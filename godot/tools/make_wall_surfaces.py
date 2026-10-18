"""Fine plaster and painted dado, without repeating cloud/mould blotches."""
from pathlib import Path
import numpy as np
from PIL import Image

out=Path(__file__).resolve().parents[1]/'assets'/'materials'
rng=np.random.default_rng(71018)
n=1024
def noise(size):
    return np.asarray(Image.fromarray(rng.random((size,size),dtype=np.float32)).resize((n,n),Image.Resampling.BICUBIC))-.5
for name,base in [('plaster',(158,154,145)),('dado',(92,104,100))]:
    grain=noise(600)*2.8+noise(180)*1.6+noise(24)*.65
    color=np.array(base)[None,None,:]+grain[:,:,None]
    Image.fromarray(np.uint8(np.clip(color,0,255))).save(out/(name+'_color.png'))
    height=noise(500)*.08+noise(160)*.04
    dy,dx=np.gradient(height)
    v=np.stack([-dx,dy,np.ones_like(dx)],-1)
    v/=np.linalg.norm(v,axis=-1,keepdims=True)
    Image.fromarray(np.uint8((v*.5+.5)*255)).save(out/(name+'_normal.png'))
print('Generated fine plaster/paint; no broad cloud noise.')
