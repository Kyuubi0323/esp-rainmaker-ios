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
//  ScheduleSwitchTableViewCell.swift
//  ESPRainMaker
//
import UIKit

class ScheduleSwitchTableViewCell: SwitchTableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        checkButton.isHidden = false
        trailingSpaceConstraint.constant = 0
        leadingSpaceConstraint.constant = 30.0
        backView.backgroundColor = .white
        setupSelections()
    }

    @IBAction override func checkBoxPressed(_: Any) {
        if param.selected {
            toggleSwitch.isEnabled = false
            checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            param.selected = false
            device.selectedParams -= 1
        } else {
            toggleSwitch.isEnabled = true
            checkButton.setImage(UIImage(named: "selected"), for: .normal)
            param.selected = true
            device.selectedParams += 1
        }
        scheduleDelegate?.paramStateChangedat(indexPath: indexPath)
    }

    @IBAction override func switchStateChanged(_ sender: UISwitch) {
        if sender.isOn {
            controlStateLabel.text = "On"
        } else {
            controlStateLabel.text = "Off"
        }
        param.value = sender.isOn
    }
}

extension ScheduleSwitchTableViewCell: ScheduleActionAllowedProtocol {
    func setupSelections() {
        switch device.scheduleAction {
        case .allowed:
            self.alpha = 1.0
            checkButton.isEnabled = true
            toggleSwitch.isEnabled = param?.selected ?? false
        default:
            self.alpha = 0.6
            checkButton.isEnabled = false
            toggleSwitch.isEnabled = false
            scheduleDelegate?.takeScheduleNotAllowedAction(action: device.scheduleAction)
        }
    }
}
