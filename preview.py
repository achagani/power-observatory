"""Render fixture-only previews; no live telemetry or hardware controls."""
import os
os.environ.setdefault('QT_QPA_PLATFORM','offscreen')
os.environ.setdefault('QT_QUICK_BACKEND','software')
import sys, json, math, copy
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl, QTimer
app=QGuiApplication(sys.argv)
view=QQuickView();view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile(str(Path(__file__).parent/'package/contents/ui/Dashboard.qml')))
if view.status()==QQuickView.Error:
    for error in view.errors():print(error.toString(),file=sys.stderr)
    sys.exit(1)
view.resize(int(sys.argv[2]) if len(sys.argv)>2 else 640,890)
root=view.rootObject();root.setProperty('liveClock',False)
now=1700000120.0;root.setProperty('now',now)
data=json.loads(Path(sys.argv[1]).read_text())
# Deterministic illustrative history, clearly labeled in documentation.
for i in range(61):
    sample=copy.deepcopy(data);sample['timestamp']=now-120+i*2
    peak=math.sin(math.pi*i/60)**4
    for domain in ('cpu','gpu'):
        start=data.get(domain,{}).get('busy')
        if isinstance(start,(int,float)):sample[domain]['busy']=start*(1-peak)+99*peak
    if isinstance(data.get('apu_watts'),(int,float)):sample['apu_watts']=data['apu_watts']*(1-peak)+105*peak
    for domain in ('cpu','gpu','npu'):
        v=data.get(domain,{}).get('watts')
        if isinstance(v,(int,float)):sample[domain]['watts']=v*(1-peak)+{'cpu':65,'gpu':55,'npu':11}[domain]*peak
    for obj,used,total in [('ram','used','total'),('gpu','vram_used','vram_total')]:
        src=data.get(obj,{})
        if src.get(total) and isinstance(src.get(used),(int,float)):
            sample[obj][used]=src[used]*(1-peak)+src[total]*.98*peak
    for fan in sample.get('fans',[]):fan['value']=fan['value']*(1-peak)+4800*peak
    for sensor in sample.get('sensors',[]):sensor['value']+=peak*12
    root.setProperty('telemetry',sample)
view.show();out=Path(__file__).parent/'previews';out.mkdir(exist_ok=True)
def capture(tab=0):
    root.setProperty('tab',tab)
    def save():
        assert view.grabWindow().save(str(out/f'tab-{tab}-{view.width()}.png'))
        if tab<3:capture(tab+1)
        else:app.quit()
    QTimer.singleShot(250,save)
QTimer.singleShot(400,capture)
app.exec()
