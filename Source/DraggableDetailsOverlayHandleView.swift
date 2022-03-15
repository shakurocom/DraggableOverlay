//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class DraggableDetailsOverlayHandleView: UIView {

    internal private(set) var handleView: UIView!
    internal private(set) var handleWidthConstraint: NSLayoutConstraint!
    internal private(set) var handleHeightConstraint: NSLayoutConstraint!

    internal override init(frame: CGRect) {
        fatalError("use init(frame:, handleColor: , ... ) ")
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("use init(frame:, handleColor: , ... ) ")
    }

    internal init(frame: CGRect, handleColor: UIColor, handleSize: CGSize, handleCornerRadius: CGFloat) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = true
        handleView = UIView(frame: CGRect(x: 0, y: 0, width: handleSize.width, height: handleSize.height))
        handleView.backgroundColor = handleColor
        handleView.layer.masksToBounds = true
        handleView.layer.cornerRadius = handleCornerRadius
        handleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(handleView)
        handleWidthConstraint = handleView.widthAnchor.constraint(equalToConstant: handleSize.width)
        handleWidthConstraint.isActive = true
        handleHeightConstraint = handleView.heightAnchor.constraint(equalToConstant: handleSize.height)
        handleHeightConstraint.isActive = true
        handleView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        handleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

}
