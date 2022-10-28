//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import CoreGraphics

extension CGRect {
    init(center: CGPoint, radius: CGFloat) {
        self = .init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}
