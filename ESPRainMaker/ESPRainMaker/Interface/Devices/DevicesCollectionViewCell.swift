// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  DevicesCollectionViewCell.swift
//  ESPRainMaker
//

import UIKit

class DevicesCollectionViewCell: UICollectionViewCell {
    @IBOutlet var bgView: UIView!
    var device: Device!
    var switchValue = false
    var switchActionButton: () -> Void = {}
    @IBOutlet var primaryValue: UILabel!
    @IBOutlet var deviceImageView: UIImageView!
    @IBOutlet var deviceName: UILabel!
    @IBOutlet var switchButton: UIButton!
    @IBOutlet var statusView: UIView!
    @IBOutlet var offlineLabel: UILabel!
    @IBAction func switchButtonPressed(_: Any) {
        switchValue = !switchValue
        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [device.primary ?? "": switchValue]])

        if switchValue {
            switchButton.setImage(UIImage(named: "switch_icon_enabled_on"), for: .normal)
        } else {
            switchButton.setImage(UIImage(named: "switch_icon_enabled_off"), for: .normal)
        }
    }

    func refresh() {
        device = nil
        switchValue = false
        primaryValue.text = ""
        deviceImageView.image = UIImage(named: "dummy_device_icon")
        deviceName.text = ""
        statusView.isHidden = true
    }
}
