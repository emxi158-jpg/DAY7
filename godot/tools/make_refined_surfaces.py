"""Deterministic, self-contained PBR maps for the native Godot room."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'materials' / 'refined'
OUT.mkdir(exist_ok=True)
N = 1024

def field(rng, size):
    a = rng.random((size, size), dtype=np.float32)
    return np.asarray(Image.fromarray(a).resize((N, N), Image.Resampling.BICUBIC), dtype=np.float32)

def save(name, a):
    Image.fromarray(np.uint8(np.clip(a, 0, 255))).save(OUT / (name + '.png'), optimize=True)

def normal(height, strength):
    dy, dx = np.gradient(height)
    v = np.stack((-dx * strength, dy * strength, np.ones_like(dx)), -1)
    v /= np.linalg.norm(v, axis=-1, keepdims=True)
    return (v * .5 + .5) * 255

yy, xx = np.mgrid[:N, :N] / (N - 1)
edge = np.minimum.reduce([xx, yy, 1-xx, 1-yy])
for k in range(4):
    rng = np.random.default_rng(7140+k)
    cloud = (field(rng, 5)-.5)*6 + (field(rng, 16)-.5)*7 + (field(rng, 50)-.5)*7 + (field(rng,180)-.5)*3
    grit = (field(rng, 400)-.5)
    edge_dirt = np.exp(-edge*75) * (3+field(rng, 20)*9)
    # Small, irregular mineral inclusions and hairline scratches in old glaze.
    marks = Image.new('L', (N,N))
    draw = ImageDraw.Draw(marks)
    for i in range(48):
        x,y = rng.integers(0,N,2)
        dx,dy = rng.integers(-65,65,2)
        draw.line([(int(x),int(y)),(int(x+dx*.55),int(y+dy*.6)),(int(x+dx),int(y+dy))],fill=int(rng.integers(25,90)),width=1)
    for i in range(3300):
        x,y = rng.integers(0,N,2)
        draw.point((int(x),int(y)),fill=int(rng.integers(10,65)))
    scratches = np.asarray(marks.filter(ImageFilter.GaussianBlur(.35)), dtype=np.float32)/255
    palette = [(111,104,91),(105,101,92),(113,108,99),(106,102,94)][k]
    tone = cloud + grit*3 - edge_dirt - scratches*21
    color = np.array(palette)[None,None,:] + tone[:,:,None]*np.array([1.,.95,.86])
    save(f'tile_{k}_albedo', color)
    # Worn glaze is locally polished; pores and dusty edges stay rough.
    polish = field(rng, 7)
    rough = np.clip(.27 + polish*.19 + (field(rng,35)-.5)*.08 + edge_dirt*.012 + scratches*.2,.24,.76)
    save(f'tile_{k}_roughness', np.stack([rough*255]*3,-1))
    height = (field(rng,90)-.5)*.09 + grit*.085 - scratches*.08 - edge_dirt*.004
    save(f'tile_{k}_normal', normal(height, 1.7))

rng=np.random.default_rng(1953)
rad=np.sqrt((xx-.5)**2+(yy-.5)**2)*2
aging=(field(rng,7)-.5)*9+(field(rng,60)-.5)*3
rim=np.clip((rad-.80)*24,0,7)*(field(rng,18)+.5)
specks=(rng.random((N,N))>.9985)*rng.uniform(6,23,(N,N))
save('clock_dial',np.array([224,221,210])+((aging-rim-specks)[:,:,None])*np.array([1.,1.,.95]))
metalnoise=(field(rng,18)-.5)*16+(field(rng,200)-.5)*8
rust=np.maximum(field(rng,26)-.67,0)*65
save('clock_metal',np.stack([50+metalnoise+rust,48+metalnoise*.9+rust*.45,38+metalnoise*.8],-1))
save('clock_metal_roughness',np.stack([np.clip(146+metalnoise*2+rust,100,225)]*3,-1))
paint_noise=(field(rng,8)-.5)*9+(field(rng,180)-.5)*3
paint_dirt=np.maximum(field(rng,30)-.62,0)*25
save('dispenser_enamel',np.array([199,197,182])+(paint_noise-paint_dirt)[:,:,None])
save('dispenser_roughness',np.stack([np.clip(142+paint_dirt*3+paint_noise,120,205)]*3,-1))
print('Generated',len(list(OUT.glob('*.png'))),'procedural PBR maps at',OUT)
