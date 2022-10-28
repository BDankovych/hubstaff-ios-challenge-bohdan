//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

/// A lazy view postpones its content's view builder until it becomes necessary.
///
/// - The content view is not used for view diffing, postponing its resolution until it becomes required for display.
/// - Parent view updates are terminated. The content is entirely responsible for its own view updates.
public struct Lazy<V: View>: View, Identifiable, Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public var id:      AnyHashable = 0
    @ViewBuilder
    public let content: () -> V

    public var body: V {
        self.content()
    }
}

#if DEBUG
struct Lazy_Previews: PreviewProvider {
    static var previews: some View {
        Tabs()
            .previewDisplayName("Lazy")
            .style(.hubstaff)
    }

    struct Tabs: View {
        @State
        var list = [Int.random(in: 0 ..< 10)]

        var body: some View {
            VStack {
                Button {
                    self.list.append(Int.random(in: 0 ..< 10))
                } label: {
                    Text("Roll")
                }
                .buttonStyle(.hsRounded(isInline: true))

                TabView {
                    Text("\(self.list as NSArray)")
                        .tabItem { Text("Current") }

                    Lazy { Text("\(self.list as NSArray)") }
                        .tabItem { Text("Lazy") }
                }
            }
        }
    }
}
#endif
