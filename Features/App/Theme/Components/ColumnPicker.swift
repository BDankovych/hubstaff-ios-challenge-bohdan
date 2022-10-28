//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

public struct ColumnPicker<Value: Hashable>: View {
    public struct Column {
        public struct Option {
            public var text:  String
            public var value: Value
        }

        @Binding
        public var selection: Value
        public var label:     String
        public var options:   [Option]
    }

    public let columns: [Column]

    public var body: some View {
        HStack(spacing: .zero) {
            ForEach(Array(self.columns.enumerated()), id: \.0) { _, column in
                Picker(column.label, selection: column.$selection) {
                    ForEach(column.options, id: \.value) {
                        Text(verbatim: $0.text)
                            .font(.hsControl)
                    }
                }
                .pickerStyle(.wheel)
                .overlay(
                    Text(column.label)
                        .font(.hsControl)
                        .padding(.horizontal, .hsRelated),
                    alignment: .trailing
                )
            }
        }
    }
}

extension UIPickerView {
    // Work-around: Native UIPickerView forces excessive width.
    // Can be clipped only visually, touch area still exceeds clip boundaries.
    override open var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: super.intrinsicContentSize.height)
    }
}

#if DEBUG
struct ColumnPicker_Previews: PreviewProvider {
    static var previews: some View {
        ColumnPicker(columns: [
            .init(
                selection: .constant(0),
                label: "hrs",
                options: (0 ... 99).map { .init(text: $0.description, value: $0) }
            ),
            .init(
                selection: .constant(0),
                label: "min",
                options: (0 ... 59).map { .init(text: $0.description, value: $0) }
            ),
            .init(
                selection: .constant(0),
                label: "sec",
                options: (0 ... 59).map { .init(text: $0.description, value: $0) }
            ),
        ])
        .frame(maxWidth: .infinity)
        .previewDisplayName("Avatar")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
