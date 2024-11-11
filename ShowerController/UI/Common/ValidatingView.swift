//
//  ValidatingTextField.swift
//  ShowerController
//
//  Created by Nigel Hannam on 13/11/2024.
//

import SwiftUI

struct ValidatingView<Label: View>: View {
    var validatingField: () -> Label
    var validationText: String
    var isValid: Bool
    
    var body: some View {
        VStack {
            validatingField()
            let validationTextColour: Color = isValid ? .secondary : .red
            Text(validationText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
                .foregroundStyle(validationTextColour)
        }
    }
}

#Preview {
    @Previewable @State var text = "Some Text"
    ValidatingView(
        validatingField: {
            TextField("Field Title", text: $text)
        },
        validationText: "This must validate",
        isValid: true
    )
}
