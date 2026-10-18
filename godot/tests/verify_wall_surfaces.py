from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageFilter

root=Path(__file__).resolve().parents[1]
report={}
for name in ['plaster','dado']:
    image=Image.open(root/'assets'/'materials'/(name+'_color.png')).convert('RGB')
    low=np.asarray(image.filter(ImageFilter.GaussianBlur(24)),dtype=float)
    std=low.std((0,1))
    assert float(std.max())<1.5, f'{name}: repeating broad cloud blotches returned ({std})'
    report[name+'_broad_variation']=std.round(3).tolist()
print('WALL_SURFACES_PASSED',json.dumps(report))
