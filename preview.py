import os
os.environ.setdefault('QT_QPA_PLATFORM','offscreen')
os.environ.setdefault('QT_QUICK_BACKEND','software')
import sys, json, math
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl, QTimer
app=QGuiApplication(sys.argv)
view=QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile(str(Path(__file__).parent/'package/contents/ui/Dashboard.qml')))
if view.status()==QQuickView.Error: sys.exit(1)
view.resize(int(sys.argv[2]) if len(sys.argv)>2 else 640,890)
root=view.rootObject()
root.setProperty('telemetry',json.loads(Path(sys.argv[1]).read_text()))
# A deterministic illustrative history is used only with the synthetic demo fixture.
if Path(sys.argv[1]).resolve() == (Path(__file__).parent/'tests/fixtures/demo.json').resolve():
    root.setProperty('cpuHistory',[12+8*math.sin(i/6)+3*math.sin(i/2) for i in range(60)])
    root.setProperty('gpuHistory',[8+4*math.sin(i/8) for i in range(60)])
    root.setProperty('powerHistory',[25+5*math.sin(i/7)+2*math.cos(i/3) for i in range(60)])
view.show()
out=Path(__file__).parent/'previews';out.mkdir(exist_ok=True)
def capture(tab=0):
    root.setProperty('tab',tab)
    def save():
        view.grabWindow().save(str(out/f'tab-{tab}-{view.width()}.png'))
        if tab<3: capture(tab+1)
        else: app.quit()
    QTimer.singleShot(200,save)
QTimer.singleShot(400,capture)
app.exec()
