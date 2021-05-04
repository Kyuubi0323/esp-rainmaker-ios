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
//  Node.swift
//  ESPRainMaker
//

import Foundation

class Node: Codable {
    var node_id: String?
    var config_version: String?
    var info: Info?
    var devices: [Device]?
    var attributes: [Attribute]?
    var primary: [String]?
    var secondary: [String]?
    var isConnected = true
    var timestamp: Int = 0
    var isSchedulingSupported = false
    var localNetwork = false
    var fromLocalStorage = false

    enum CodingKeys: String, CodingKey {
        case node_id = "id"
        case status
        case config
        case devices
        case config_version
        case info
        case isSchedulingSupported
        case primary
        case secondary
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(node_id, forKey: .node_id)
        try container.encode(isSchedulingSupported, forKey: .isSchedulingSupported)
        try container.encode(devices, forKey: .devices)
        try container.encode(primary, forKey: .primary)
        try container.encode(secondary, forKey: .secondary)

        var configContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        try configContainer.encode(info, forKey: .info)
        try configContainer.encode(config_version, forKey: .config_version)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        node_id = try container.decode(String?.self, forKey: .node_id)
        devices = try container.decode([Device]?.self, forKey: .devices)
        primary = try container.decode([String]?.self, forKey: .primary)
        secondary = try container.decode([String]?.self, forKey: .secondary)

        let configContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        info = try configContainer.decode(Info?.self, forKey: .info)
        config_version = try configContainer.decode(String.self, forKey: .config_version)
        timestamp = 0

        if let nodeDevices = devices {
            for device in nodeDevices {
                device.node = self
            }
        }
        isSchedulingSupported = try container.decodeIfPresent(Bool.self, forKey: .isSchedulingSupported) ?? false
        isConnected = false
        fromLocalStorage = true
    }

    func getNodeStatus() -> String {
        var status = ""
        if fromLocalStorage {
            return status
        }
        if localNetwork {
            status = "Reachable on WLAN"
        } else {
            if isConnected {
                return status
            } else {
                if timestamp == 0 {
                    status = "Offline"
                } else {
                    status = "Offline at " + timestamp.getShortDate()
                }
            }
        }

        return status
    }

    init() {}
}

struct Info: Codable {
    var name: String?
    var fw_version: String?
    var type: String?
}
