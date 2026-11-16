import json
import re
import unittest
from pathlib import Path

CONFIGS = Path(__file__).resolve().parents[1] / "configs"


class NetworkingTests(unittest.TestCase):
    def test_connectivity_targets_match_dashboard(self):
        dashboard = json.loads(
            (CONFIGS / "grafana/dashboards/networking.json").read_text()
        )
        panels = {panel["id"]: panel for panel in dashboard["panels"]}
        alloy = (CONFIGS / "alloy/openwrt.alloy").read_text()
        self.assertNotIn("icmp_ipv6", alloy)
        self.assertNotIn("icmp_ipv6", (CONFIGS / "alloy/blackbox.yml").read_text())
        self.assertNotIn("family", json.dumps(dashboard))
        self.assertEqual(panels[2]["title"], "Internet")
        self.assertNotIn(3, panels)
        self.assertEqual(alloy.count('module  = "icmp_ipv4"'), 2)
        targets = set(re.findall(r'probe_target = "([^"]+)"', alloy))
        history = panels[9]["targets"][0]["expr"]
        expected = set(re.findall(r'"probe_target","([^"]+)"', history))
        self.assertEqual(len(targets), 4)
        self.assertEqual(targets, expected)

    def test_wan_freshness_is_checked_before_aggregation(self):
        dashboard = json.loads(
            (CONFIGS / "grafana/dashboards/networking.json").read_text()
        )
        wan = next(panel for panel in dashboard["panels"] if panel["id"] == 12)
        for target, direction in zip(
            wan["targets"], ("receive", "transmit"), strict=True
        ):
            selector = f'node_network_{direction}_bytes_total{{job="openwrt",node="$router",device="eth1"}}'
            self.assertEqual(
                target["expr"],
                f"8 * max(rate({selector}[$__rate_interval]) and (time() - timestamp({selector}) < 120))",
            )


if __name__ == "__main__":
    unittest.main()
