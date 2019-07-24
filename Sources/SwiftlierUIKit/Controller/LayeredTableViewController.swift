//
//  LayeredTableViewController.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 8/5/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

#if os(iOS)
import UIKit

public protocol LayeredTableViewControllerDelegate: class {
    func bottomHeight(forLayeredTableViewController controller: LayeredTableViewController) -> CGFloat
    func contentInset(forLayeredTableViewController controller: LayeredTableViewController) -> UIEdgeInsets
}

open class LayeredTableViewController: UIViewController {
    public let topTableView: UITableView
    public let bottomTableView: UITableView

    fileprivate var topTableViewDelegate: UITableViewDelegate?
    fileprivate var bottomTableViewDelegate: UITableViewDelegate?
    fileprivate var baseBottomInset: CGFloat = 0
    fileprivate var openGestureRecognizer: UITapGestureRecognizer!
    fileprivate var arrangedSize = CGSize()

    public init(topStyle: UITableView.Style = .plain, bottomStyle: UITableView.Style = .plain) {
        self.topTableView = UITableView(frame: CGRect(), style: topStyle)
        self.bottomTableView = TapThroughAboveTableView(frame: CGRect(), style: bottomStyle)

        super.init(nibName: nil, bundle: nil)

        self.openGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openBottom))
    }

    public required init?(coder aDecoder: NSCoder) {
        self.topTableView = UITableView()
        self.bottomTableView = TapThroughAboveTableView()

        super.init(coder: aDecoder)

        self.openGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openBottom))
    }

    public weak var delegate: LayeredTableViewControllerDelegate? {
        didSet {
            self.view.setNeedsLayout()
        }
    }

    public var effectiveClosedBottomTableViewFrame: CGRect {
        let y = -self.bottomTableView.contentOffset.y
        return CGRect(
            x: self.bottomTableView.frame.origin.x,
            y: y,
            width: self.bottomTableView.frame.width,
            height: self.bottomTableView.frame.height - y
        )
    }

    public fileprivate(set) var isOpen: Bool = true {
        didSet {
            guard isOpen != oldValue else {
                return
            }
            self.bottomTableView.allowsSelection = isOpen
            self.openGestureRecognizer.isEnabled = !isOpen
        }
    }

    deinit {
        self.bottomTableView.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.topTableView.translatesAutoresizingMaskIntoConstraints = false
        self.bottomTableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addFillingSubview(self.topTableView)
        self.view.addFillingSubview(self.bottomTableView)

        self.isOpen = false
        self.bottomTableView.addGestureRecognizer(self.openGestureRecognizer)

        self.bottomTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        for indexPath in self.topTableView.indexPathsForSelectedRows ?? [] {
            self.topTableView.deselectRow(at: indexPath, animated: true)
        }

        for indexPath in self.bottomTableView.indexPathsForSelectedRows ?? [] {
            self.bottomTableView.deselectRow(at: indexPath, animated: true)
        }
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.arrange(for: self.view.bounds.size)
    }

    open func arrange(for size: CGSize) {
        guard size != self.arrangedSize else {
            return
        }

        defer {
            self.arrangedSize = size
        }

        let bottomHeight = self.delegate?.bottomHeight(forLayeredTableViewController: self) ?? 300
        var inset = self.delegate?.contentInset(forLayeredTableViewController: self) ?? UIEdgeInsets()
        var top = size.height - bottomHeight
        var bottomOfTop = bottomHeight
        if #available(iOS 11.0, tvOS 11.0, *) {
            top -= self.view.safeAreaInsets.bottom + self.view.safeAreaInsets.top
        }
        else {
            top -= (self.tabBarController?.tabBar.frame.height ?? 0)
            bottomOfTop += (self.topTableView.tableHeaderView?.frame.height ?? 0)
                + (self.tabBarController?.tabBar.frame.height ?? 0)
            inset.bottom += (self.tabBarController?.tabBar.frame.height ?? 0)
        }

        self.topTableView.contentInset = UIEdgeInsets(
            top: inset.top,
            left: inset.left,
            bottom: bottomOfTop,
            right: inset.right
        )

        self.bottomTableView.contentInset = UIEdgeInsets(
            top: top,
            left: inset.left,
            bottom: inset.bottom,
            right: inset.right
        )
        self.baseBottomInset = inset.bottom
        self.bottomTableView.scrollIndicatorInsets = UIEdgeInsets(
            top: inset.top,
            left: inset.left,
            bottom: inset.bottom,
            right: inset.right
        )
        self.topTableView.scrollIndicatorInsets = self.topTableView.contentInset

        if self.topTableView.delegate !== self {
            self.topTableViewDelegate = self.topTableView.delegate
            self.topTableView.delegate = self
        }

        if self.bottomTableView.delegate !== self {
            self.bottomTableViewDelegate = self.bottomTableView.delegate
            self.bottomTableView.delegate = self
        }

        self.maskBottomTableView()

        if self.isOpen {
            self.bottomTableView.contentOffset.y = max(self.bottomOpenYOffset, self.bottomTableView.contentOffset.y)
        }
        else {
            self.bottomTableView.contentOffset.y = self.bottomClosedYOffset
        }
        self.resetBottomInset(for: size)
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath ?? "" {
        case "contentSize":
            self.resetBottomInset(adjustContentOffset: self.isOpen)
        default:
            break
        }
    }

    public var topAdjustedContentInset: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.topTableView.adjustedContentInset
        } else {
            var insets = self.topTableView.contentInset
            insets.top += UIApplication.shared.statusBarFrame.maxY
            insets.bottom += (self.tabBarController?.tabBar.frame.height ?? 0)
            return insets
        }
    }

    public var bottomClosedYOffset: CGFloat {
        if #available(iOS 11.0, *) {
            return -self.bottomTableView.adjustedContentInset.top
        } else {
            return -self.bottomTableView.contentInset.top
                - UIApplication.shared.statusBarFrame.maxY
        }
    }

    public var bottomOpenYOffset: CGFloat {
        return -self.topAdjustedContentInset.top
    }

    @objc public func openBottom() {
        self.bottomTableView.setContentOffset(CGPoint(x: 0, y: self.bottomOpenYOffset), animated: true)
        self.isOpen = true
    }

    public func closeBottom() {
        self.bottomTableView.setContentOffset(CGPoint(x: 0, y: self.bottomClosedYOffset), animated: true)
        self.isOpen = false
    }
}

extension LayeredTableViewController: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.move(point: &targetContentOffset.pointee, toOutsideOfShowingTransitionRangeFor: scrollView)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if self.isOpen {
            self.closeBottom()
        }
        else {
            self.topTableView.setContentOffset(CGPoint(x: 0, y: -self.topTableView.contentInset.top), animated: true)
        }
        return false
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {}
}

private class TapThroughAboveTableView: UITableView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event), point.y >= 0 else {
            return nil
        }
        return view
    }
}

private extension LayeredTableViewController {
    func maskBottomTableView() {
        let layer = CAShapeLayer()
        let rect = CGRect(x: 0, y: 0, width: self.bottomTableView.bounds.width, height: 9999999)
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: UIRectCorner.topLeft.union(.topRight),
            cornerRadii: CGSize(width: 10, height: 10)
        )
        layer.path = path.cgPath
        self.bottomTableView.layer.mask = layer
    }

    func move(point: inout CGPoint, toOutsideOfShowingTransitionRangeFor scrollView: UIScrollView) {
        switch scrollView {
        case self.topTableView:
            break
        case self.bottomTableView:
            let open = self.bottomOpenYOffset
            guard point.y < open else {
                self.isOpen = true
                return
            }

            let closed: CGFloat = self.bottomClosedYOffset
            let range = open - closed
            let beyondOpen = point.y - closed
            if beyondOpen / range > 0.5 {
                point.y = open
                self.isOpen = true
            }
            else {
                point.y = closed
                self.isOpen = false
            }
        default:
            break
        }
    }

    func resetBottomInset(for size: CGSize? = nil, adjustContentOffset: Bool = false) {
        let size = size ?? self.view.bounds.size
        let inset = self.delegate?.contentInset(forLayeredTableViewController: self) ?? UIEdgeInsets()
        var minimumHeight = size.height - inset.top - inset.bottom
        if #available(iOS 11.0, *) {
            minimumHeight -= self.view.safeAreaInsets.top
                + self.view.safeAreaInsets.bottom
        }
        else {
            minimumHeight -= (self.tabBarController?.tabBar.frame.height ?? 0)
                + UIApplication.shared.statusBarFrame.maxY
        }
        let missingHeight = minimumHeight - self.bottomTableView.contentSize.height
        if missingHeight > 0 {
            let new = self.baseBottomInset + missingHeight
            let change = new - self.bottomTableView.contentInset.bottom
            self.bottomTableView.contentInset.bottom = new
            if adjustContentOffset {
                self.bottomTableView.contentOffset.y += change
            }
        }
        else {
            self.bottomTableView.contentInset.bottom = self.baseBottomInset
        }
    }
}

extension LayeredTableViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didEndDisplayingHeaderView: view, forSection: section)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didEndDisplayingHeaderView: view, forSection: section)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didEndDisplayingFooterView: view, forSection: section)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didEndDisplayingFooterView: view, forSection: section)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, heightForRowAt: indexPath) ?? 44
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, heightForRowAt: indexPath) ?? 44
        default:
            return 44
        }
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, heightForHeaderInSection: section) ?? 0
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, heightForHeaderInSection: section) ?? 0
        default:
            return 0
        }
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, heightForFooterInSection: section) ?? 0
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, heightForFooterInSection: section) ?? 0
        default:
            return 0
        }
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, estimatedHeightForRowAt: indexPath) ?? 44
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, estimatedHeightForRowAt: indexPath) ?? 44
        default:
            return 44
        }
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, estimatedHeightForHeaderInSection: section) ?? 0
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, estimatedHeightForHeaderInSection: section) ?? 0
        default:
            return 0
        }
    }
    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, estimatedHeightForFooterInSection: section) ?? 0
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, estimatedHeightForFooterInSection: section) ?? 0
        default:
            return 0
        }
    }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, viewForHeaderInSection: section) ?? nil
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, viewForHeaderInSection: section) ?? nil
        default:
            return nil
        }
    }
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, viewForFooterInSection: section) ?? nil
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, viewForFooterInSection: section) ?? nil
        default:
            return nil
        }
    }
    public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, shouldHighlightRowAt: indexPath) ?? true
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, shouldHighlightRowAt: indexPath) ?? true
        default:
            return true
        }
    }
    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didHighlightRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didHighlightRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didUnhighlightRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didUnhighlightRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, willSelectRowAt: indexPath) ?? indexPath
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, willSelectRowAt: indexPath) ?? indexPath
        default:
            return indexPath
        }
    }
    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, willDeselectRowAt: indexPath) ?? indexPath
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, willDeselectRowAt: indexPath) ?? indexPath
        default:
            return indexPath
        }
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didDeselectRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didDeselectRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, editingStyleForRowAt: indexPath) ?? .none
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, editingStyleForRowAt: indexPath) ?? .none
        default:
            return .none
        }
    }
    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, titleForDeleteConfirmationButtonForRowAt: indexPath) ?? "Delete"
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, titleForDeleteConfirmationButtonForRowAt: indexPath) ?? "Delete"
        default:
            return "Delete"
        }
    }
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, editActionsForRowAt: indexPath)
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, editActionsForRowAt: indexPath)
        default:
            return nil
        }
    }
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, leadingSwipeActionsConfigurationForRowAt: indexPath)
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, leadingSwipeActionsConfigurationForRowAt: indexPath)
        default:
            return nil
        }
    }
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
        default:
            return nil
        }
    }
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, shouldIndentWhileEditingRowAt: indexPath) ?? true
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, shouldIndentWhileEditingRowAt: indexPath) ?? true
        default:
            return true
        }
    }
    public func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, willBeginEditingRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, willBeginEditingRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didEndEditingRowAt: indexPath)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didEndEditingRowAt: indexPath)
        default:
            break
        }
    }
    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, targetIndexPathForMoveFromRowAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath) ?? proposedDestinationIndexPath
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, targetIndexPathForMoveFromRowAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath) ?? proposedDestinationIndexPath
        default:
            return proposedDestinationIndexPath
        }
    }
    public func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, indentationLevelForRowAt: indexPath) ?? 0
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, indentationLevelForRowAt: indexPath) ?? 0
        default:
            return 0
        }
    }
    public func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, shouldShowMenuForRowAt: indexPath) ?? false
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, shouldShowMenuForRowAt: indexPath) ?? false
        default:
            return false
        }
    }
    public func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, canPerformAction: action, forRowAt: indexPath, withSender: sender) ?? false
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, canPerformAction: action, forRowAt: indexPath, withSender: sender) ?? false
        default:
            return false
        }
    }
    public func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, performAction: action, forRowAt: indexPath, withSender: sender)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, performAction: action, forRowAt: indexPath, withSender: sender)
        default:
            break
        }
    }
    @available(iOS 9.0, *)
    public func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, canFocusRowAt: indexPath) ?? true
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, canFocusRowAt: indexPath) ?? true
        default:
            return true
        }
    }
    @available(iOS 9.0, *)
    public func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, shouldUpdateFocusIn: context) ?? true
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, shouldUpdateFocusIn: context) ?? true
        default:
            return true
        }
    }
    @available(iOS 9.0, *)
    public func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        switch tableView {
        case self.topTableView:
            self.topTableViewDelegate?.tableView?(tableView, didUpdateFocusIn: context, with: coordinator)
        case self.bottomTableView:
            self.bottomTableViewDelegate?.tableView?(tableView, didUpdateFocusIn: context, with: coordinator)
        default:
            break
        }
    }
    @available(iOS 9.0, *)
    public func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.indexPathForPreferredFocusedView?(in: tableView) ?? nil
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.indexPathForPreferredFocusedView?(in: tableView) ?? nil
        default:
            return nil
        }
    }
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        switch tableView {
        case self.topTableView:
            return self.topTableViewDelegate?.tableView?(tableView, shouldSpringLoadRowAt: indexPath, with: context) ?? true
        case self.bottomTableView:
            return self.bottomTableViewDelegate?.tableView?(tableView, shouldSpringLoadRowAt: indexPath, with: context) ?? true
        default:
            return true
        }
    }
}
#endif
