"""Display discovery/control checks use synthetic KScreen state, never live hardware."""
import copy
import unittest
from test_telemetry import t


def config():
    def mode(id, hz, width=2560, height=1600):
        return dict(id=id, refreshRate=hz, size=dict(width=width, height=height))
    return {'outputs': [
        dict(id=1, name='eDP-1', connected=True, enabled=True, currentModeId='fast', scale=1.2,
             modes=[mode('slow',60),mode('fast',180),mode('duplicate',180),mode('other',120,1920,1080)]),
        dict(id=2, name='DP-1', connected=True, enabled=True, currentModeId='fractional', scale=1,
             modes=[mode('fractional',59.94),mode('integer',60),mode('high',144)]),
        dict(id=3, name='HDMI-A-1', connected=False, enabled=True, currentModeId='1', modes=[mode('1',60)])]}

class DisplayTests(unittest.TestCase):
    def test_rates_match_current_resolution_and_active_wins_duplicate(self):
        d=t.parse_displays(config())[0]
        self.assertEqual([m['hz'] for m in d['refresh_modes']],[60,180])
        self.assertEqual(d['refresh_modes'][1],dict(id='fast',hz=180,active=True))
    def test_fractional_rates_are_distinct(self):
        d=t.parse_displays(config())[1]
        self.assertEqual([m['hz'] for m in d['refresh_modes']],[59.94,60,144])
    def test_disconnected_and_disabled_outputs_filtered(self):
        c=config();c['outputs'][1]['enabled']=False
        self.assertEqual(len(t.parse_displays(c)),1)
    def test_command_targets_selected_external_output(self):
        self.assertEqual(t.display_mode_command(config(),'2','high'),['kscreen-doctor','output.2.mode.high'])
    def test_disconnected_between_render_and_click(self):
        c=config();c['outputs'][0]['connected']=False
        with self.assertRaisesRegex(ValueError,'disconnected'):t.display_mode_command(c,'1','slow')
    def test_resolution_changed_between_render_and_click(self):
        c=config();c['outputs'][0]['currentModeId']='other'
        with self.assertRaisesRegex(ValueError,'resolution'):t.display_mode_command(c,'1','slow')
    def test_reject_unknown_or_resolution_changing_mode(self):
        for mode in ['missing','other']:
            with self.assertRaises(ValueError):t.display_mode_command(config(),'1',mode)
    def test_reject_command_injection_and_kscreen_option_separators(self):
        for value in ['1;id','$(id)','1.mode.2','1 enable','1\n2',"'",'']:
            with self.assertRaises(ValueError):t.display_mode_command(config(),value,'slow')
            with self.assertRaises(ValueError):t.display_mode_command(config(),'1',value)
    def test_empty_and_unknown_current_mode(self):
        self.assertEqual(t.parse_displays({}),[])
        c=config();c['outputs'][0]['currentModeId']='missing'
        self.assertEqual(t.parse_displays(c)[0]['refresh_modes'],[])
    def test_unknown_resolution_not_offered(self):
        c=config();c['outputs'][0]['modes'][0]['size']={}
        self.assertNotIn('slow',[m['id'] for m in t.parse_displays(c)[0]['refresh_modes']])
    def test_does_not_mutate_kscreen_input(self):
        c=config();before=copy.deepcopy(c);t.parse_displays(c)
        self.assertEqual(c,before)

if __name__=='__main__':unittest.main()
