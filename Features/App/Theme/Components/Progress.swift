//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

public extension ProgressViewStyle where Self == SmallProgressViewStyle {
    static var hsSmall: Self { Self() }
}

public extension ProgressViewStyle where Self == LineProgressViewStyle {
    static var hsLine: Self { Self() }
}

public struct SmallProgressViewStyle: ProgressViewStyle {
    @State
    private var isAnimating = false

    public func makeBody(configuration: Configuration) -> some View {
        Image(named: "circle.hexagonpath.fill")
            .rotationEffect(self.isAnimating ? .degrees(360) : .zero)
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: self.isAnimating)
            .onAppear {
                OperationQueue.main.addOperation {
                    self.isAnimating = true
                }
            }
            .onDisappear {
                self.isAnimating = false
            }
    }
}

public struct LineProgressViewStyle: ProgressViewStyle {
    @State
    private var isAnimating = false

    public func makeBody(configuration: Configuration) -> some View {
        Rectangle()
            .fill(.linearGradient(
                colors: [Color.accentColor.opacity(.zero), Color.accentColor, Color.accentColor.opacity(.zero)],
                startPoint: self.isAnimating ? .center : .leading,
                endPoint: self.isAnimating ? .trailing : .center
            ))
            .frame(height: 1)
            .animation(.easeInOut(duration: 1).repeatForever(), value: self.isAnimating)
            .onAppear {
                OperationQueue.main.addOperation {
                    self.isAnimating = true
                }
            }
            .onDisappear {
                self.isAnimating = false
            }
    }
}

#if DEBUG
struct Progress_Previews: PreviewProvider, View {
    static var previews = Self()

    var body: some View {
        VStack(spacing: .hsGroup) {
            ProgressView()

            ProgressView()
                .progressViewStyle(.hsLine)

            ProgressView()
                .progressViewStyle(.hsSmall)
        }
        .previewDisplayName("Progress")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
