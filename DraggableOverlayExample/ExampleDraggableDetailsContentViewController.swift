//
// Copyright (c) 2022 Shakuro (https://shakuro.com/)
//

import Foundation
import DraggableOverlayFramework
import UIKit

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
