//
//  Outlet.swift
//  ShowerController
//
//  Created by Nigel Hannam on 03/11/2024.
//

import Foundation
import SwiftData

@Model
class Outlet {
    static let outletSlot0: Int = 0
    static let outletSlot1: Int = 1

    enum OutletType: Int, Codable, CaseIterable, Identifiable {
        case overhead, handset, bath
        var id: Self { self }
    }

    #Unique<Outlet>([\.device, \.outletSlot])
    
    @Relationship
    var device: Device?
    
    private(set) var outletSlot: Int
    private(set) var type: OutletType
    internal var isRunning: Bool
    internal var isEnabledForWirelessRemoteButton: Bool
    
    fileprivate(set) var minimumTemperature: Double
    fileprivate(set) var maximumTemperature: Double
    fileprivate(set) var thresholdTemperature: Double
    fileprivate(set) var maximumDurationSeconds: Int

    var temperatureRange: ClosedRange<Double>? {
        maximumTemperature >= minimumTemperature && maximumTemperature != 0 ? minimumTemperature...maximumTemperature : nil
    }
    
    init(
        outletSlot: Int,
        type: OutletType,
        isRunning: Bool = false,
        isEnabledForWirelessRemoteButton: Bool = false,
        maximumDurationSeconds: Int = Device.maximumPermittedDurationSeconds,
        maximumTemperature: Double = Device.permittedTemperatureRange.upperBound,
        minimumTemperature: Double = Device.permittedTemperatureRange.lowerBound,
        thresholdTemperature: Double = Device.permittedTemperatureRange.lowerBound
    ) {
        self.outletSlot = outletSlot
        self.type = type
        self.isRunning = isRunning
        self.isEnabledForWirelessRemoteButton = isEnabledForWirelessRemoteButton
        self.maximumDurationSeconds = maximumDurationSeconds
        self.maximumTemperature = maximumTemperature
        self.minimumTemperature = minimumTemperature
        self.thresholdTemperature = thresholdTemperature
    }
    
    func isMinimumTemperature(_ value: Double) -> Bool {
        minimumTemperature == value
    }
    
    func apply(outletSpec: TechnicalInformationNotification.Valve.OutletSpec) {
        guard outletSlot == outletSpec.outletSlot else {
            return
        }
        
        self.type = outletSpec.type
    }
}

class OutletNotificationApplier: OutletNotificationVisitor {
    private let outlet: Outlet
    
    init(_ outlet: Outlet) {
        self.outlet = outlet
    }
    
    func visit(_ notification: OutletSettingsNotification) {
        outlet.maximumDurationSeconds = notification.maximumDurationSeconds
        outlet.maximumTemperature = notification.maximumTemperature
        outlet.minimumTemperature = notification.minimumTemperature
        outlet.thresholdTemperature = notification.thresholdTemperature
    }
}

extension Outlet: ObservableModel {
    func observationRegistrar() -> ObservationRegistrar {
        return _$observationRegistrar
    }
}
