#if os(iOS)
import UIKit

final class LikeButtonCell: UITableViewCell {
    
    // MARK: Properties
    
    static let identifier = String(describing: LikeButtonCell.self)
    
    
    // MARK: Initialize
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = nil
        contentView.backgroundColor = nil
        textLabel?.textColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.textAlignment = .center
    }
}
#endif
