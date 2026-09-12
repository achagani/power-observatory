"""Offscreen UI interaction checks; no helper or hardware control is executed."""
import os
os.environ['QT_QPA_PLATFORM']='offscreen'
os.environ['QT_QUICK_BACKEND']='software'
from pathlib import Path
import json
import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QJSEngine
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
# Exercise the same JavaScript classification rules imported by QML.
engine=QJSEngine()
result=engine.evaluate((ROOT/'package/contents/ui/Zones.js').read_text().replace('.pragma library',''))
assert not result.isError(),result.toString()
cases=[
    ('memory(null,100).index',-1),('memory(0,100).index',0),('memory(60,100).index',1),
    ('memory(85,100).index',2),('memory(95,100).index',3),('memory(100,0).index',-1),
    ('memory(105,100).ratio',1.05),('memory(-1,100).index',-1),
    ('power(null,[30,60,90]).index',-1),('power(0,[30,60,90]).index',0),
    ('power(30,[30,60,90]).index',1),('power(60,[30,60,90]).index',2),('power(90,[30,60,90]).index',3),
    ('thermal(110,null,null).index',-1),('thermal(95,80,95).index',3),
    ('thermal(90,80,95).index',2),('thermal(50,80,95).index',0),('thermal(null,80,95).index',-1),
    ('thermal(-5,80,95).index',0),('load(100).label','Near capacity')]
for expression,expected in cases:
    result=engine.evaluate(expression)
    assert not result.isError(),expression
    assert result.toVariant()==expected,(expression,result.toVariant(),expected)

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
# Memory/gauge shapes handle saturation, genuine zero, missing totals and staleness.
root.setProperty('tab',0)
for used,total,expected in [(0,100,0),(60,100,.6),(105,100,1),(None,100,0),(10,0,0)]:
    changed=json.loads(json.dumps(data));changed['gpu']['vram_used']=used;changed['gpu']['vram_total']=total
    root.setProperty('telemetry',changed);QTest.qWait(20)
    assert find_item('vram-gauge').property('fillFraction')==expected
root.setProperty('telemetry',data);root.setProperty('stale',True);QTest.qWait(20)
assert find_item('vram-gauge').property('fillFraction')==0
root.setProperty('stale',False)
# A hardware danger banner requires an actual reported critical threshold.
root.setProperty('telemetry',json.loads((ROOT/'tests/fixtures/high-draw.json').read_text()));QTest.qWait(20)
assert find_item('thermal-danger') is not None
root.setProperty('stale',True);QTest.qWait(20)
assert find_item('thermal-danger') is None
root.setProperty('stale',False)
unknown=json.loads(json.dumps(data));unknown['sensors']=[{'name':'Unknown limit','value':110,'critical':None}]
root.setProperty('telemetry',unknown);QTest.qWait(20)
assert find_item('thermal-danger') is None
# Missing data and hotplug remove controls rather than leaving stale choices.
root.setProperty('telemetry',{});QTest.qWait(30)
assert find_item('refresh-1-slow') is None
bad=[m for m in messages if any(term in m for term in ('Error','is not defined','Binding loop','recursive rearrange','Unable to assign'))]
assert not bad,bad
print('QML checks passed: controls, tabs, widths, 20 zone boundaries, saturation, missing/stale gauges.')
