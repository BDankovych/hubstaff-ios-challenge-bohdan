//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

// TODO: Replace with styled SwiftUI.GroupBox when upgrading to iOS 14.
struct GroupBox: View {
    var icon:        String?
    var title:       String?
    var description: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .hsInternal) {
            self.icon.flatMap {
                Image(named: $0)
                    .foregroundColor(.accentColor)
            }

            self.title.flatMap {
                Text($0)
                    .font(.hsControl)
            }

            self.description.flatMap {
                Text($0)
                    .font(.hsDetails)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .hsGroup)
        .padding(.vertical, .hsRelated)
        .overlay(
            RoundedRectangle(cornerRadius: .hsInternal)
                .strokeBorder(Color.hsGrayControl)
        )
    }
}

#if DEBUG
struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupBox(
            title: "Time & activity",
            description: "See team members' time worked, activity levels, and amounts earned per project/work order."
        )
        .padding()
        .previewDisplayName("GroupView")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
