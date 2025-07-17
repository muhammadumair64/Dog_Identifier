//
//  AutoScrollingView.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 05/02/2025.
//
import SwiftUI

struct AutoScrollingView<Content: View>: UIViewRepresentable {
    var content: Content
    let timerInterval: TimeInterval = 0 // 0.02 Lower value for smoother scrolling
    let scrollSpeed: CGFloat = 0 //0.5 Pixels per timer tick
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = false
        scrollView.isScrollEnabled = true // Allow manual scrolling
        scrollView.bounces = false
        scrollView.delegate = context.coordinator // Handle user interactions
        
        // Set up hosting controller for SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)
        
        // Pin SwiftUI content to UIScrollView
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        context.coordinator.startAutoScroll(scrollView)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(timerInterval: timerInterval, scrollSpeed: scrollSpeed)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        private var timer: Timer?
        private let timerInterval: TimeInterval
        private let scrollSpeed: CGFloat
        private var isUserScrolling = false
        
        init(timerInterval: TimeInterval, scrollSpeed: CGFloat) {
            self.timerInterval = timerInterval
            self.scrollSpeed = scrollSpeed
        }
        
        func startAutoScroll(_ scrollView: UIScrollView) {
            timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
                guard let self = self, !self.isUserScrolling else { return }
                
                let currentOffset = scrollView.contentOffset.x
                let maxOffset = scrollView.contentSize.width - scrollView.bounds.width
                
                // Reset to the beginning when reaching the end
                if currentOffset >= maxOffset {
                    scrollView.setContentOffset(.zero, animated: false)
                } else {
                    scrollView.setContentOffset(CGPoint(x: currentOffset + self.scrollSpeed, y: 0), animated: false)
                }
            }
        }
        
        func stopAutoScroll() {
            timer?.invalidate()
            timer = nil
        }
        
        // MARK: - UIScrollViewDelegate Methods
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isUserScrolling = true
            stopAutoScroll()
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isUserScrolling = false
                startAutoScroll(scrollView)
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isUserScrolling = false
            startAutoScroll(scrollView)
        }
        
        deinit {
            stopAutoScroll()
        }
    }
}
