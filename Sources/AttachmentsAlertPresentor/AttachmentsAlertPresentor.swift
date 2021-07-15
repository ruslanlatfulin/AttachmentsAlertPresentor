#if os(iOS)

import UIKit
import AVKit
import MobileCoreServices
import Photos

class AttachmentAlertPresentor: NSObject {
    
    override init() { }
    
    convenience init(sources: [AttachmentSource] = [.photoCamera, .photoLibrary, .document], from controller: UIViewController?) {
        self.init()
        self.attachmentSources = sources
        self.viewController = controller
    }
    
    deinit {
        print("AttachmentsAlertPresentor deinit")
    }
    
    private var attachmentSources = [AttachmentSource]()
    
    var photoChooseCompletion: (([URL]) -> Void)?
    
    func chooseAttachments(photoChooseCompletion: @escaping ([URL]) -> Void) {
        self.photoChooseCompletion = photoChooseCompletion
        let alertController = UIAlertController(style: .actionSheet)
        alertController.addTelegramPicker(self, attachmentSources)
        alertController.addAction(title: "Отмена", style: .cancel)
        self.viewController?.present(alertController, animated: true, completion: nil)
    }
    
    private var viewController: UIViewController?
    
    // MARK: - Attach files methods
    
    private func openPhotoCamera(controller: UIViewController) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .denied { return }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        controller.present(imagePicker, animated: true, completion: nil)
    }
    
    private func openPhotoLibrary(controller: UIViewController, isVideoAvailable: Bool = false) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        // default mediaTypes is images only
        if (isVideoAvailable) {
            imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeMPEG4 as String, kUTTypeImage as String]
        }
        imagePicker.delegate = self
        controller.present(imagePicker, animated: true)
    }
    
    private func chooseDocument(controller: UIViewController) {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes:
                [
                    "com.microsoft.word.doc",
                    "org.openxmlformats.wordprocessingml.document",
                    "com.adobe.pdf",
                    "public.text",
                    "public.image",
                    "com.microsoft.excel.xls",
                    "org.openxmlformats.spreadsheetml.sheet",
                    "public.composite-content"
                ],
            in: .import)
        if #available(iOS 11.0, *) {
            documentPicker.allowsMultipleSelection = true
        }
        documentPicker.delegate = self
        controller.present(documentPicker, animated: true, completion: nil)
    }
    
    private func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
            return true
        }
        mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
            if let contentEditingInput = contentEditingInput {
                completionHandler(contentEditingInput.fullSizeImageURL)
            }
        })
    }
    
    private func getUrlsFromPHAssets(assets: [PHAsset], completion: @escaping ((_ urls: [URL]) -> ())) {
        var array: [URL] = []
        let group = DispatchGroup()
        for asset in assets {
            group.enter()
            self.getURL(ofPhotoWith: asset) { (url) in
                if let url = url {
                    array.append(url)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(array)
        }
    }
}

extension AttachmentAlertPresentor: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        photoChooseCompletion?(urls)
    }
}

extension AttachmentAlertPresentor: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if #available(iOS 11.0, *) {
            if let url = info[.imageURL] as? URL {
                photoChooseCompletion?([url])
            } else if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 1) {
                let manager = FileManager()
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.YYYY HH:mm"
                    let filename = dateFormatter.string(from: Date()) + ".jpeg"
                    let cachesDirectoryURL = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                    let url = cachesDirectoryURL.appendingPathComponent(filename)
                    try imageData.write(to: url)
                    photoChooseCompletion?([url])
                } catch {
                    print(error)
                }
            }
        }
        picker.dismiss(animated: true)
    }
}

extension AttachmentAlertPresentor: TelegramPickerDelegate {
    func telegramPicker(didTakePhotoAt controller: TelegramPickerViewController) {
        guard let viewController = self.viewController else { return }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
        controller.dismiss(animated: true, completion: nil)
        self.openPhotoCamera(controller: viewController)
    }
    
    func telegramPicker(didSelectPhotoAt controller: TelegramPickerViewController) {
        guard let viewController = self.viewController else { return }
        controller.dismiss(animated: true, completion: nil)
        self.openPhotoLibrary(controller: viewController)
    }
    
    func telegramPicker(didSelectDocumentAt controller: TelegramPickerViewController) {
        guard let viewController = self.viewController else { return }
        controller.dismiss(animated: true, completion: nil)
        self.chooseDocument(controller: viewController)
    }
    
    func telegramPicker(_ viewController: TelegramPickerViewController, didSelect assets: [PHAsset]) {
        viewController.dismiss(animated: true, completion: nil)
        getUrlsFromPHAssets(assets: assets) { urls in
            self.photoChooseCompletion?(urls)
        }
    }
}
#endif
