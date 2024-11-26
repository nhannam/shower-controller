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

    @State var temperature: Double = 0
    
    var displayTemperature: Double {
        return switch device.runningState {
        case .running, .cold:
            device.targetTemperature
        case .paused, .off:
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
                    
                    let activeOutlet = device.isOutletRunning(outletSlot: Outlet.outletSlot1) ? outlet1 : outlet0
                    if let activeOutlet {
                        TemperatureCirclePicker(
                            temperature: $temperature,
                            permittedRange: activeOutlet.temperatureRange ?? Outlet.permittedTemperatureRange,
                            onEditingChanged: { editing in
                                if (!editing) {
                                    temperatureSelected(temperature: temperature)
                                }
                            }
                        )
                        
                        Group {
                            if device.getRunningStateForTemperature(temperature: temperature, outletSlot: activeOutlet.outletSlot) == .cold {
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
        DeviceControlsView(
            device: PreviewData.data.device
        )
    }
}
