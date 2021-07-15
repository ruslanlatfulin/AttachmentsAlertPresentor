#if os(iOS)
import UIKit

class ItemWithImage: UICollectionViewCell {
    
    static let identifier = String(describing: ItemWithImage.self)
    
    lazy var imageView: UIImageView = {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFill
        $0.maskToBounds = true
        return $0
    }(UIImageView())
    
    lazy var unselectedCircle: UIView = {
        $0.backgroundColor = .clear
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
        $0.maskToBounds = false
        return $0
    }(UIView())
    
    lazy var selectedCircle: UIView = {
        $0.backgroundColor = .clear
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
        $0.maskToBounds = false
        return $0
    }(UIView())
    
    lazy var selectedPoint: UIView = {
        $0.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        return $0
    }(UIView())
    
    fileprivate let inset: CGFloat = 8
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    fileprivate func setup() {
        backgroundColor = .clear
        
        let unselected: UIView = UIView()
        unselected.addSubview(imageView)
        unselected.addSubview(unselectedCircle)
        backgroundView = unselected
        
        let selected: UIView = UIView()
        selected.addSubview(selectedCircle)
        selected.addSubview(selectedPoint)
        selectedBackgroundView = selected
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout() {
        imageView.frame = contentView.frame
        updateAppearance(forCircle: unselectedCircle)
        updateAppearance(forCircle: selectedCircle)
        updateAppearance(forPoint: selectedPoint)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.size = size
        layout()
        return size
    }
    
    func updateAppearance(forCircle view: UIView) {
        view.frame.size = CGSize(width: 28, height: 28)
        view.frame.origin.x = imageView.bounds.width - unselectedCircle.bounds.width - inset
        view.frame.origin.y = inset
        view.circleCorner = true
    }
    
    func updateAppearance(forPoint view: UIView) {
        view.frame.size = CGSize(width: unselectedCircle.width - unselectedCircle.layer.borderWidth * 2, height: unselectedCircle.height - unselectedCircle.layer.borderWidth * 2)
        view.center = selectedCircle.center
        view.circleCorner = true
    }
}
#endif
