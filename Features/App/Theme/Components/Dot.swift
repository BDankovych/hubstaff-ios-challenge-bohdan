//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

struct Dot: View {
    var tint: Color = .hsGrayControl

    var body: some View {
        Circle()
            .frame(width: .hsInternal / 2, height: .hsInternal / 2)
            .foregroundColor(self.tint)
    }
}

#if DEBUG
struct Dot_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: .hsInternal) {
            Text("59:25")
            Dot()
            Text("2 to-dos")
            Dot()
            Text("No notes")
        }
        .padding()
        .previewDisplayName("Dot")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
