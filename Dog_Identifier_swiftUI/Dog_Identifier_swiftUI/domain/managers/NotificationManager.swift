//
//  NotificationManager.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 15/01/2025.
//


import Foundation
import Combine

/// A centralized manager for handling notifications across the app.
final class NotificationManager {
    
    // MARK: - Singleton Instance
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Publishers
    /// Combine publisher for observing the `newPostsSaved` notification.
    let newPostsSavedPublisher = PassthroughSubject<Void, Never>()

    // MARK: - Notification Names
    enum Notifications {
        static let newPostsSaved = Notification.Name("newPostsSaved")
    }

    // MARK: - Methods

    /// Posts the `newPostsSaved` notification.
    func postNewPostsSaved() {
        NotificationCenter.default.post(name: Notifications.newPostsSaved, object: nil)
    }

    /// Subscribes to the `newPostsSaved` notification and forwards it to the Combine publisher.
    func subscribeToNotifications() {
        NotificationCenter.default
            .publisher(for: Notifications.newPostsSaved)
            .sink { [weak self] _ in
                self?.newPostsSavedPublisher.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Private
    /// Set of cancellables to manage Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
}
