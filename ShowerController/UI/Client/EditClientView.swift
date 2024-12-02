//
//  EditClientView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditClientView: View {
    private static let logger = LoggerFactory.logger(EditPresetView.self)
    
    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools
    
    var client: Client?
    
    @State private var name: String = ""

    @State private var isSubmitted =  false

    private var isNameValid: Bool {
        return name.wholeMatch(of: /.{1, 30}/) != nil
    }
    
    var body: some View {
        let createRequired = client == nil
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                        if createRequired {
                            Text("Please select a name for this device")
                        } else {
                            Text("Changes to the application name will only be reflecting in new pairings")
                        }
                    }
                }
                Section {
                    ValidatingView(
                        validatingField: { TextField("Name", text: $name) },
                        validationText: "1-20 characters",
                        isValid: isNameValid
                    )
                }
            }
            .toolbar {
                if !createRequired {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { isSubmitted = true })
                        .disabled(!isNameValid)
                }
            }
            .operationInProgress(isSubmitted)
            .navigationTitle("Application")
            .navigationBarBackButtonHidden()
            .interactiveDismissDisabled(createRequired)
        }
        .task {
            if let client {
                name = client.name
            } else {
                name = UIDevice.current.name
            }
        }
        .task(id: isSubmitted) {
            if isSubmitted {
                await persist()
                isSubmitted = false
            }
        }
    }
    
    func persist() async {
        await tools.alertOnError {
            if let client {
                try await tools.clientService.updateClientName(
                    clientId: client.clientId,
                    name: name
                )
            } else {
                try await tools.clientService.createClient(name: name)
            }
            dismiss()
        }
    }
}

#Preview {
    Preview {
        return EditClientView()
    }
}

