"""Reference-band configuration and driver threshold normalization."""
from pathlib import Path
import tempfile
import unittest
from test_telemetry import t

class GaugeTests(unittest.TestCase):
    def test_defaults_are_copied(self):
        first=t.power_bands({});first['apu'][0]=999
        self.assertEqual(t.power_bands({})['apu'],[30,60,90])
    def test_valid_custom_bands(self):
        self.assertEqual(t.power_bands({'power_bands_watts':{'apu':[10,20,40]}})['apu'],[10,20,40])
    def test_invalid_config_falls_back_per_domain(self):
        for values in (None,{},'30,60,90',[],[30,60],[30,30,90],[60,30,90],[-1,30,60],[True,30,60],[1,float('inf'),90],[1,float('nan'),90],[1,2,10**1000]):
            result=t.power_bands({'power_bands_watts':{'apu':values,'gpu':[5,10,15]}})
            self.assertEqual(result['apu'],[30,60,90])
            self.assertEqual(result['gpu'],[5,10,15])
    def test_invalid_config_container(self):
        self.assertEqual(t.power_bands({'power_bands_watts':None}),t.DEFAULT_POWER_BANDS)
    def test_temperature_limits_convert_units(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'temp1_input'
            p.with_name('temp1_max').write_text('80000')
            p.with_name('temp1_crit').write_text('95000')
            self.assertEqual(t.sensor_limits(p),{'high':80,'critical':95})
    def test_missing_or_sentinel_limits_remain_unknown(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'temp1_input'
            self.assertEqual(t.sensor_limits(p),{'high':None,'critical':None})
            p.with_name('temp1_max').write_text('65261850')
            p.with_name('temp1_crit').write_text('0')
            self.assertEqual(t.sensor_limits(p),{'high':None,'critical':None})
    def test_inverted_high_does_not_override_critical(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'temp1_input'
            p.with_name('temp1_max').write_text('100000')
            p.with_name('temp1_crit').write_text('95000')
            self.assertEqual(t.sensor_limits(p),{'high':None,'critical':95})

if __name__=='__main__':unittest.main()
