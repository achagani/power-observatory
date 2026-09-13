"""Hardware-independent discovery and invalidation checks."""
import tempfile
import unittest
from pathlib import Path
from test_telemetry import t

class ReferencesTests(unittest.TestCase):
    def test_fan_driver_user_and_estimated_precedence(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'fan1_input'; p.write_text('8800')
            ref,peak=t.fan_reference(p,8800,{}, {})
            self.assertEqual(ref['reference_rpm'],9000)
            self.assertIn('Estimated',ref['reference_source'])
            old={ref['identity']:peak}
            ref,_=t.fan_reference(p,2000,{},old)
            self.assertEqual(ref['reference_rpm'],9000)
            p.with_name('fan1_max').write_text('10000')
            ref,_=t.fan_reference(p,8800,{},old)
            self.assertEqual(ref['reference_rpm'],10000)
            self.assertEqual(ref['reference_source'],'Driver high reference')
            ref,_=t.fan_reference(p,8800,{'fan_reference_rpm':{str(p):12000}},old)
            self.assertEqual(ref['reference_rpm'],12000)
            p.with_name('fan1_max').unlink()
            ref,_=t.fan_reference(p,0,{}, {})
            self.assertIsNone(ref['reference_rpm'])

    def test_fan_bad_limits_and_distinct_hardware(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'fan2_input'
            for invalid in ('0','-1','nan','inf','4294967295'):
                p.with_name('fan2_max').write_text(invalid)
                ref,_=t.fan_reference(p,3000,{'fan_reference_rpm':{str(p):True}}, {'other-device':9000})
                self.assertEqual(ref['reference_rpm'],3000)
                self.assertIn('Estimated',ref['reference_source'])

    def test_power_limits_follow_current_machine_and_profile(self):
        for limit in (15,65,120):
            bands,refs=t.power_references({}, {'current_stapm_power_limit':limit,'stapm_power_limit':150})
            self.assertEqual(bands['apu'],[limit*.4,limit*.8,limit*.95])
            self.assertEqual(refs['apu']['maximum'],limit)
            self.assertEqual(refs['gpu']['source'],'Estimated reference')
        bands,refs=t.power_references({'power_bands_watts':{'apu':[10,20,30]}},{'current_stapm_power_limit':65})
        self.assertEqual(bands['apu'],[10,20,30])
        self.assertEqual(refs['apu']['source'],'User configured')

    def test_power_invalid_and_removed_limits(self):
        for value in (None,0,-1,True,float('nan'),float('inf'),65535):
            bands,refs=t.power_references({'barrel_rated_watts':200,'power_bands_watts':{'apu':[30,20,10]}},{'current_stapm_power_limit':value})
            self.assertEqual(refs['apu']['source'],'Estimated reference')
            self.assertEqual(bands['apu'],t.DEFAULT_POWER_BANDS['apu'])
        _,refs=t.power_references({}, {'current_stapm_power_limit':0,'stapm_power_limit':45})
        self.assertEqual(refs['apu']['maximum'],45)

    def test_sensor_identity_survives_hwmon_renumbering(self):
        with tempfile.TemporaryDirectory() as directory:
            a=Path(directory)/'device/hwmon/hwmon2/fan1_input'
            b=Path(directory)/'device/hwmon/hwmon9/fan1_input'
            first,peak=t.fan_reference(a,8500,{}, {})
            second,_=t.fan_reference(b,2000,{}, {first['identity']:peak})
            self.assertEqual(first['identity'],second['identity'])
            self.assertEqual(second['reference_rpm'],9000)
