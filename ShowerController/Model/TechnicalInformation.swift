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

    private(set) var valveType: UInt16
    private(set) var valveSoftwareVersion: UInt16
    private(set) var uiType: UInt16
    private(set) var uiSoftwareVersion: UInt16
    private(set) var bluetoothType: UInt16
    private(set) var bluetoothSoftwareVersion: UInt16

    init(valveType: UInt16, valveSoftwareVersion: UInt16, uiType: UInt16, uiSoftwareVersion: UInt16, bluetoothType: UInt16, bluetoothSoftwareVersion: UInt16) {
        self.valveType = valveType
        self.valveSoftwareVersion = valveSoftwareVersion
        // 42 = dual shower, 44 = shower+bath
        self.uiType = uiType
        self.uiSoftwareVersion = uiSoftwareVersion
        self.bluetoothType = bluetoothType
        self.bluetoothSoftwareVersion = bluetoothSoftwareVersion
    }
}

extension TechnicalInformation: ObservableModel {
    func observationRegistrar() -> ObservationRegistrar {
        return _$observationRegistrar
    }
}
