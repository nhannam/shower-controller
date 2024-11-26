//
//  DeviceControlsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct DeviceControlsView: View {
    private static let logger = LoggerFactory.logger(DeviceControlsView.self)
    
    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var deviceLockoutTracker = DeviceLockoutTracker()
    @State private var timer: Timer?

    @State private var temperature: Double = 0

    @State private var isEditingTemperature = false
    @State private var isSubmitted = false
    
    var displayTemperature: Double {
        if device.isWaterFlowing {
            device.targetTemperature
        } else {
            device.selectedTemperature
        }
    }

    var body: some View {
        HStack {
            let outlet0 = device.outlets.first(where: { $0.outletSlot == Outlet.outletSlot0 })
            let outlet1 = device.outlets.first(where: { $0.outletSlot == Outlet.outletSlot1 })
            
            Spacer()
            
            VStack {
                ZStack {
                    Grid {
                        DurationText(
                            seconds: device.secondsRemaining
                        )
                        .foregroundStyle(device.runningState == .paused ? .gray : .black)
                        .frame(alignment: .top)
                        .font(.largeTitle)
                        
                        GridRow {
                            if let outlet0 {
                                OutletButton(device: device, outlet: outlet0)
                            }

                            if let outlet1 {
                                Spacer()
                                OutletButton(device: device, outlet: outlet1)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: 250, height: 250)
                    
                    let activeOutlet = device.activeOutlet
                    if let activeOutlet {
                        TemperatureCirclePicker(
                            temperature: $temperature,
                            permittedRange: activeOutlet.temperatureRange ?? Outlet.permittedTemperatureRange,
                            onEditingChanged: { editing in
                                if (!editing) {
                                    temperatureSelected(temperature: temperature)
                                }
                                isEditingTemperature = editing
                            }
                        )
                        
                        Group {
                            var isCold: Bool {
                                if isEditingTemperature || isSubmitted || !device.isWaterFlowing {
                                    device.getRunningStateForTemperature(
                                        temperature: temperature,
                                        outlet: activeOutlet
                                    ) == .cold
                                } else {
                                    device.runningState == .cold
                                }
                            }

                            if isCold {
                                Text("Cold")
                            } else {
                                TemperatureText(temperature: temperature)
                            }
                        }
                        .font(.largeTitle)
                        .offset(y: 120)
                    }
                }
            }
            .disabled(deviceLockoutTracker.lockedOut)
            .frame(width: 300, height: 300)

            Spacer()
        }
        .onChange(of: device.updatesLockedOutUntil, initial: true, lockoutTimeChanged)
        .onChange(of: displayTemperature, initial: true) { _, newValue in
            temperature = newValue
        }
    }
    
    func temperatureSelected(temperature: Double) {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.updateSelectedTemperature(
                device.id,
                targetTemperature: temperature
            )
        } finally: {
            isSubmitted = false
        }
    }
    
    func lockoutTimeChanged(_ oldDate: Date, _ newDate: Date) {
        if let timer {
            timer.invalidate()
            self.timer = nil
        }
        deviceLockoutTracker.lockedOutUntil = newDate
        deviceLockoutTracker.updateLockedOut()
        
        let lockoutTimeRemaining = newDate.timeIntervalSinceNow
        if lockoutTimeRemaining > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: lockoutTimeRemaining, repeats: false) {_ in
                Task {
                    await deviceLockoutTracker.updateLockedOut()
                }
            }
        }
    }

}

@MainActor
@Observable
final class DeviceLockoutTracker {
    fileprivate var lockedOutUntil: Date?
    private(set) var lockedOut = false
    
    func updateLockedOut() {
        if let lockedOutUntil {
            if lockedOutUntil > Date() {
                lockedOut = true
            } else {
                lockedOut = false
            }
        } else {
            lockedOut = false
        }
    }
}

#Preview {
    Preview {
        DeviceControlsView(
            device: PreviewData.data.device
        )
    }
}
