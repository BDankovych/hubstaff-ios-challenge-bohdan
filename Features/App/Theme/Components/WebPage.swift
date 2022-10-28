//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Orchestration
import SafariServices
import SwiftUI

struct WebPage: UIViewControllerRepresentable {
    let url:     URL
    var dismiss: ((SFSafariViewController) -> Void)?

    func makeCoordinator() -> WebDelegate {
        WebDelegate()
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        using(SFSafariViewController(url: self.url)) {
            $0.delegate = context.coordinator
        }
    }

    func updateUIViewController(_ viewController: SFSafariViewController, context: Context) {
        context.coordinator.configuration = self
    }

    class WebDelegate: NSObject, SFSafariViewControllerDelegate {
        var configuration: WebPage?

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            if let dismiss = self.configuration?.dismiss {
                dismiss(controller)
            }
            else if let navigationController = controller.navigationController {
                navigationController.popViewController(animated: true)
            }
        }
    }
}

#if DEBUG
struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebPage(url: URL(string: "https://bit.ly/3rmyccZ")!)
            .previewDisplayName("WebView")
            .previewLayout(.sizeThatFits)
            .style(.hubstaff)
    }
}
#endif
