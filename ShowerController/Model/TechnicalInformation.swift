//
//  TechnicalInformation.swift
//  ShowerController
//
//  Created by Nigel Hannam on 13/11/2024.
//

import SwiftUI
import SwiftData

@Model
class TechnicalInformation {
    #Unique<TechnicalInformation>([\.device])

    @Relationship
    var device: Device?

    private(set) var valveType: UInt8
    private(set) var valveSoftwareVersion: UInt8
    private(set) var uiType: UInt8
    private(set) var uiSoftwareVersion: UInt8
    private(set) var bluetoothSoftwareVersion: UInt8

    init(valveType: UInt8, valveSoftwareVersion: UInt8, uiType: UInt8, uiSoftwareVersion: UInt8, bluetoothSoftwareVersion: UInt8) {
        self.valveType = valveType
        self.valveSoftwareVersion = valveSoftwareVersion
        self.uiType = uiType
        self.uiSoftwareVersion = uiSoftwareVersion
        self.bluetoothSoftwareVersion = bluetoothSoftwareVersion
    }
}

extension TechnicalInformation: ObservableModel {
    func observationRegistrar() -> ObservationRegistrar {
        return _$observationRegistrar
    }
}
