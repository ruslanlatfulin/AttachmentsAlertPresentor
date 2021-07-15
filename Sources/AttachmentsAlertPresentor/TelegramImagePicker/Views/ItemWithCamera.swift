//
//  ItemWithCamera.swift
//
//
//  Created by Ruslan Latfulin on 9.06.21.
//  Copyright © 2021 Ruslan Latfulin. All rights reserved.
//


#if os(iOS)
import UIKit
import AVFoundation

final class ItemWithCamera: UICollectionViewCell {
    
    var previewView: AVPreviewView = {
        let view = AVPreviewView(frame: .zero)
        view.backgroundColor = UIColor.black
        return view
    }()
    
    var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        view.image = #imageLiteral(resourceName: "button-camera").withRenderingMode(.alwaysTemplate)
        view.tintColor = .white
        return view
    }()
    
    var blurView: UIVisualEffectView?
    
    var isVisualEffectViewUsedForBlurring = false
    
    
    // MARK: View Lifecycle Methods
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView = previewView
        previewView.layer.cornerRadius = 12
        addSubview(imageView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundView = previewView
        addSubview(imageView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(origin: previewView.center, size: CGSize(width: 45, height: 45))
        imageView.center = previewView.center
        blurView?.frame = previewView.bounds
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layoutIfNeeded()
    }
}
#endif
