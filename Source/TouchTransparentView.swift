//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

/**
 View, that is transparent for touches except areas, used by its subviews.
 */
internal class TouchTransparentView: UIView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: subviewPoint, with: event) {
                return true
            }
        }
        return false
    }

}
