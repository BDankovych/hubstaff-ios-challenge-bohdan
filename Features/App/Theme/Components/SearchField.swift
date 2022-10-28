//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

public struct SearchField: View {
    var icon  = "magnifyingglass"
    var label = "Search"
    @Binding
    var text: String

    @FocusState
    private var isFocused: Bool

    public var body: some View {
        HStack(spacing: .zero) {
            Image(named: self.icon)
                .padding(.hsInternal)

            TextField(self.label, text: self.$text)
                .focused(self.$isFocused)
                .submitLabel(.search)
        }
        .frame(height: .hsControl)
        .background(Color.hsGrayFill)
        .cornerRadius(.hsGroup)
        .onTapGesture { self.isFocused = true }
        .onFirstAppear { self.text = "" }
    }
}

#if DEBUG
struct SearchField_Previews: View, PreviewProvider {
    static var previews = Self()

    @State
    private var text = "I am a search query"

    var body: some View {
        SearchField(text: self.$text)
            .padding()
            .previewDisplayName("Search Field")
            .previewLayout(.sizeThatFits)
            .style(.hubstaff)
    }
}
#endif
