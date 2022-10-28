//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

struct SegmentedControl<S: RawRepresentable & Hashable>: View where S.RawValue == String {
    let segments: [S]
    @Binding
    var selected: S

    @State
    private var segmentWidth = SegmentWidthPreference()

    var body: some View {
        if self.segments.count > 1 {
            HStack(spacing: .zero) {
                ForEach(self.segments, id: \.rawValue) { segment in
                    Button {
                        self.selected = segment
                    } label: {
                        Text(segment.rawValue)
                            .with(segment == self.selected) { view, isSelected in
                                view.fontWeight(isSelected ? .semibold : nil)
                                    .foregroundColor(isSelected ? .accentColor : .hsPrimary)
                            }
                            .geometryReader(into: SegmentWidthPreference.self) { $0.size.width }
                            .frame(minWidth: self.segmentWidth.value)
                            .padding(.horizontal, .hsRelated)
                            .frame(height: .hsBreak)
                            .contentShape(Rectangle())
                    }
                    .accessibility(identifier: "\(segment.rawValue.lowercased())_segment_button")
                    .background(Color.white.opacity(segment == self.selected ? .on : .off))
                    .animation(.default, value: self.selected)
                    .cornerRadius(.hsInternal - .hsEdge)
                }
            }
            .onPreferenceChange(into: SegmentWidthPreference.self, update: self.$segmentWidth)
            .padding(.hsEdge)
            .background(Color.hsBlueFill)
            .cornerRadius(.hsInternal)
            .buttonStyle(.plain)
        }
    }

    struct SegmentWidthPreference: MaxValuePreference {
        var value: CGFloat?
    }
}

#if DEBUG
struct SegmentControl_Previews: View, PreviewProvider {
    static var previews: some View { Self() }

    @State
    private var selected = Segment.quuxquux

    var body: some View {
        SegmentedControl(segments: Segment.allCases, selected: self.$selected)
            .previewDisplayName("SegmentControl")
            .style(.hubstaff)
    }

    private enum Segment: String, CaseIterable {
        case foo
        case bar
        case quuxquux
    }
}
#endif
