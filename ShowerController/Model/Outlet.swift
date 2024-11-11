//
//  Outlet.swift
//  ShowerController
//
//  Created by Nigel Hannam on 03/11/2024.
//

import Foundation
import SwiftData

enum OutletType: Int, Codable, CaseIterable, Identifiable {
    case overhead, bath
    var id: Self { self }
}

@Model
class Outlet {
    #Unique<Outlet>([\.device, \.outletSlot])
    
    @Relationship
    var device: Device?
    
    private(set) var outletSlot: Int
    private(set) var type: OutletType
    internal var isRunning: Bool
    internal var isEnabledForWirelessRemoteButton: Bool
    
    fileprivate(set) var minimumTemperature: Double
    fileprivate(set) var maximumTemperature: Double
    fileprivate(set) var maximumDurationSeconds: Int

    var temperatureRange: ClosedRange<Double>? {
        maximumTemperature >= minimumTemperature && maximumTemperature != 0 ? minimumTemperature...maximumTemperature : nil
    }
    
    init(
        outletSlot: Int,
        type: OutletType,
        isRunning: Bool = false,
        isEnabledForWirelessRemoteButton: Bool = false,
        minimumTemperature: Double = 0,
        maximumTemperature: Double = 0,
        maximumDurationSeconds: Int = 0
    ) {
        self.outletSlot = outletSlot
        self.type = type
        self.isRunning = isRunning
        self.isEnabledForWirelessRemoteButton = isEnabledForWirelessRemoteButton
        self.minimumTemperature = minimumTemperature
        self.maximumTemperature = maximumTemperature
        self.maximumDurationSeconds = maximumDurationSeconds
    }
}

class OutletNotificationApplier: OutletNotificationVisitor {
    private let outlet: Outlet
    
    init(_ outlet: Outlet) {
        self.outlet = outlet
    }
    
    func visit(_ notification: OutletSettingsNotification) {
        outlet.minimumTemperature = notification.minimumTemperature
        outlet.maximumTemperature = notification.maximumTemperature
        outlet.maximumDurationSeconds = notification.maximumDurationSeconds
    }
}
