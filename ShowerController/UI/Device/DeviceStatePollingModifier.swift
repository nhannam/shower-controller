//
//  DeviceStatePollingModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData
import Combine

struct DeviceStatePollingModifier: ViewModifier {
    private static let logger = LoggerFactory.logger(DeviceStatePollingModifier.self)
    private static let POLL_FREQUENCY = TimeInterval(1)

    enum PollingState { case start, awaitResponse, ok, failed }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(Toolbox.self) private var tools
    
    @State private var pollingState: PollingState = .start
    @State private var stausColour: Color = .secondary


    @State private var timer = Timer.publish(every: POLL_FREQUENCY, on: .main, in: .common).autoconnect()
    
    var deviceId: UUID
    
    func body(content: Content) -> some View {
        content
            .suspendable(
                onSuspend: stopTimer,
                onResume: startTimer
            )
            .onAppear(perform: startTimer)
            .onDisappear(perform: stopTimer)
            .onChange(of: pollingState, initial: true) {
                switch pollingState {
                case .start:
                    stausColour = .secondary
                case .awaitResponse:
                    // keep colour unchanged
                    Self.logger.debug("Awaiting response")
                case .ok:
                    stausColour = .green
                case .failed:
                    stausColour = .red
                }
            }
            .onReceive(timer) { time in
                Self.logger.debug("timer \(time)")
                maybePollState()
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    Button(
                        action: startPolling,
                        label: { Image(systemName: "antenna.radiowaves.left.and.right.circle") }
                    )
                    .tint(stausColour)
                }
            }
            .task(startPolling)
            
    }

    func startPolling() {
        pollingState = .start
    }
    
    func startTimer() {
        Self.logger.debug("timer starting")
        timer.upstream.connect().cancel()
        maybePollState()
        timer = Timer.publish(every: Self.POLL_FREQUENCY, on: .main, in: .common).autoconnect()
    }

    func stopTimer() {
        Self.logger.debug("timer stopping")
        timer.upstream.connect().cancel()
    }
    
    
    func maybePollState() {
        if (pollingState != .awaitResponse) {
            Self.logger.debug("Requesting device state")
            pollingState = .awaitResponse

            tools.submitJob {
                do {
                    try await tools.deviceService.requestState(deviceId)
                    pollingState = .ok
                } catch {
                    pollingState = .failed
                }
            }
        }
    }
}

extension View {
    func deviceStatePolling(_ deviceId: UUID) -> some View {
        modifier(
            DeviceStatePollingModifier(deviceId: deviceId)
        )
    }
}
