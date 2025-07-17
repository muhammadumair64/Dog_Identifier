//
//  ScrollDetector.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 22/01/2025.
//


import SwiftUI

/// Extracting UIScrollview from SwiftUI ScrollView for monitoring offset and velocity and refreshing
public struct ScrollDetector: UIViewRepresentable {
    public init(
        onScroll: @escaping (CGFloat) -> Void,
        onDraggingEnd: @escaping (CGFloat, CGFloat) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.onScroll = onScroll
        self.onDraggingEnd = onDraggingEnd
        self.onRefresh = onRefresh
    }

    /// ScrollView Delegate Methods
    public class Coordinator: NSObject, UIScrollViewDelegate {
        init(parent: ScrollDetector) {
            self.parent = parent
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.onScroll(scrollView.contentOffset.y)
        }

        public func scrollViewWillEndDragging(
            _: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            parent.onDraggingEnd(targetContentOffset.pointee.y, velocity.y)
        }

        public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.panGestureRecognizer.view)
            parent.onDraggingEnd(scrollView.contentOffset.y, velocity.y)
        }

        @objc func handleRefresh() {
            parent.onRefresh()

            refreshControl?.endRefreshing()
        }

        var parent: ScrollDetector

        /// One time Delegate Initialization
        var isDelegateAdded: Bool = false
        var refreshControl: UIRefreshControl?
    }

    public var onScroll: (CGFloat) -> Void
    /// Offset, Velocity
    public var onDraggingEnd: (CGFloat, CGFloat) -> Void
    public var onRefresh: () -> Void

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIView(context _: Context) -> UIView {
        return UIView()
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            /// Adding Delegate for only one time
            /// uiView - Background
            /// .superview = background {}
            /// .superview = VStack {}
            /// .superview = ScrollView {}
            if let scrollview = uiView.superview?.superview?.superview as? UIScrollView, !context.coordinator.isDelegateAdded {
                /// Adding Delegate
                scrollview.delegate = context.coordinator
                context.coordinator.isDelegateAdded = true

                /// Adding refresh control
                let refreshControl = UIRefreshControl()
                refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh), for: .valueChanged)
                scrollview.refreshControl = refreshControl
                context.coordinator.refreshControl = refreshControl
            }
        }
    }
}
