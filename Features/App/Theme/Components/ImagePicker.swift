//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Orchestration
import SwiftUI

public struct ImagePicker: UIViewControllerRepresentable {
    public var sourceType: UIImagePickerController.SourceType
    public let completion: ([UIImagePickerController.InfoKey: Any]?) -> Void

    public static func isAvailable(_ sourceType: UIImagePickerController.SourceType) -> Bool {
        UIImagePickerController.isSourceTypeAvailable(sourceType)
    }

    public func makeCoordinator() -> some UIImagePickerControllerDelegate & UINavigationControllerDelegate {
        ImageDelegate(completion: self.completion)
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        using(UIImagePickerController()) {
            $0.delegate = context.coordinator
        }
    }

    public func updateUIViewController(_ viewController: UIImagePickerController, context: Context) {
        viewController.sourceType = self.sourceType
    }

    private class ImageDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: ([UIImagePickerController.InfoKey: Any]?) -> Void

        init(completion: @escaping ([UIImagePickerController.InfoKey: Any]?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard !picker.isBeingDismissed
            else { return }

            picker.dismiss(animated: true) {
                self.completion(info)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.completion(nil)
            }
        }
    }
}

#if DEBUG
struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(sourceType: .photoLibrary, completion: { _ in })
            .previewDisplayName("ImagePicker")
            .style(.hubstaff)
    }
}
#endif
