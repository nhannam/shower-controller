//
//  NavigationRoute.swift
//  ShowerController
//
//  Created by Nigel Hannam on 21/11/2024.
//

import Foundation

protocol NavigationRoute: Hashable {
}

struct PairedDeviceRoute: NavigationRoute {
    let device: Device
}

enum PairedDeviceDetailsRoute: NavigationRoute {
    case presets(device: Device)
    case pairedClients(device: Device)
    case settings(device: Device)
    case technicalInformation(device: Device)
}
