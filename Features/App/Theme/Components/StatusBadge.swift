//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Orchestration
import SwiftUI

public struct StatusBadge: View {
    public struct Model {
        public var label: String
        public var tint:  Tint
    }

    public let model: Model
    public var mode:  Mode = .pill

    public var body: some View {
        switch self.mode {
            case .pill:
                Text(self.model.label)
                    .font(.hsCaption.weight(.semibold))
                    .foregroundColor(self.model.tint.color())
                    .padding(.horizontal, .hsInternal / 2)
                    .padding(.vertical, .hsInternal / 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: .hsInternal / 2)
                            .strokeBorder(self.model.tint.color(), lineWidth: 1.5)
                    )
            case .clear:
                Text(self.model.label)
                    .font(.hsCaption)
                    .foregroundColor(self.model.tint.color())
        }
    }

    public enum Mode {
        case pill
        case clear
    }
}

#if DEBUG
struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatusBadge(model: StatusBadge.Model(label: "22%", tint: UIColor.hsOrange), mode: .pill)
            StatusBadge(model: StatusBadge.Model(label: "77%", tint: UIColor.hsGreen), mode: .clear)
        }
        .padding()
        .previewDisplayName("BadgeView")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
