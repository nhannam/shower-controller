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

    private var targetTemperature: Binding<Double> {
        Binding {
            return if device.timerState == .running {
                device.targetTemperature
            } else {
                device.selectedTemperature
            }
        } set: { updatedTemperature in
            temperatureSelected(temperature: updatedTemperature)
        }
    }
    var body: some View {
        Group {
            let outlet0 = device.outlets.first(where: { $0.outletSlot == Device.outletSlot0 })
            let outlet1 = device.outlets.first(where: { $0.outletSlot == Device.outletSlot1 })
            if let outlet0 {
                HStack {
                    Spacer()
                    
                    ZStack {
                        Grid {
                            DurationText(
                                seconds: device.secondsRemaining
                            )
                            .foregroundStyle(device.timerState == .paused ? .gray : .black)
                            .frame(alignment: .top)
                            .font(.largeTitle)
                            
                            GridRow {
                                OutletButton(device: device, outlet: outlet0)

                                if let outlet1 {
                                    Spacer()
                                    OutletButton(device: device, outlet: outlet1)
                                }
                            }

                            Spacer()
                        }
                        .frame(width: 250, height: 250)

                        if let temperatureRange = outlet0.temperatureRange {
                            HStack {
                                TemperatureCirclePicker(
                                    temperature: targetTemperature,
                                    temperatureRange: temperatureRange,
                                    labelPosition: .bottom
                                )
                            }
                            .frame(width: 300, height: 300)
                        }
                    }
                    .disabled(deviceLockoutTracker.lockedOut)
                    
                    Spacer()
                }
            }
        }
        .onChange(of: device.updatesLockedOutUntil, initial: true, lockoutTimeChanged)
    }
    
    func temperatureSelected(temperature: Double) {
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.updateSelectedTemperature(
                device.id,
                targetTemperature: temperature
            )
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
        return DeviceControlsView(
            device: PreviewData.data.device
        )
    }
}
