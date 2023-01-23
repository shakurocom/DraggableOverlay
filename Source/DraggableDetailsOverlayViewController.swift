//
// Copyright (c) 2022 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit
import Shakuro_CommonTypes

/// Delegate of the draggable overlay. The one whole controls it.
public protocol DraggableDetailsOverlayViewControllerDelegate: AnyObject {

    /// An array of anchors, that overlay will use for snapping. Anchors pointing to effectively the same point will be reduced to singular anchor.
    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor]

    /// Amount of background from the top, that overlay is not allowed to cover.
    /// Return 0 to be able to cover every available space.
    func draggableDetailsOverlayTopInset(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat

    /// Maximum height of overlay.
    /// Return `nil` if height should not be limited.
    func draggableDetailsOverlayMaxHeight(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat?

    /// This will also be reported, when user draggs overlay beyond allowed anchors (and overlay do not actually moves).
    func draggableDetailsOverlayDidDrag(_ overlay: DraggableDetailsOverlayViewController)

    /// Content's scroll will still be prevented for another runloop.
    func draggableDetailsOverlayDidEndDragging(_ overlay: DraggableDetailsOverlayViewController)

    /// Called on automatic and manual invoke of `show()` & `hide()`.
    func draggableDetailsOverlayDidChangeIsVisible(_ overlay: DraggableDetailsOverlayViewController)

    /// Called when layout (constraints for overlay position, etc... ) finished changing
    func draggableDetailsOverlayDidUpdatedLayout(_ overlay: DraggableDetailsOverlayViewController)

    /// Called just before overlay will hide because of dragging it to "off screen" position
    func draggableDetailsOverlayWillDragOffScreenToHide(_ overlay: DraggableDetailsOverlayViewController)

    /// Called just after overlay did hide because of tapping on shadow  view
    func draggableDetailsOverlayDidHideByShadowTap(_ overlay: DraggableDetailsOverlayViewController)

    /// Will be called only if `isSnapToAnchorsEnabled` is set to `true`.
    /// Will be called after user ends drag gesture and before animation to nearest anchor.
    func draggableDetailsOverlay(_ overlay: DraggableDetailsOverlayViewController,
                                 willAnimateEndDragToNearestAnchor anchor: DraggableDetailsOverlayViewController.Anchor)

}

/// Interface for controller, that will be displayed inside draggable overlay.
/// Content's layout notes:
/// - height of container for content is dynamic and will change with drag.
/// - minimum height is 0
/// - priority of container's bottom constraint is 999
public protocol DraggableDetailsOverlayNestedInterface {
    /// - parameter requirePreventOfScroll: `true` indicates that overlay is currently dragging.
    /// Nested controller should prevent any content scrolling.
    /// For better UX scrolling indicators should be disabled as well.
    /// methods to be aware of are:
    /// 1) func scrollViewDidScroll(_:) - keep offset at saved value
    /// 2) func scrollViewWillEndDragging(_:,withVelocity:,targetContentOffset:) - set targetContentOffset.pointee to saved offset
    func draggableDetailsOverlay(_ overlay: DraggableDetailsOverlayViewController, requirePreventOfScroll: Bool)
    func draggableDetailsOverlayContentScrollViews(_ overlay: DraggableDetailsOverlayViewController) -> [UIScrollView]
}

/// Overlay that can be dragged to cover more or less of available space.
/// Can be configured to be "twitter-like". With limited content height.
public class DraggableDetailsOverlayViewController: UIViewController {

    public typealias NestedController = UIViewController & DraggableDetailsOverlayNestedInterface

    /// Anchor points for resting positions of overlay.
    /// Anchors will be cached.
    /// Anchors pointing effectively to the same position on screen will be collapsed into single anchor.
    /// Tags are used for identification of anchors. Strictly by user. Please use positive numbers.
    /// Tags will be combined in case of collapsing of anchors.
    /// Default tag has tag of `-1`.
    public struct Anchor: Equatable {

        public static let defaultAnchor: Anchor = Anchor(topOffset: 0, tag: -1)

        public let tags: [Int]
        internal let isFromTop: Bool // used only as input value before caching
        internal let value: CGFloat

        /// Anchor point described as an offset for top of the `DraggableDetailsOverlayViewController.view`.
        public init(topOffset: CGFloat, tag: Int) {
            tags = [tag]
            isFromTop = true
            value = topOffset
        }

        /// Anchor point described as visible height of overlay.
        public init(height: CGFloat, tag: Int) {
            tags = [tag]
            isFromTop = false
            value = height
        }

        internal init(topOffset: CGFloat, tags: [Int]) {
            self.tags = tags
            isFromTop = true
            value = topOffset
        }

    }

    private enum Constant {
        static let hiddenContainerOffset: CGFloat = 10
        /// Anchors will be considered equal if they separated by no more than this amount of points.
        static let anchorsCachingGranularity: CGFloat = 1.0
    }

    /// Is on/off screen?
    /// Changes at the start of show() and at the end of hide().
    public private(set) var isVisible: Bool = false {
        didSet {
            if oldValue != isVisible {
                delegate?.draggableDetailsOverlayDidChangeIsVisible(self)
            }
        }
    }

    /// Enable shadow background.
    /// Shadow will block interaction with everything underneath.
    /// Default value is `true`.
    public var isShadowEnabled: Bool = true {
        didSet {
            guard isViewLoaded else { return }
            shadowBackgroundView.isHidden = !isShadowEnabled
        }
    }

    /// Enable/disable overlay close on shadow tap.
    /// Default value is `false`.
    public var isTapOnShadowToCloseEnabled: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            shadowTapGestureRecognizer.isEnabled = isTapOnShadowToCloseEnabled
        }
    }

    /// Enable shadow (blurred thingy) around averlay.
    /// Default value is `false`.
    public var isContainerShadowEnabled: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            if isContainerShadowEnabled {
                addContainerShadow()
            } else {
                removeContainerShadow()
            }
        }
    }

    public var shadowBackgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) {
        didSet {
            guard isViewLoaded else { return }
            shadowBackgroundView.backgroundColor = shadowBackgroundColor
        }
    }

    public var draggableContainerBackgroundColor: UIColor = UIColor.white {
        didSet {
            guard isViewLoaded else { return }
            draggableContainerView.backgroundColor = draggableContainerBackgroundColor
        }
    }

    public var draggableContainerTopCornersRadius: CGFloat = 5 {
        didSet {
            guard isViewLoaded else { return }
            draggableContainerView.layer.cornerRadius = draggableContainerTopCornersRadius
            draggableContainerBottomConstraint.constant = draggableContainerTopCornersRadius
            contentContainerBottomConstraint.constant = -draggableContainerTopCornersRadius
        }
    }

    /// Container for drag-handle.
    /// Handle is centered here.
    /// Use 0 to hide handle.
    /// Default value is `16`.
    public var handleContainerHeight: CGFloat = 16 {
        didSet {
            guard isViewLoaded else { return }
            handleHeightConstraint.constant = handleContainerHeight
        }
    }

    /// Color of drag-handle.
    /// Default value is `UIColor.lightGray`.
    public var handleColor: UIColor = UIColor.lightGray {
        didSet {
            guard isViewLoaded else { return }
            handleView.handleView.backgroundColor = handleColor
        }
    }

    /// Size of drag-handle element.
    /// Default value is `36 x 4`.
    public var handleSize: CGSize = CGSize(width: 36, height: 4) {
        didSet {
            guard isViewLoaded else { return }
            handleView.handleWidthConstraint.constant = handleSize.width
            handleView.handleHeightConstraint.constant = handleSize.height
        }
    }

    /// Corner radius value for drag-handle element.
    /// Independent of it's height.
    /// Default value is `2`.
    public var handleCornerRadius: CGFloat = 2 {
        didSet {
            guard isViewLoaded else { return }
            handleView.handleView.layer.cornerRadius = handleCornerRadius
        }
    }

    /// Animation duration for `show()` & `hide()` & `updateLayout(animated:)`.
    /// Default value is `0.25`.
    public var showHideAnimationDuration: TimeInterval = 0.25

    /// If enabled - overlay will be snap-animated to nearest anchor.
    /// Affects drag and show().
    /// Default value `true`.
    public var isSnapToAnchorsEnabled: Bool = true

    /// If enabled, user can drag overlay below bottom
    /// Default value `false`.
    public var isDragOffScreenToHideEnabled: Bool = false

    /// If enabled - user can over-drag overlay beyond most periferal anchors.
    /// Over-drag is affected by `bounceDragDumpening`.
    /// Default value is `false`.
    public var isBounceEnabled: Bool = false

    /// How much harder it is to over-drag (comparing to normal drag).
    /// Default value is `0.5`.
    public var bounceDragDumpening: CGFloat = 0.5

    /// If `false` - snapping anchor will be calculated from current position of overlay.
    /// If `true` - current position + touch velocity will be used.
    /// Default value is `true`.
    public var snapCalculationUsesDeceleration: Bool = true

    /// If `false` - When user releases touch with some velocity,
    /// decelerating behaviour can't snap to anchors other then current or immediate next/previous one.
    /// Default value is `true`.
    public var snapCalculationDecelerationCanSkipNextAnchor: Bool = true

    /// Deceleartion rate used for calculation of snap anchors.
    /// Default value is `UIScrollView.DecelerationRate.normal`
    public var snapCalculationDecelerationRate: UIScrollView.DecelerationRate = .normal

    /// Duration of animation used, when user releases finger during drag.
    /// Default value is `0.2`.
    public var snapAnimationNormalDuration: TimeInterval = 0.2

    /// Use spring animation for snapping to anchors.
    /// Spring is not used in `show()`.
    /// Default value is `true`.
    public var snapAnimationUseSpring: Bool = true

    /// Same as `snapAnimationUseSpring`, but explicitly for top anchor.
    /// Default value is `false`.
    public var snapAnimationTopAnchorUseSpring: Bool = false

    /// Duration of animation used, when user releases finger during drag and container snaps to anchor.
    /// Default value is `0.4`.
    public var snapAnimationSpringDuration: TimeInterval = 0.4

    /// Parameter of spring animation (if enabled).
    /// Default value is `0.7`.
    public var snapAnimationSpringDamping: CGFloat = 0.7

    /// Parameter of spring animation (if enabled).
    /// Default value is `1.5`.
    public var snapAnimationSpringInitialVelocity: CGFloat = 1.5

    /// If enabled horizontal-ish drags will not activate drag of the overlay.
    /// Should be disabled if content
    /// Default value is `false`.
    public var allowHorizontalContentScrolling: Bool = false

    public var handleViewAccessibilityTitle: String?
    public var handleViewAccessibilitySubtitle: String?
    public var handleViewAccessibilityMaximizedTitle: String?
    public var handleViewAccessibilityMinimizedTitle: String?
    public var handleViewAccessibilityCollapseTitle: String?
    public var handleViewAccessibilityExpandTitle: String?
    public var handleViewAccessibilityHideTitle: String?

    private var shadowBackgroundView: UIView!
    private var draggableContainerView: UIView!
    private var draggableContainerHiddenTopConstraint: NSLayoutConstraint!
    private var draggableContainerShownTopConstraint: NSLayoutConstraint!
    private var draggableContainerBottomConstraint: NSLayoutConstraint!
    private var contentContainerView: UIView!
    private var contentContainerBottomConstraint: NSLayoutConstraint!
    private var handleView: DraggableDetailsOverlayHandleView!
    private var handleHeightConstraint: NSLayoutConstraint!
    private var dragGestureRecognizer: UIPanGestureRecognizer!
    private var shadowTapGestureRecognizer: UITapGestureRecognizer!

    private let nestedController: NestedController
    private weak var delegate: DraggableDetailsOverlayViewControllerDelegate?

    private var anchors: [Anchor] = []
    /// Sorted top->bottom (lowest->highest).
    private var cachedAnchors: [Anchor] = [Anchor.defaultAnchor]
    private var screenBottomOffset: CGFloat = 0
    /// Height for which offsets/heights were cached/calculated.
    private var layoutCalculatedForHeight: CGFloat = 0

    /// Scroll view from nested content, where pan started.
    /// Downward drag is disabled if this scroll is not at the top of it's content.
    private var currentPanStartingContentScrollView: UIScrollView?

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not allowed. Use init(style:)")
    }

    public init(nestedController: NestedController, delegate: DraggableDetailsOverlayViewControllerDelegate) {
        self.nestedController = nestedController
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    public override func loadView() {
        // some solid frame to operate with constraints
        let mainView = TouchTransparentView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        mainView.backgroundColor = UIColor.clear
        mainView.clipsToBounds = true
        view = mainView

        updateAnchors()

        setupShadowBackgroundView()
        setupDraggableContainer()
        setupHandle()
        if isContainerShadowEnabled {
            addContainerShadow()
        }
        setupContentContainer()
        setupPanRecognizer()
        setupTapRecognizer()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(nestedController, notifyAboutAppearanceTransition: false, targetContainerView: contentContainerView)

        setupAccessibility()
    }

    public override var childForStatusBarStyle: UIViewController? {
        return nestedController
    }

    // MARK: - Events

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout(animated: false, forced: false)
    }

    // MARK: - Public

    /// Affected by `isSnapToAnchorsEnabled`.
    public func show(initialAnchor: Anchor, animated: Bool, completion: (() -> Void)? = nil) {
        setVisible(true, animated: animated, initialAnchor: initialAnchor, completion: completion)
        setupAccessibility()
    }

    public func hide(animated: Bool, completion: (() -> Void)? = nil) {
        setVisible(false, animated: animated, initialAnchor: Anchor.defaultAnchor, completion: completion)
    }

    public func updateLayout(animated: Bool) {
        updateLayout(animated: animated, forced: true)
    }

    /// Current vertical space between allowed area's top and draggable container's top.
    /// - return's nil if view is not loaded or if overlay is hidden.
    public func currentTopOffset() -> CGFloat? {
        guard isViewLoaded, isVisible else {
            return nil
        }
        return draggableContainerShownTopConstraint.constant
    }

}

// MARK: - UIGestureRecognizerDelegate

extension DraggableDetailsOverlayViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !view.isHidden else {
            return false
        }
        if gestureRecognizer === dragGestureRecognizer, let view = gestureRecognizer.view, allowHorizontalContentScrolling {
            let translation = dragGestureRecognizer.translation(in: view)
            return abs(translation.x) <= abs(translation.y)
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === dragGestureRecognizer || otherGestureRecognizer === dragGestureRecognizer {
            return true
        }
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === dragGestureRecognizer,
            !view.isHidden,
            isShadowEnabled || draggableContainerView.frame.contains(touch.location(in: view))
            else {
                return false
        }
        return true
    }

}

// MARK: - Interface Callbacks

private extension DraggableDetailsOverlayViewController {

    @objc private func handleDragGesture(_ recognizer: UIGestureRecognizer) {
        guard recognizer === dragGestureRecognizer, !view.isHidden else {
            return
        }
        let translationY = dragGestureRecognizer.translation(in: dragGestureRecognizer.view).y
        let velocity = dragGestureRecognizer.velocity(in: dragGestureRecognizer.view)
        dragGestureRecognizer.setTranslation(CGPoint.zero, in: dragGestureRecognizer.view)
        switch recognizer.state {
        case .possible:
            break

        case .began:
            let contentScrollViews = nestedController.draggableDetailsOverlayContentScrollViews(self)
            currentPanStartingContentScrollView = contentScrollViews.first(where: { (scroll) -> Bool in
                let touchLocation = dragGestureRecognizer.location(in: scroll.superview)
                return scroll.frame.contains(touchLocation)
            })
            setPreventContentScroll(true)

        case .changed:
            if isContentScrollAtTop(contentScrollView: currentPanStartingContentScrollView) || translationY < 0 {
                let newOffset = draggableContainerShownTopConstraint.constant + translationY
                let maxOffset = cachedAnchors.last?.value ?? 0
                let minOffset = cachedAnchors.first?.value ?? 0
                let newShadowAlpha: CGFloat
                if newOffset < minOffset {
                    if isBounceEnabled {
                        let dumpenedNewOffset = draggableContainerShownTopConstraint.constant + translationY * bounceDragDumpening
                        draggableContainerShownTopConstraint.constant = dumpenedNewOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(true)
                    } else {
                        draggableContainerShownTopConstraint.constant = minOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(false)
                    }
                } else if minOffset <= newOffset && newOffset <= maxOffset {
                    draggableContainerShownTopConstraint.constant = newOffset
                    newShadowAlpha = 1.0
                    setPreventContentScroll(true)
                } else { // newOffset > maxOffset
                    if isDragOffScreenToHideEnabled {
                        draggableContainerShownTopConstraint.constant = newOffset
                        newShadowAlpha = CGFloat.maximum((screenBottomOffset - newOffset) / (screenBottomOffset - maxOffset), 0.0)
                        setPreventContentScroll(true)
                    } else if isBounceEnabled {
                        let dumpenedNewOffset = draggableContainerShownTopConstraint.constant + translationY * bounceDragDumpening
                        draggableContainerShownTopConstraint.constant = dumpenedNewOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(true)
                    } else {
                        draggableContainerShownTopConstraint.constant = maxOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(false)
                    }
                }
                if isShadowEnabled {
                    shadowBackgroundView.alpha = newShadowAlpha
                }
                delegate?.draggableDetailsOverlayDidDrag(self)
            } else {
                setPreventContentScroll(false)
            }

        case .ended,
             .cancelled,
             .failed:
            let currentOffset = draggableContainerShownTopConstraint.constant
            if isSnapToAnchorsEnabled {
                let restAnchor: Anchor
                let shouldHide: Bool
                if snapCalculationUsesDeceleration {
                    let deceleratedOffset = DecelerationHelper.project(
                        value: currentOffset,
                        initialVelocity: velocity.y / 1000.0, /* because this should be in milliseconds */
                        decelerationRate: snapCalculationDecelerationRate.rawValue)
                    if snapCalculationDecelerationCanSkipNextAnchor {
                        let temp = closestAnchor(targetOffset: deceleratedOffset)
                        restAnchor = temp.anchor
                        shouldHide = temp.shouldHide
                    } else {
                        let temp = closestAnchor(targetOffset: deceleratedOffset, currentOffset: currentOffset)
                        restAnchor = temp.anchor
                        shouldHide = temp.shouldHide
                    }
                } else {
                    let temp = closestAnchor(targetOffset: currentOffset)
                    restAnchor = temp.anchor
                    shouldHide = temp.shouldHide
                }
                let isContentScrollAtTop = self.isContentScrollAtTop(contentScrollView: currentPanStartingContentScrollView)
                if isDragOffScreenToHideEnabled && shouldHide && isContentScrollAtTop {
                    delegate?.draggableDetailsOverlayWillDragOffScreenToHide(self)
                    hide(animated: currentOffset < screenBottomOffset)
                } else {
                    delegate?.draggableDetailsOverlay(self, willAnimateEndDragToNearestAnchor: restAnchor)
                    if currentOffset != restAnchor.value && (velocity.y <= 0 || (velocity.y > 0 && isContentScrollAtTop)) {
                        let isSpring = restAnchor == cachedAnchors.first ? snapAnimationTopAnchorUseSpring : snapAnimationUseSpring
                        animateToOffset(restAnchor.value, isSpring: isSpring, completion: nil)
                    }
                }
            } else if isDragOffScreenToHideEnabled && currentOffset >= screenBottomOffset {
                delegate?.draggableDetailsOverlayWillDragOffScreenToHide(self)
                hide(animated: false)
            }
            currentPanStartingContentScrollView = nil
            DispatchQueue.main.async(execute: { // to prevent deceleration behaviour in content's scroll
                self.setPreventContentScroll(false)
            })
            delegate?.draggableDetailsOverlayDidEndDragging(self)

        @unknown default:
            break
        }
    }

    @objc private func handleShadowTapGesture() {
        hide(animated: true, completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.draggableDetailsOverlayDidHideByShadowTap(strongSelf)
        })
    }

    @objc private func collapseButtonPressed() -> Bool {
        return performAccessibilityAction(isCollapse: true)
    }

    @objc private func expandButtonPressed() -> Bool {
        return performAccessibilityAction(isCollapse: false)
    }

    @objc private func hideButtonPressed() -> Bool {
        hide(animated: true)
        return true
    }

}

// MARK: - Private

private extension DraggableDetailsOverlayViewController {

    private func setupShadowBackgroundView() {
        shadowBackgroundView = UIView(frame: view.bounds)
        shadowBackgroundView.backgroundColor = shadowBackgroundColor
        shadowBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shadowBackgroundView)
        shadowBackgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        shadowBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        shadowBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        shadowBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        shadowBackgroundView.isHidden = !isShadowEnabled
        shadowBackgroundView.alpha = 0.0
    }

    private func setupDraggableContainer() {
        draggableContainerView = UIView(frame: view.bounds)
        draggableContainerView.backgroundColor = draggableContainerBackgroundColor
        draggableContainerView.layer.masksToBounds = true
        draggableContainerView.layer.cornerRadius = draggableContainerTopCornersRadius
        draggableContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(draggableContainerView)
        if #available(iOS 11.0, *) {
            draggableContainerShownTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            draggableContainerHiddenTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                                constant: Constant.hiddenContainerOffset)
        } else {
            draggableContainerShownTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
            draggableContainerHiddenTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                                constant: Constant.hiddenContainerOffset)
        }
        draggableContainerShownTopConstraint.isActive = false
        draggableContainerHiddenTopConstraint.isActive = true
        draggableContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        draggableContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        draggableContainerBottomConstraint = draggableContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                            constant: draggableContainerTopCornersRadius)
        draggableContainerBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        draggableContainerBottomConstraint.isActive = true
    }

    private func setupHandle() {
        handleView = DraggableDetailsOverlayHandleView(
            frame: CGRect(x: 0, y: 0, width: draggableContainerView.bounds.width, height: handleContainerHeight),
            handleColor: handleColor,
            handleSize: handleSize,
            handleCornerRadius: handleCornerRadius)
        handleView.translatesAutoresizingMaskIntoConstraints = false
        draggableContainerView.addSubview(handleView)
        handleView.leadingAnchor.constraint(equalTo: draggableContainerView.leadingAnchor).isActive = true
        handleView.trailingAnchor.constraint(equalTo: draggableContainerView.trailingAnchor).isActive = true
        handleView.topAnchor.constraint(equalTo: draggableContainerView.topAnchor).isActive = true
        handleHeightConstraint = handleView.heightAnchor.constraint(equalToConstant: handleContainerHeight)
        handleHeightConstraint.isActive = true
    }

    private func addContainerShadow() {
        let layer = draggableContainerView.layer
        layer.masksToBounds = false
        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize()
        layer.shadowRadius = 6
    }

    private func removeContainerShadow() {
        let layer = draggableContainerView.layer
        layer.shadowColor = UIColor.clear.cgColor
    }

    private func setupContentContainer() {
        contentContainerView = UIView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: draggableContainerView.bounds.width,
                                                    height: draggableContainerView.bounds.height - handleContainerHeight))
        contentContainerView.backgroundColor = UIColor.clear
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        draggableContainerView.addSubview(contentContainerView)
        contentContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        contentContainerView.leadingAnchor.constraint(equalTo: draggableContainerView.leadingAnchor).isActive = true
        contentContainerView.trailingAnchor.constraint(equalTo: draggableContainerView.trailingAnchor).isActive = true
        contentContainerView.topAnchor.constraint(equalTo: handleView.bottomAnchor).isActive = true
        contentContainerBottomConstraint = contentContainerView.bottomAnchor.constraint(equalTo: draggableContainerView.bottomAnchor,
                                                                                        constant: -draggableContainerTopCornersRadius)
        contentContainerBottomConstraint.isActive = true
    }

    private func setupPanRecognizer() {
        dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragGesture))
        dragGestureRecognizer.delegate = self
        dragGestureRecognizer.isEnabled = true
        view.addGestureRecognizer(dragGestureRecognizer)
    }

    private func setupTapRecognizer() {
        shadowTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShadowTapGesture))
        shadowTapGestureRecognizer.isEnabled = isTapOnShadowToCloseEnabled
        shadowBackgroundView.addGestureRecognizer(shadowTapGestureRecognizer)
    }

    private func updateAnchors() {
        struct TempAnchor {
            internal let offset: CGFloat
            internal var tags: [Int]
        }
        anchors = delegate?.draggableDetailsOverlayAnchors(self) ?? [Anchor.defaultAnchor]
        let topInset = calculateTopInset()
        var newAnchors: [TempAnchor] = []
        screenBottomOffset = view.bounds.height
        for anchor in anchors {
            let offset = offsetForAnchor(anchor, topInset: topInset)
            if !isOffsetsEqual(screenBottomOffset, offset) {
                // ignore very small steps
                if let index = newAnchors.firstIndex(where: { isOffsetsEqual($0.offset, offset) }) {
                    newAnchors[index].tags.append(contentsOf: anchor.tags)
                } else {
                    newAnchors.append(TempAnchor(offset: offset, tags: anchor.tags))
                }
            }
        }
        cachedAnchors = newAnchors.sorted(by: { $0.offset < $1.offset }).map({ Anchor(topOffset: $0.offset, tags: $0.tags) })

        setupAccessibility()
    }

    private func offsetForAnchor(_ anchor: Anchor, topInset: CGFloat) -> CGFloat {
        if anchor.isFromTop {
            return min(view.bounds.height, max(anchor.value, topInset))
        } else {
            let inset = view.bounds.height - anchor.value - topSafeAreaInset() - bottomSafeAreaInset()
            return min(view.bounds.height, max(topInset, inset))
        }
    }

    /// Calculates closest anchor regardless of current position.
    private func closestAnchor(targetOffset: CGFloat) -> (anchor: Anchor, shouldHide: Bool) {
        let closestAnchorTemp = cachedAnchors.min(by: { return abs($0.value - targetOffset) < abs($1.value - targetOffset) })
        let closestAnchor = closestAnchorTemp ?? Anchor.defaultAnchor
        let shouldHide = abs(closestAnchor.value - targetOffset) > abs(screenBottomOffset - targetOffset)
        return (closestAnchor, shouldHide)
    }

    /// Calculates closes anchor from current position (current or next or previous).
    private func closestAnchor(targetOffset: CGFloat, currentOffset: CGFloat) -> (anchor: Anchor, shouldHide: Bool) {
        let currentAnchor = cachedAnchors.first(where: { isOffsetsEqual($0.value, currentOffset) })
        let nextAnchor: Anchor?
        let previousAnchor: Anchor?
        if let realCurrentAnchor = currentAnchor {
            nextAnchor = cachedAnchors.first(where: { $0.value > realCurrentAnchor.value })
            previousAnchor = cachedAnchors.last(where: { $0.value < realCurrentAnchor.value })
        } else {
            nextAnchor = cachedAnchors.first(where: { $0.value > currentOffset })
            previousAnchor = cachedAnchors.last(where: { $0.value < currentOffset })
        }
        let anchors = [previousAnchor, currentAnchor, nextAnchor].compactMap({ $0 })
        let closestAnchor = anchors.min(by: { return abs($0.value - targetOffset) < abs($1.value - targetOffset) }) ?? Anchor.defaultAnchor
        let shouldHide = abs(closestAnchor.value - targetOffset) > abs(screenBottomOffset - targetOffset)
        return (closestAnchor, shouldHide)
    }

    private func topSafeAreaInset() -> CGFloat {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets.top
        } else {
            return topLayoutGuide.length
        }
    }

    private func bottomSafeAreaInset() -> CGFloat {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets.bottom
        } else {
            return bottomLayoutGuide.length
        }
    }

    private func calculateTopInset() -> CGFloat {
        let topInsetFromMaxHeight: CGFloat
        if let maxHeight = delegate?.draggableDetailsOverlayMaxHeight(self) {
            topInsetFromMaxHeight = max(0, view.bounds.height - maxHeight)
        } else {
            topInsetFromMaxHeight = 0
        }
        return max(topInsetFromMaxHeight, delegate?.draggableDetailsOverlayTopInset(self) ?? 0)
    }

    private func isOffsetsEqual(_ left: CGFloat, _ right: CGFloat) -> Bool {
        return abs(left - right) < Constant.anchorsCachingGranularity
    }

    private func updateLayout(animated: Bool, forced: Bool) {
        guard view.bounds.height != layoutCalculatedForHeight || forced else {
            return
        }
        updateAnchors()
        layoutCalculatedForHeight = view.bounds.height
        guard isVisible else {
            return
        }
        let newCurrentOffset = closestAnchor(targetOffset: draggableContainerShownTopConstraint.constant).anchor.value
        guard newCurrentOffset != draggableContainerShownTopConstraint.constant else {
            delegate?.draggableDetailsOverlayDidUpdatedLayout(self)
            return
        }
        if animated {
            animateToOffset(newCurrentOffset, isSpring: false, completion: {
                self.delegate?.draggableDetailsOverlayDidUpdatedLayout(self)
            })
        } else {
            draggableContainerShownTopConstraint.constant = newCurrentOffset
            view.layoutIfNeeded()
            delegate?.draggableDetailsOverlayDidUpdatedLayout(self)
        }
    }

    private func setVisible(_ newVisible: Bool, animated: Bool, initialAnchor: Anchor, completion: (() -> Void)? = nil) {
        let initialOffset: CGFloat
        if newVisible {
            isVisible = true
            updateLayout(animated: false, forced: true)
            view.isHidden = false
            let topInset = calculateTopInset()
            let wantedOffset = offsetForAnchor(initialAnchor, topInset: topInset)
            initialOffset = isSnapToAnchorsEnabled ? closestAnchor(targetOffset: wantedOffset).anchor.value : wantedOffset
        } else {
            initialOffset = 0
        }
        let animations = { () -> Void in
            if newVisible {
                self.shadowBackgroundView.alpha = 1.0
                self.draggableContainerHiddenTopConstraint.isActive = false
                self.draggableContainerShownTopConstraint.constant = initialOffset
                self.draggableContainerShownTopConstraint.isActive = true
            } else {
                self.shadowBackgroundView.alpha = 0.0
                self.draggableContainerShownTopConstraint.isActive = false
                self.draggableContainerHiddenTopConstraint.isActive = true
            }
        }
        let animationCompletion = { (_: Bool) -> Void in
            if !newVisible {
                self.view.isHidden = true
                self.isVisible = false
            }
            completion?()
            if self.isShadowEnabled {
                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
        if animated {
            UIView.animate(
                withDuration: showHideAnimationDuration,
                delay: 0.0,
                options: [.beginFromCurrentState, .curveEaseOut],
                animations: {
                    animations()
                    self.view.layoutIfNeeded()
            },
                completion: animationCompletion)
        } else {
            animations()
            animationCompletion(true)
        }
    }

    private func animateToOffset(_ targetOffset: CGFloat, isSpring: Bool, completion: (() -> Void)?) {
        let animations = { () -> Void in
            if self.isShadowEnabled {
                self.shadowBackgroundView.alpha = 1.0
            }
            self.draggableContainerShownTopConstraint.constant = targetOffset
            self.view.layoutIfNeeded()
        }
        if isSpring {
            UIView.animate(withDuration: snapAnimationSpringDuration,
                           delay: 0.0,
                           usingSpringWithDamping: snapAnimationSpringDamping,
                           initialSpringVelocity: snapAnimationSpringInitialVelocity,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: animations,
                           completion: { (_) -> Void in completion?() })
        } else {
            UIView.animate(withDuration: snapAnimationNormalDuration,
                           delay: 0.0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: animations,
                           completion: { (_) -> Void in completion?() })
        }
    }

    private func setPreventContentScroll(_ newValue: Bool) {
        nestedController.draggableDetailsOverlay(self, requirePreventOfScroll: newValue)
    }

    private func isContentScrollAtTop(contentScrollView: UIScrollView?) -> Bool {
        guard let scroll = contentScrollView else {
            return true
        }
        return scroll.contentOffset.y <= -scroll.contentInset.top
    }

    private func performAccessibilityAction(isCollapse: Bool) -> Bool {
        let currentOffset = draggableContainerShownTopConstraint.constant
        let nextAnchorIndex = cachedAnchors.firstIndex(where: { isOffsetsEqual($0.value, currentOffset) }).map({ $0 + (isCollapse ? 1 : -1) })
        guard let nextAnchorIndexActual = nextAnchorIndex, nextAnchorIndexActual >= 0 && nextAnchorIndexActual < cachedAnchors.count else {
            return false
        }
        let topInset = calculateTopInset()
        let newCurrentOffset = offsetForAnchor(cachedAnchors[nextAnchorIndexActual], topInset: topInset)
        animateToOffset(newCurrentOffset, isSpring: false, completion: {
            self.delegate?.draggableDetailsOverlayDidUpdatedLayout(self)
        })
        setupAccessibility()
        return true
    }

    private func setupAccessibility() {
        guard isViewLoaded, let handleViewActual = handleView else {
            return
        }
        view.accessibilityViewIsModal = isShadowEnabled
        handleViewActual.isAccessibilityElement = true
        let currentOffset = draggableContainerShownTopConstraint.constant
        let currentAnchorIndex = cachedAnchors.firstIndex(where: { isOffsetsEqual($0.value, currentOffset) })
        var label = handleViewAccessibilityTitle ?? "TODO: Overlay controller"
        if cachedAnchors.count > 1 {
            if currentAnchorIndex == 0 {
                label.append(", ")
                label.append(handleViewAccessibilityMaximizedTitle ?? "Maximized")
            } else if currentAnchorIndex == cachedAnchors.count - 1 {
                label.append(", ")
                label.append("Minimized")
            }
        }
        label.append(", ")
        label.append(handleViewAccessibilitySubtitle ?? "Adjust the size of the overlay")
        handleViewActual.accessibilityLabel = label
        var actions: [UIAccessibilityCustomAction] = []
        if cachedAnchors.count > 1 {
            let collapseTitle = handleViewAccessibilityCollapseTitle ?? "Collapse"
            let expandTitle = handleViewAccessibilityExpandTitle ?? "Expand"
            actions.append(UIAccessibilityCustomAction(name: collapseTitle, target: self, selector: #selector(collapseButtonPressed)))
            actions.append(UIAccessibilityCustomAction(name: expandTitle, target: self, selector: #selector(expandButtonPressed)))
        }
        if isDragOffScreenToHideEnabled {
            let hideTitle = handleViewAccessibilityHideTitle ?? "Hide"
            actions.append(UIAccessibilityCustomAction(name: hideTitle, target: self, selector: #selector(hideButtonPressed)))
        }
        handleViewActual.accessibilityCustomActions = actions
    }

}
