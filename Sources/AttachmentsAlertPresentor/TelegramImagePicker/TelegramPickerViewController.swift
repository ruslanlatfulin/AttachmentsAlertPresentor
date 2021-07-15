#if os(iOS)
import Foundation
import UIKit
import Photos
import AVFoundation

protocol TelegramPickerDelegate {
    func telegramPicker(didTakePhotoAt controller: TelegramPickerViewController)
    func telegramPicker(didSelectPhotoAt controller: TelegramPickerViewController)
    func telegramPicker(didSelectDocumentAt controller: TelegramPickerViewController)
    func telegramPicker(_ viewController: TelegramPickerViewController, didSelect assets: [PHAsset])
}

public enum TelegramAsset {
    case camera
    case asset(_ : PHAsset)
}

final class TelegramPickerViewController: UIViewController {
    
    private var selectedButtons = [ButtonType]()
    private var buttons: [ButtonType] {
        get {
            return selectedAssets.count == 0
                ? self.selectedButtons
                : [.sendPhotos(count: selectedAssets.count)]
        }
        set {
            selectedButtons = newValue
        }
    }
    
    // MARK: - UI
    
    struct UI {
        static let rowHeight: CGFloat = 58
        static let insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let minimumInteritemSpacing: CGFloat = 6
        static let minimumLineSpacing: CGFloat = 6
        static let maxHeight: CGFloat = UIScreen.main.bounds.width / 2
        static let multiplier: CGFloat = 2
    }
    
    private var preferredHeight: CGFloat {
        return UI.maxHeight / (selectedAssets.count == 0 ? UI.multiplier : 1) + UI.insets.top + UI.insets.bottom
    }
    
    private func sizeFor(asset: PHAsset) -> CGSize {
        let height: CGFloat = UI.maxHeight
        let width: CGFloat = CGFloat(Double(height) * Double(asset.pixelWidth) / Double(asset.pixelHeight))
        return CGSize(width: width, height: height)
    }
    
    private func sizeForItem(asset: PHAsset) -> CGSize {
        let size: CGSize = sizeFor(asset: asset)
        if selectedAssets.count == 0 {
            let value: CGFloat = size.height / UI.multiplier
            return CGSize(width: value, height: value)
        } else {
            return size
        }
    }
    
    // MARK: - Properties

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.contentInset = UI.insets
        collectionView.backgroundColor = .clear
        collectionView.maskToBounds = false
        collectionView.clipsToBounds = false
        collectionView.register(ItemWithPhoto.self, forCellWithReuseIdentifier: String(describing: ItemWithPhoto.self))
        collectionView.register(ItemWithCamera.self, forCellWithReuseIdentifier: String(describing: ItemWithCamera.self))
        
        return collectionView
    }()
    
    private lazy var layout: PhotoLayout = {
        let layout = PhotoLayout()
        layout.delegate = self
        layout.lineSpacing = UI.minimumLineSpacing
        return layout
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.lightGray.withAlphaComponent(0.4)
        tableView.separatorInset = .zero
        tableView.backgroundColor = nil
        tableView.bounces = false
        tableView.register(LikeButtonCell.self, forCellReuseIdentifier: LikeButtonCell.identifier)
        
        return tableView
    }()
    
    private lazy var assets = [TelegramAsset]()
    private lazy var selectedAssets = [PHAsset]()
    private var attachmentSource = [AttachmentSource]()
    
    private var captureSession = AVCaptureSession()
    private var delegate: TelegramPickerDelegate!
    
    // MARK: - Initialize
    
    required init(_ delegate: TelegramPickerDelegate, _ attachmentSource: [AttachmentSource]) {
        self.delegate = delegate
        self.attachmentSource = attachmentSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        captureSession.stopRunning()
    }
    
    override func loadView() {
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            preferredContentSize.width = UIScreen.main.bounds.width * 0.5
        }
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        
        self.attachmentSource.forEach { attachmentSource in
            switch attachmentSource {
            case .photoCamera:
                // TODO - Need fix for iPad
                if UIDevice.current.userInterfaceIdiom == .pad {
                    selectedButtons.append(.photoCamera)
                } else {
                    assets.append(.camera)
                }
            case .photoLibrary:
                selectedButtons.append(.photoLibrary)
            case .document:
                selectedButtons.append(.file)
            }
        }
        
        updatePhotos()
        
        if let device = AVCaptureDevice.default(for: .video), let cameraInput = try? AVCaptureDeviceInput(device: device) {
            self.captureSession.addInput(cameraInput)
            captureSession.startRunning()
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutSubviews()
    }
    
    func layoutSubviews() {
        self.tableView.tableHeaderView?.height = self.preferredHeight
        self.preferredContentSize.height = self.tableView.contentSize.height
    }
    
    func updatePhotos() {
        checkStatus { [unowned self] assets in
            let updatedAssets = assets.map { TelegramAsset.asset($0) }
            // TODO - Need fix for iPad
            if UIDevice.current.userInterfaceIdiom != .pad {
                self.assets.append(contentsOf: updatedAssets)
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.tableView.reloadData()
            }
        }
    }
    
    func checkStatus(completionHandler: @escaping ([PHAsset]) -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            Assets.requestAccess { [unowned self] status in
                self.checkStatus(completionHandler: completionHandler)
            }
        case .authorized, .limited:
            DispatchQueue.main.async {
                self.fetchPhotos(completionHandler: completionHandler)
            }
        case .denied, .restricted: break
        @unknown default: break
        }
    }
    
    func fetchPhotos(completionHandler: @escaping ([PHAsset]) -> ()) {
        Assets.fetch { result in
            switch result {
            case .success(let assets):
                completionHandler(assets)
            case .error: break
            }
        }
    }
    
    func action(withAsset asset: PHAsset, at indexPath: IndexPath) {
        let previousCount = selectedAssets.count
        selectedAssets.contains(asset) ? selectedAssets.remove(asset) : selectedAssets.append(asset)
        let currentCount = selectedAssets.count

        if (previousCount == 0 && currentCount > 0) || (previousCount > 0 && currentCount == 0) {
            UIView.animate(withDuration: 0.25, animations: {
                self.layout.invalidateLayout()
            }) { finished in
                self.layoutSubviews()
            }
        } else {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
        tableView.reloadData()
    }
    
    func action(for button: ButtonType) {
        switch button {
        case .photoCamera:
            delegate.telegramPicker(didTakePhotoAt: self)
        case .photoLibrary:
            delegate.telegramPicker(didSelectPhotoAt: self)
        case .file:
            delegate.telegramPicker(didSelectDocumentAt: self)
        case .sendPhotos:
            delegate.telegramPicker(self, didSelect: selectedAssets)
        }
    }
}

// MARK: - TableViewDelegate

extension TelegramPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        layout.selectedCellIndexPath = layout.selectedCellIndexPath == indexPath ? nil : indexPath
        switch assets[indexPath.item] {
        case .camera:
            delegate.telegramPicker(didTakePhotoAt: self)
        case .asset(let asset):
            action(withAsset: asset, at: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch assets[indexPath.item] {
        case .camera: break
        case .asset(let asset):
            action(withAsset: asset, at: indexPath)
        }
    }
}

// MARK: - CollectionViewDataSource

extension TelegramPickerViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch assets[indexPath.item] {
        case .camera:
            guard let item = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ItemWithCamera.self), for: indexPath) as? ItemWithCamera else { return UICollectionViewCell() }
            item.previewView.session = captureSession
            return item
        case .asset(let asset):
            guard let item = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ItemWithPhoto.self), for: indexPath) as? ItemWithPhoto else { return UICollectionViewCell() }
            
            let size = sizeFor(asset: asset)
            
            DispatchQueue.main.async {
                Assets.resolve(asset: asset, size: size) { new in
                    item.imageView.image = new
                }
            }
            return item
        }
    }
}

// MARK: - PhotoLayoutDelegate

extension TelegramPickerViewController: PhotoLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, sizeForPhotoAtIndexPath indexPath: IndexPath) -> CGSize {
        switch assets[indexPath.item] {
        case .camera:
            return CGSize(width: UI.maxHeight / UI.multiplier, height: preferredHeight)
        case .asset(let asset): return sizeForItem(asset: asset)
        }
    }
}

// MARK: - TableViewDelegate

extension TelegramPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.action(for: self.buttons[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return collectionView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        print(preferredHeight)
        return assets.isEmpty ? 0 : self.preferredHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UI.rowHeight
    }
}

// MARK: - TableViewDataSource

extension TelegramPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LikeButtonCell.identifier) as? LikeButtonCell else { return UITableViewCell() }
        cell.textLabel?.font = buttons[indexPath.row].font
        cell.textLabel?.text = buttons[indexPath.row].title
        return cell
    }
}
#endif
