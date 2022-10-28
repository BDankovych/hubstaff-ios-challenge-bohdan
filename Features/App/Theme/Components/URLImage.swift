//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Orchestration
import SwiftUI

struct URLImage: View {
    init(request: URLRequest?, showProgress: Bool = true) {
        self.init(request: request, showProgress: showProgress, empty: { Image(named: "exclamationmark.icloud") })
    }

    init<E: View>(request: URLRequest?, showProgress: Bool = true, @ViewBuilder empty: @escaping () -> E) {
        self.request = request
        self.showProgress = showProgress
        self.empty = { AnyView(empty()) }
    }

    private let request:      URLRequest?
    private let showProgress: Bool
    private var empty:        () -> AnyView

    @State
    private var image: UIImage?
    @State
    private var isLoading = false

    var body: some View {
        Image(uiImage: self.image ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .background(
                ZStack {
                    if self.isLoading {
                        if self.showProgress {
                            ProgressView()
                        }
                    }
                    else {
                        if self.image == nil {
                            self.empty()
                        }
                    }
                }
            )
            .onValue(of: self.request) { request in
                self.image = (request?.cachedData()).flatMap(UIImage.init(data:))

                _Concurrency.Task {
                    if let request = request, request.url?.scheme != nil {
                        self.isLoading = true
                        defer { self.isLoading = false }

                        do {
                            self.image = try await UIImage(data: request.remoteData())
                        }
                        catch {
                            inf("Unavailable image: \(request.url?.absoluteString ?? "-"), reason: \(error)")
                        }
                    }
                }
            }
    }
}

#if DEBUG
struct URLImage_Previews: PreviewProvider {
    static var previews: some View {
        URLImage(request: URLRequest(url: URL(string: "https://bit.ly/3rmyccZ")!), showProgress: true) { Color.red }
            .previewDisplayName("URLImage")
            .style(.hubstaff)
    }
}
#endif
