//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Orchestration
import SwiftUI

public struct AvatarBadge: View {
    public var model: Avatar
    public var font:  UIFont = .hsCaption
    public var mode:  Mode   = .heavy

    public var body: some View {
        Text(self.model.moniker)
            .lineLimit(1)
            .minimumScaleFactor(0.1)
            .padding(.hsRelated / 2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: .hsBreak, minHeight: .hsBreak)
            .overlay(URLImage(request: self.model.image.flatMap { URLRequest(url: $0) }, showProgress: false, empty: { EmptyView() }))
            .modify { view in
                switch self.mode {
                    case .heavy:
                        view.foregroundColor(.white)
                            .background(self.model.tint.color())
                            .font(Font(self.font).weight(.semibold))
                    case .light:
                        view.foregroundColor(self.model.tint.color())
                            .background(self.model.tint.color(opacity: 0.2))
                            .font(Font(self.font).weight(.semibold))
                    case .label:
                        view.foregroundColor(.accentColor)
                            .background(self.model.tint.color())
                            .font(Font(self.font))
                }
            }
            .mask(Circle())
    }

    public enum Mode {
        case heavy
        case light
        case label
    }
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AvatarBadge(model: SimpleAvatar(image: nil, tint: UIColor.hsBlue, moniker: "B"))
            AvatarBadge(model: SimpleAvatar(image: nil, tint: UIColor.hsBlue, moniker: "+3"), mode: .label)
            AvatarBadge(model: SimpleAvatar(image: nil, tint: UIColor.hsBlue, moniker: "K"), font: .systemFont(ofSize: 160))
            AvatarBadge(
                model: SimpleAvatar(
                    image: URL(string: "https://bit.ly/3rmyccZ"),
                    tint: UIColor.hsGrayFill,
                    moniker: "C"
                ),
                font: .systemFont(ofSize: 80)
            )
        }
        .previewDisplayName("Avatar")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
