//
//
//

import Foundation
import UIKit
import Shakuro_CommonTypes
import DraggableOverlayFramework

// MARK: - Example Content

internal enum ExampleStoryboardName: String {

    case main = "Main"

    internal func storyboard() -> UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }

}

internal protocol ExampleDraggableDetailsContentViewControllerDelegate: AnyObject {
    func contentDidPressCloseButton()
}

internal class ExampleDraggableDetailsContentViewController: UIViewController {

    internal weak var delegate: ExampleDraggableDetailsContentViewControllerDelegate?

    @IBOutlet private var topTableView: UITableView!
    @IBOutlet private var bottomTableView: UITableView!

    private var shouldPreventScrolling: Bool = false
    private var currentContentScrollOffsetTop: CGPoint = .zero
    private var currentContentScrollOffsetBottom: CGPoint = .zero

    internal static func instantiate() -> ExampleDraggableDetailsContentViewController {
        let controller: ExampleDraggableDetailsContentViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsContentViewControllerID")
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        topTableView.delegate = self
        topTableView.dataSource = self
        bottomTableView.delegate = self
        bottomTableView.dataSource = self
    }

    @IBAction private func closeOverlayButtondidPress() {
        delegate?.contentDidPressCloseButton()
    }

}

// MARK: UITableViewDataSource, UITableViewDelegate

extension ExampleDraggableDetailsContentViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "kExampleDraggableDetailsContentCellID", for: indexPath)
        cell.textLabel?.text = (tableView === topTableView ? "top" : "bottom") + " #\(indexPath.row)"
        return cell
    }

}

// MARK: UIScrollViewDelegate

extension ExampleDraggableDetailsContentViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldPreventScrolling {
            if scrollView === topTableView {
                scrollView.contentOffset = currentContentScrollOffsetTop
            } else if scrollView === bottomTableView {
                scrollView.contentOffset = currentContentScrollOffsetBottom
            }
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if shouldPreventScrolling {
            if scrollView === topTableView {
                targetContentOffset.pointee = currentContentScrollOffsetTop
            } else if scrollView === bottomTableView {
                targetContentOffset.pointee = currentContentScrollOffsetBottom
            }
        }
    }

}

// MARK: DraggableDetailsOverlayNestedInterface

extension ExampleDraggableDetailsContentViewController: DraggableDetailsOverlayNestedInterface {

    func draggableDetailsOverlay(_ overlay: DraggableDetailsOverlayViewController, requirePreventOfScroll: Bool) {
        shouldPreventScrolling = requirePreventOfScroll
        topTableView.showsVerticalScrollIndicator = !requirePreventOfScroll
        bottomTableView.showsVerticalScrollIndicator = !requirePreventOfScroll
        if requirePreventOfScroll {
            currentContentScrollOffsetTop = topTableView.contentOffset
            currentContentScrollOffsetBottom = bottomTableView.contentOffset
        }
    }

    func draggableDetailsOverlayContentScrollViews(_ overlay: DraggableDetailsOverlayViewController) -> [UIScrollView] {
        return [topTableView, bottomTableView]
    }

}

// MARK: - Example

internal class ExampleDraggableDetailsOverlayViewController: UIViewController {

    @IBOutlet private var contentScrollView: UIScrollView!

    @IBOutlet private var presentationStyleControl: UISegmentedControl!

    @IBOutlet private var shadowSwitch: UISwitch!
    @IBOutlet private var shadowColorButton: UIButton!

    @IBOutlet private var draggableContainerBackgroundColorButton: UIButton!

    @IBOutlet private var handleColorButton: UIButton!

    @IBOutlet private var overlayTopInsetSlider: UISlider!
    @IBOutlet private var overlayMaxHeightSlider: UISlider!

    @IBOutlet private var draggableContainerTopCornersRadiusSlider: UISlider!
    @IBOutlet private var handleContainerHeightSlider: UISlider!
    @IBOutlet private var handleWidthSlider: UISlider!
    @IBOutlet private var handleHeightSlider: UISlider!
    @IBOutlet private var handleCornerRadiusSlider: UISlider!
    @IBOutlet private var showHideAnimationDurationSlider: UISlider!
    @IBOutlet private var bounceDragDumpeningSlider: UISlider!
    @IBOutlet private var snapAnimationNormalDurationSlider: UISlider!
    @IBOutlet private var snapAnimationSpringDurationSlider: UISlider!
    @IBOutlet private var snapAnimationSpringDampingSlider: UISlider!
    @IBOutlet private var snapAnimationSpringInitialVelocitySlider: UISlider!

    @IBOutlet private var draggableContainerTopCornersRadiusLabel: UILabel!
    @IBOutlet private var handleContainerHeightLabel: UILabel!
    @IBOutlet private var handleSizeLabel: UILabel!
    @IBOutlet private var handleCornerRadiusLabel: UILabel!
    @IBOutlet private var showHideAnimationDurationLabel: UILabel!
    @IBOutlet private var bounceDragDumpeningLabel: UILabel!
    @IBOutlet private var snapAnimationNormalDurationLabel: UILabel!
    @IBOutlet private var snapAnimationSpringDurationLabel: UILabel!
    @IBOutlet private var snapAnimationSpringDampingLabel: UILabel!
    @IBOutlet private var snapAnimationSpringInitialVelocityLabel: UILabel!
    @IBOutlet private var overlayTopInsetLabel: UILabel!
    @IBOutlet private var overlayMaxHeightLabel: UILabel!

    @IBOutlet private var isSnapToAnchorsEnabledSwitch: UISwitch!
    @IBOutlet private var isDragOffScreenToHideEnabledSwitch: UISwitch!
    @IBOutlet private var isBounceEnabledSwitch: UISwitch!
    @IBOutlet private var snapCalculationUsesDecelerationSwitch: UISwitch!
    @IBOutlet private var snapCalculationDecelerationCanSkipNextAnchorSwitch: UISwitch!
    @IBOutlet private var snapAnimationUseSpringSwitch: UISwitch!
    @IBOutlet private var snapAnimationTopAnchorUseSpringSwitch: UISwitch!
    @IBOutlet private var containerShadowSwitch: UISwitch!

    @IBOutlet private var snapCalculationDecelerationRateSegmentedControl: UISegmentedControl!

    private var contentViewController: ExampleDraggableDetailsContentViewController!
    private var overlayViewController: DraggableDetailsOverlayViewController!
    private var keyboardHandler: KeyboardHandler?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Draggable overlay"
        contentScrollView.delegate = self

        contentViewController = ExampleDraggableDetailsContentViewController.instantiate()
        contentViewController.delegate = self
        overlayViewController = DraggableDetailsOverlayViewController(nestedController: contentViewController, delegate: self)

        contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 400, right: 0)

        overlayViewController.isShadowEnabled = shadowSwitch.isOn
        overlayViewController.isSnapToAnchorsEnabled = isSnapToAnchorsEnabledSwitch.isOn
        isDragOffScreenToHideEnabledSwitch.isOn = overlayViewController.isDragOffScreenToHideEnabled
        isBounceEnabledSwitch.isOn = overlayViewController.isBounceEnabled
        snapCalculationUsesDecelerationSwitch.isOn = overlayViewController.snapCalculationUsesDeceleration
        snapCalculationDecelerationCanSkipNextAnchorSwitch.isOn = overlayViewController.snapCalculationDecelerationCanSkipNextAnchor
        snapAnimationUseSpringSwitch.isOn = overlayViewController.snapAnimationUseSpring
        snapAnimationTopAnchorUseSpringSwitch.isOn = overlayViewController.snapAnimationTopAnchorUseSpring
        containerShadowSwitch.isOn = overlayViewController.isContainerShadowEnabled

        [shadowColorButton, draggableContainerBackgroundColorButton, handleColorButton].forEach { (button: UIButton) in
            button.setTitleShadowColor(UIColor.black, for: .normal)
        }
        shadowColorButton.setTitleColor(overlayViewController.shadowBackgroundColor, for: .normal)
        draggableContainerBackgroundColorButton.setTitleColor(overlayViewController.draggableContainerBackgroundColor, for: .normal)
        handleColorButton.setTitleColor(overlayViewController.handleColor, for: .normal)

        draggableContainerTopCornersRadiusSlider.value = Float(overlayViewController.draggableContainerTopCornersRadius)
        handleCornerRadiusSlider.value = Float(overlayViewController.handleCornerRadius)

        handleWidthSlider.value = Float(overlayViewController.handleSize.width)
        handleHeightSlider.value = Float(overlayViewController.handleSize.height)
        handleContainerHeightSlider.value = Float(overlayViewController.handleContainerHeight)
        showHideAnimationDurationSlider.value = Float(overlayViewController.showHideAnimationDuration)
        bounceDragDumpeningSlider.value = Float(overlayViewController.bounceDragDumpening)

        snapAnimationNormalDurationSlider.value = Float(overlayViewController.snapAnimationNormalDuration)
        snapAnimationSpringDurationSlider.value = Float(overlayViewController.snapAnimationSpringDuration)
        snapAnimationSpringDampingSlider.value = Float(overlayViewController.snapAnimationSpringDamping)
        snapAnimationSpringInitialVelocitySlider.value = Float(overlayViewController.snapAnimationSpringInitialVelocity)

        overlayViewController.snapCalculationDecelerationRate = snapCalculationDecelerationRateSegmentedControl.selectedSegmentIndex == 0 ? .normal : .fast

        keyboardHandler = KeyboardHandler(enableCurveHack: false, heightDidChange: { [weak self] (change: KeyboardHandler.KeyboardChange) in
            guard let strongSelf = self else {
                return
            }
            UIView.animate(
                withDuration: change.animationDuration,
                delay: 0.0,
                animations: {
                    UIView.setAnimationCurve(change.animationCurve)
                    strongSelf.contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: change.newHeight, right: 0)
                    strongSelf.view.layoutIfNeeded()
            },
                completion: nil)
        })
        keyboardHandler?.isActive = true
        updateSliderLabels()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let maxValue: Float = Float(view.bounds.size.height)
        if maxValue != overlayTopInsetSlider.maximumValue || maxValue != overlayMaxHeightSlider.maximumValue {
            overlayTopInsetSlider.maximumValue = maxValue
            overlayMaxHeightSlider.maximumValue = maxValue
            overlayViewController.updateLayout(animated: false)
            updateSliderLabels()
        }
    }

    @IBAction private func showOverlayButtonDidPress() {
        view.endEditing(true)
        showOverlay()
    }

    @IBAction private func switchValueChanged(_ sender: UISwitch) {
        switch sender {
        case shadowSwitch:
            overlayViewController.isShadowEnabled = shadowSwitch.isOn
        case isSnapToAnchorsEnabledSwitch:
            overlayViewController.isSnapToAnchorsEnabled = isSnapToAnchorsEnabledSwitch.isOn
        case isDragOffScreenToHideEnabledSwitch:
            overlayViewController.isDragOffScreenToHideEnabled = isDragOffScreenToHideEnabledSwitch.isOn
        case isBounceEnabledSwitch:
            overlayViewController.isBounceEnabled = isBounceEnabledSwitch.isOn
        case snapCalculationUsesDecelerationSwitch:
            overlayViewController.snapCalculationUsesDeceleration = snapCalculationUsesDecelerationSwitch.isOn
        case snapCalculationDecelerationCanSkipNextAnchorSwitch:
            overlayViewController.snapCalculationDecelerationCanSkipNextAnchor = snapCalculationDecelerationCanSkipNextAnchorSwitch.isOn
        case snapAnimationTopAnchorUseSpringSwitch:
            overlayViewController.snapAnimationTopAnchorUseSpring = snapAnimationTopAnchorUseSpringSwitch.isOn
        case snapAnimationUseSpringSwitch:
            overlayViewController.snapAnimationUseSpring = snapAnimationUseSpringSwitch.isOn
        case containerShadowSwitch:
            overlayViewController.isContainerShadowEnabled = containerShadowSwitch.isOn
        default:
            assertionFailure("unknown switch")
        }
    }

    @IBAction private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender {
        case snapCalculationDecelerationRateSegmentedControl:
            overlayViewController.snapCalculationDecelerationRate = snapCalculationDecelerationRateSegmentedControl.selectedSegmentIndex == 0 ? .normal : .fast
        case presentationStyleControl:
            showOverlay()
        default:
            assertionFailure("unknown segmented control")
        }
    }

    @IBAction private func sliderValueChanged(_ sender: UISlider) {
        switch sender {
        case draggableContainerTopCornersRadiusSlider:
            overlayViewController.draggableContainerTopCornersRadius = CGFloat(sender.value)
        case handleCornerRadiusSlider:
            overlayViewController.handleCornerRadius = CGFloat(sender.value)
        case handleWidthSlider, handleHeightSlider:
            overlayViewController.handleSize = CGSize(width: CGFloat(handleWidthSlider.value), height: CGFloat(handleHeightSlider.value))
        case handleContainerHeightSlider:
            overlayViewController.handleContainerHeight = CGFloat(handleContainerHeightSlider.value)
        case showHideAnimationDurationSlider:
            overlayViewController.showHideAnimationDuration = TimeInterval(showHideAnimationDurationSlider.value)
        case bounceDragDumpeningSlider:
            overlayViewController.bounceDragDumpening = CGFloat(bounceDragDumpeningSlider.value)
        case snapAnimationNormalDurationSlider:
            overlayViewController.snapAnimationNormalDuration = TimeInterval(snapAnimationNormalDurationSlider.value)
        case snapAnimationSpringDurationSlider:
            overlayViewController.snapAnimationSpringDuration = TimeInterval(snapAnimationSpringDurationSlider.value)
        case snapAnimationSpringDampingSlider:
            overlayViewController.snapAnimationSpringDamping = CGFloat(snapAnimationSpringDampingSlider.value)
        case snapAnimationSpringInitialVelocitySlider:
            overlayViewController.snapAnimationSpringInitialVelocity = CGFloat(snapAnimationSpringInitialVelocitySlider.value)
        case overlayMaxHeightSlider, overlayTopInsetSlider:
            overlayViewController.updateLayout(animated: true)
        default:
            assertionFailure("unknown slider")
        }
        updateSliderLabels()
    }

    @IBAction private func changeShadowColor(_ sender: UIButton) {
        overlayViewController.shadowBackgroundColor = UIColor.random(alpha: 0.5)
        shadowColorButton.setTitleColor(overlayViewController.shadowBackgroundColor.withAlphaComponent(1.0), for: .normal)
    }

    @IBAction private func draggableContainerBackgroundColorButtonPressed(_ sender: UIButton) {
        overlayViewController.draggableContainerBackgroundColor = UIColor.random(alpha: 1.0)
        draggableContainerBackgroundColorButton.setTitleColor(overlayViewController.draggableContainerBackgroundColor, for: .normal)
    }

    @IBAction private func handleColorButtonPressed(_ sender: UIButton) {
        overlayViewController.handleColor = UIColor.random(alpha: 1.0)
        handleColorButton.setTitleColor(overlayViewController.handleColor, for: .normal)
    }
}

// MARK: ExampleDraggableDetailsContentViewControllerDelegate

extension ExampleDraggableDetailsOverlayViewController: ExampleDraggableDetailsContentViewControllerDelegate {

    func contentDidPressCloseButton() {
        overlayViewController.hide(animated: true)
    }

}

// MARK: DraggableDetailsOverlayViewControllerDelegate

extension ExampleDraggableDetailsOverlayViewController: DraggableDetailsOverlayViewControllerDelegate {

    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor] {
        return [
            DraggableDetailsOverlayViewController.Anchor(topOffset: 40, tag: 1),
            DraggableDetailsOverlayViewController.Anchor(height: 300, tag: 2),
            DraggableDetailsOverlayViewController.Anchor(height: 100, tag: 3)
        ]
    }

    func draggableDetailsOverlayTopInset(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat {
        return CGFloat(overlayTopInsetSlider.value)
    }

    func draggableDetailsOverlayMaxHeight(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat? {
        return CGFloat(overlayMaxHeightSlider.value)
    }

    func draggableDetailsOverlayDidDrag(_ overlay: DraggableDetailsOverlayViewController) {
        print("did drag")
    }

    func draggableDetailsOverlayDidEndDragging(_ overlay: DraggableDetailsOverlayViewController) {
        print("did end dragging")
    }

    func draggableDetailsOverlayDidChangeIsVisible(_ overlay: DraggableDetailsOverlayViewController) {
        if !overlay.isVisible, presentedViewController != nil {
            dismiss(animated: false, completion: nil)
        }
    }

    func draggableDetailsOverlayDidUpdatedLayout(_ overlay: DraggableDetailsOverlayViewController) {
        print("did update layout")
    }

    func draggableDetailsOverlayWillDragOffScreenToHide(_ overlay: DraggableDetailsOverlayViewController) {
        print("will drag offscreen")
    }

    func draggableDetailsOverlayDidHideByShadowTap(_ overlay: DraggableDetailsOverlayViewController) {
        print("will hide by shadow tap")
    }

    func draggableDetailsOverlay(_ overlay: DraggableDetailsOverlayViewController, willAnimateEndDragToNearestAnchor anchor: DraggableDetailsOverlayViewController.Anchor) {
        print("will animate end drag to nearest anchor: \(anchor)")
    }

}

// MARK: UIScrollViewDelegate

extension ExampleDraggableDetailsOverlayViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === contentScrollView {
            view.endEditing(false)
        }
    }

}

private extension ExampleDraggableDetailsOverlayViewController {

    func showOverlay() {
        guard presentedViewController == nil else {
            dismiss(animated: true) { [weak self] in
                guard let actualSelf = self else {
                    return
                }
                actualSelf.showOverlay()
            }
            return
        }
        let selectedSegment = presentationStyleControl.selectedSegmentIndex
        switch selectedSegment {
        case 0:
            addChildViewController(overlayViewController, notifyAboutAppearanceTransition: true)
            overlayViewController.view.layoutIfNeeded()
            overlayViewController.hide(animated: false)
            overlayViewController.show(initialAnchor: DraggableDetailsOverlayViewController.Anchor(height: 400, tag: 4), animated: true)
        case 1, 2:
            overlayViewController.hide(animated: false)
            if overlayViewController.parent != nil {
                overlayViewController.removeFromParentViewController(notifyAboutAppearanceTransition: true)
                overlayViewController.hide(animated: false)
            }
            overlayViewController.modalPresentationStyle = .overCurrentContext
            if selectedSegment == 1 {
                overlayViewController.isShadowEnabled = false
                overlayViewController.modalTransitionStyle = .coverVertical
                overlayViewController.show(initialAnchor: DraggableDetailsOverlayViewController.Anchor(height: 400, tag: 4), animated: false)
                present(overlayViewController, animated: true, completion: nil)
            } else {
                overlayViewController.isShadowEnabled = true
                overlayViewController.modalTransitionStyle = .crossDissolve
                present(overlayViewController, animated: true) {
                    self.overlayViewController.show(initialAnchor: DraggableDetailsOverlayViewController.Anchor(height: 400, tag: 4), animated: true)
                }
            }
        default:
            break
        }

    }

    func updateSliderLabels() {
        draggableContainerTopCornersRadiusLabel.text = String(format: "%.1f", draggableContainerTopCornersRadiusSlider.value)
        handleContainerHeightLabel.text = String(format: "%.1f", handleContainerHeightSlider.value)
        handleSizeLabel.text = String(format: "W: %.1f; H: %.1f", handleWidthSlider.value, handleHeightSlider.value)
        handleCornerRadiusLabel.text = String(format: "%.1f", handleCornerRadiusSlider.value)
        showHideAnimationDurationLabel.text = String(format: "%.2f", showHideAnimationDurationSlider.value)
        bounceDragDumpeningLabel.text = String(format: "%.2f", bounceDragDumpeningSlider.value)
        snapAnimationNormalDurationLabel.text = String(format: "%.2f", snapAnimationNormalDurationSlider.value)
        snapAnimationSpringDurationLabel.text = String(format: "%.2f", snapAnimationSpringDurationSlider.value)
        snapAnimationSpringDampingLabel.text = String(format: "%.2f", snapAnimationSpringDampingSlider.value)
        snapAnimationSpringInitialVelocityLabel.text = String(format: "%.2f", snapAnimationSpringInitialVelocitySlider.value)
        overlayTopInsetLabel.text = String(format: "%.1f", overlayTopInsetSlider.value)
        overlayMaxHeightLabel.text = String(format: "%.1f", overlayMaxHeightSlider.value)
    }
}
