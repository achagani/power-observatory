import ctypes
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('telemetry',Path(__file__).parent/'package/contents/code/telemetry.py')
t=importlib.util.module_from_spec(spec);spec.loader.exec_module(t)

class TelemetryTests(unittest.TestCase):
    def battery(self,status='Discharging',power=20000000):
        directory=tempfile.TemporaryDirectory();self.addCleanup(directory.cleanup)
        p=Path(directory.name)
        for name,value in dict(status=status,power_now=power,voltage_now=16000000,energy_now=40000000,energy_full=70000000,energy_full_design=70000000,capacity=57).items():
            (p/name).write_text(str(value))
        return p
    def test_discharge_remaining(self):
        b,_=t.battery_data(self.battery(),False,{},100)
        self.assertEqual(b['watts'],20);self.assertEqual(b['seconds'],7200)
    def test_charging_time(self):
        b,_=t.battery_data(self.battery('Charging'),True,{},100)
        self.assertEqual(b['seconds'],5400)
    def test_zero_flow_no_infinite_estimate(self):
        b,_=t.battery_data(self.battery(power=0),False,{},100)
        self.assertIsNone(b['seconds']);self.assertEqual(b['watts'],0)
    def test_missing_power_is_not_zero(self):
        p=self.battery();(p/'power_now').unlink()
        b,_=t.battery_data(p,False,{},100)
        self.assertIsNone(b['watts']);self.assertIsNone(b['seconds'])
    def test_adapter_supplementing_battery(self):
        b,_=t.battery_data(self.battery(),True,{},100)
        self.assertTrue(b['ac']);self.assertEqual(b['seconds'],7200)
    def test_smoothing_resets_on_status_change(self):
        b,_=t.battery_data(self.battery(),False,{'battery_filter':{'time':99,'status':'Charging','watts':90}},100)
        self.assertEqual(b['smoothed_watts'],20)
    def test_cpu_idle_and_busy(self):
        old=[100,0,0,100,0,0,0,0]
        self.assertEqual(t.percent_delta([150,0,0,150,0,0,0,0],old),50)
        self.assertIsNone(t.percent_delta(old,None))
    def test_metrics_abi_and_sentinels(self):
        self.assertEqual(ctypes.sizeof(t.MetricsV3),264)
        m=t.MetricsV3();m.size=264;m.format=3;m.content=0
        m.average_apu_power=42000;m.stapm_power_limit=65535
        with tempfile.NamedTemporaryFile() as f:
            f.write(bytes(m));f.flush();data=t.metrics(f.name)
            self.assertEqual(data['average_apu_power'],42000)
            self.assertIsNone(data['stapm_power_limit'])
            m.format=4;f.seek(0);f.write(bytes(m));f.flush()
            self.assertEqual(t.metrics(f.name),{})
    def test_charger_modes(self):
        for ac,mode,expected in [(False,1,'battery'),(True,1,'barrel'),(True,2,'usb'),(True,3,'barrel'),(None,0,'unknown')]:
            with patch.object(t,'number',return_value=mode),patch.object(t.Path,'glob',return_value=[]):
                self.assertEqual(t.charger_data(ac)['kind'],expected)

if __name__=='__main__':unittest.main()
