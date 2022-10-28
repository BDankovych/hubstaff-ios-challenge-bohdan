//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation
import Orchestration
import SwiftUI

public struct Header: View {
    public var icon:        String?
    public var avatar:      Avatar?
    public var title:       String?
    public var subtitle:    String?
    public var badge:       StatusBadge.Model?
    public var value:       String?
    public var action:      String?
    public var destination: (() -> AnyView?)?

    public var body: some View {
        HStack(spacing: .hsInternal) {
            self.icon.flatMap {
                Image(named: $0)
            }

            self.avatar.flatMap {
                AvatarBadge(model: $0)
            }

            self.title.flatMap {
                Text($0)
                    .font(.hsTitle)
            }

            self.subtitle.flatMap {
                Text($0)
                    .font(.hsSubtitle)
            }

            self.badge.flatMap {
                StatusBadge(model: $0)
            }

            Spacer()

            self.value.flatMap {
                Text($0)
                    .font(.hsControl)
            }

            if let destination = self.destination {
                HStack {
                    self.action.flatMap {
                        Text($0)
                            .font(.hsControl)
                    }

                    Image(named: "chevron.right")
                }
                .if(let: self.action) { view, _ in
                    view.foregroundColor(.accentColor)
                        .navigationLink(destination: destination)
                }
            }
        }
        .if(let: self.destination) { view, destination in
            view.if(self.action == nil) {
                $0.navigationLink(destination: destination)
            }
        }
    }
}

#if DEBUG
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Header(title: "Time entries")

            Header(icon: "desktopcomputer", title: "Desktop activity", action: "View all") {
                AnyView(EmptyView())
            }

            Header(
                avatar: SimpleAvatar(image: URL(string: "https://bit.ly/3rmyccZ"), tint: UIColor.hsGrayFill, moniker: "A"),
                subtitle: "Alessia Taylor",
                badge: StatusBadge.Model(label: "72%", tint: UIColor.hsGreen),
                value: "21:55"
            ) {
                AnyView(EmptyView())
            }
        }
        .previewDisplayName("Report Widget")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
