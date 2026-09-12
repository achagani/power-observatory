"""Offscreen UI interaction checks; no helper or hardware control is executed."""
import os
os.environ['QT_QPA_PLATFORM']='offscreen'
os.environ['QT_QUICK_BACKEND']='software'
from pathlib import Path
import json
import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView, QQuickItem
from PySide6.QtCore import QUrl, Qt, QPoint, QPointF, qInstallMessageHandler
from PySide6.QtTest import QTest

ROOT=Path(__file__).resolve().parents[1]
messages=[]
def message_handler(kind,context,text):
    messages.append(text)
    print(text,file=sys.stderr)
qInstallMessageHandler(message_handler)
app=QGuiApplication([])
view=QQuickView();view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile(str(ROOT/'package/contents/ui/Dashboard.qml')))
assert view.status()!=QQuickView.Error
view.resize(640,890)
root=view.rootObject()
data=json.loads((ROOT/'tests/fixtures/demo.json').read_text())
root.setProperty('telemetry',data)
view.show();QTest.qWait(100)
def find_item(name, item=None):
    item = root if item is None else item
    if item.objectName() == name and item.isVisible(): return item
    for child in item.childItems():
        found=find_item(name,child)
        if found is not None:return found
    return None

requests=[];root.refreshRequested.connect(lambda output,mode:requests.append((output,mode)))
button=find_item('refresh-1-slow')
assert button is not None and button.isEnabled()
point=button.mapToScene(QPointF(button.width()/2,button.height()/2))
QTest.mouseClick(view,Qt.LeftButton,Qt.NoModifier,QPoint(round(point.x()),round(point.y())))
assert requests==[('1','slow')],requests
assert not find_item('refresh-1-fast').isEnabled()
root.setProperty('controlBusy',True);QTest.qWait(20)
assert not button.isEnabled()
root.setProperty('controlBusy',False)
for width in (480,640):
    view.resize(width,890)
    for tab in range(4):
        root.setProperty('tab',tab);QTest.qWait(25)
        assert root.width()==width
# Missing data and hotplug remove controls rather than leaving stale choices.
root.setProperty('telemetry',{});QTest.qWait(30)
assert find_item('refresh-1-slow') is None
bad=[m for m in messages if any(term in m for term in ('Error','is not defined','Binding loop','recursive rearrange','Unable to assign'))]
assert not bad,bad
print('QML checks passed: mode signal, active/busy states, tabs, widths, unavailable data.')
