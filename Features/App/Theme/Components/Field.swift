//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

public struct HSField<V: View>: View {
    public var label:   String
    public var icon:    String?
    @ViewBuilder
    public var content: () -> V

    public var body: some View {
        HStack(spacing: .hsRelated) {
            self.icon.flatMap {
                Image(named: $0)
                    .foregroundColor(.accentColor)
            }
            .foregroundColor(.accentColor)

            content()
                .padding(.vertical, .hsInternal)
        }
        .padding(.horizontal, .hsGroup)
        .frame(minHeight: .hsControl)
        .overlay(
            RoundedRectangle(cornerRadius: .hsInternal)
                .strokeBorder(Color.hsSecondary, lineWidth: 1)
        )
        .padding(.top, UIFont.hsCaption.lineHeight / 2)
        .overlay(
            Text(self.label)
                .font(.hsCaption)
                .foregroundColor(.hsSecondary)
                .padding(.horizontal, .hsInternal)
                .background(Color.white)
                .padding(.leading, .hsRelated),
            alignment: .topLeading
        )
    }
}

public struct HSTextField: View {
    public var label: String
    public var icon:  String

    @Binding
    public var text:        String
    public var isSecret   = false
    @State
    public var isUnmasked = false
    public var contentType: UITextContentType?

    private var autocapitalization: UITextAutocapitalizationType {
        guard let contentType = self.contentType
        else { return .sentences }

        switch contentType {
            case .postalCode, .telephoneNumber, .creditCardNumber, .oneTimeCode, .shipmentTrackingNumber, .flightNumber:
                return .allCharacters
            case .emailAddress, .URL, .username, .password, .newPassword:
                return .none
            default:
                return .words
        }
    }

    public var body: some View {
        HSField(label: self.label, icon: self.icon) {
            Group {
                if self.isSecret, !self.isUnmasked {
                    SecureField("", text: self.$text)
                }
                else {
                    TextField("", text: self.$text)
                }
            }
            .textContentType(self.contentType ?? (self.isSecret ? .password : nil))
            .disableAutocorrection(self.contentType != nil)
            .autocapitalization(self.autocapitalization)

            if self.isSecret {
                Button {
                    self.isUnmasked.toggle()
                } label: {
                    Image(named: self.isUnmasked ? "eye" : "eye.slash")
                }
            }
        }
    }
}

#if DEBUG
struct TextField_Previews: PreviewProvider {
    @State static var text = "some text"

    static var previews: some View {
        Group {
            HSField(label: "picker", icon: "globe") {
                Picker("pick something", selection: Self.$text) {
                    Text("some text")
                    Text("some other text")
                }
            }
            .previewDisplayName("Field, Picker")
            HSTextField(label: "regular text", icon: "envelope", text: Self.$text)
                .previewDisplayName("TextField")
            HSTextField(label: "secret text", icon: "lock", text: Self.$text, isSecret: true)
                .previewDisplayName("TextField")
        }
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
