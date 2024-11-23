//
//  ObservableModel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 23/11/2024.
//

import Foundation
import SwiftData

protocol ObservableModel: PersistentModel {
    func observationRegistrar() -> ObservationRegistrar
}
