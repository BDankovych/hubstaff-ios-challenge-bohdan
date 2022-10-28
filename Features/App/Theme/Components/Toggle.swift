//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

public extension ToggleStyle where Self == CheckboxToggleStyle {
    static var hsCheckbox: Self { Self() }
}

public struct CheckboxToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.$isOn.wrappedValue.toggle()
        } label: {
            RoundedRectangle(cornerRadius: .hsInternal / 2)
                .foregroundColor(.accentColor.opacity(configuration.isOn ? .on : .off))
                .animation(.default, value: configuration.isOn)
                .frame(width: .hsRelated, height: .hsRelated)
                .padding(.hsEdge)
                .overlay(
                    RoundedRectangle(cornerRadius: .hsInternal / 2)
                        .strokeBorder(Color.hsGrayControl)
                )

            configuration.label
                .font(.hsCaption)
                .foregroundColor(.hsPrimary)
        }
    }
}

#if DEBUG
struct Toggle_Previews: PreviewProvider, View {
    static var previews = Self()

    @State
    private var isOn = false

    var body: some View {
        Group {
            Toggle(isOn: self.$isOn) { Text("default toggle") }

            Toggle(isOn: self.$isOn) { Text("checkbox toggle") }
                .toggleStyle(.hsCheckbox)
        }
        .previewDisplayName("Toggle")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
