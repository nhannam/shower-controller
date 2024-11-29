//
//  Preset.swift
//  ShowerController
//
//  Created by Nigel Hannam on 23/10/2024.
//

import Foundation
import SwiftData

@Model
class Preset {
    static let DURATION_GRANULARITY = 10

    #Unique<Preset>([\.device, \.presetSlot])
    
    @Relationship
    var device: Device?

    @Relationship
    var outlet: Outlet

    fileprivate(set) var presetSlot: UInt8
    fileprivate(set) var name: String

    fileprivate(set) var targetTemperature: Double
    fileprivate(set) var durationSeconds: Int

    init(
        presetSlot: UInt8,
        name: String,
        outlet: Outlet,
        targetTemperature: Double = Device.permittedTemperatureRange.lowerBound,
        durationSeconds: Int = Device.maximumPermittedDurationSeconds
    ) {
        self.presetSlot = presetSlot
        self.name = name
        self.outlet = outlet
        self.targetTemperature = targetTemperature
        self.durationSeconds = durationSeconds
    }
    
    func isSlot(_ presetSlot: UInt8) -> Bool {
        return self.presetSlot == presetSlot
    }
}

class PresetNotificationApplier: PresetNotificationVisitor {
    private let preset: Preset
    
    init(_ preset: Preset) {
        self.preset = preset
    }
    
    func visit(_ notification: PresetDetailsNotification) {
        preset.name = notification.name
        preset.targetTemperature = notification.targetTemperature
        preset.durationSeconds = notification.durationSeconds

        if let outlet = preset.device!.getOutletBySlot(notification.outletSlot) {
            preset.outlet = outlet
        }
    }
}

extension Preset: ObservableModel {
    func observationRegistrar() -> ObservationRegistrar {
        return _$observationRegistrar
    }
}
