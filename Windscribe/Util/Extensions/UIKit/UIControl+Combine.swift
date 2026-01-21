//
//  UIControl+Combine.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2025-01-20.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Combine

extension UIControl {
    /// Publisher that emits when a control event occurs
    func publisher(for event: UIControl.Event) -> UIControlPublisher {
        return UIControlPublisher(control: self, event: event)
    }
}

extension UIView {
    /// Publisher that emits when a gesture recognizer is triggered
    func gesturePublisher(_ gestureType: GestureType) -> UIGesturePublisher {
        return UIGesturePublisher(view: self, gestureType: gestureType)
    }
}

enum GestureType {
    case tap(numberOfTaps: Int = 1)
}

/// Custom publisher for UIGestureRecognizer events
struct UIGesturePublisher: Publisher {
    typealias Output = UIGestureRecognizer
    typealias Failure = Never

    let view: UIView
    let gestureType: GestureType

    func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        let subscription = UIGestureSubscription(subscriber: subscriber, view: view, gestureType: gestureType)
        subscriber.receive(subscription: subscription)
    }
}

/// Subscription implementation for UIGestureRecognizer events
final class UIGestureSubscription<S: Subscriber>: Subscription where S.Input == UIGestureRecognizer, S.Failure == Never {
    private var subscriber: S?
    private weak var view: UIView?
    private var gestureRecognizer: UIGestureRecognizer?

    init(subscriber: S, view: UIView, gestureType: GestureType) {
        self.subscriber = subscriber
        self.view = view

        switch gestureType {
        case .tap(let numberOfTaps):
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gestureTriggered(_:)))
            tapGesture.numberOfTapsRequired = numberOfTaps
            view.addGestureRecognizer(tapGesture)
            self.gestureRecognizer = tapGesture
        }
    }

    @objc private func gestureTriggered(_ gesture: UIGestureRecognizer) {
        _ = subscriber?.receive(gesture)
    }

    func request(_ demand: Subscribers.Demand) {
        // We don't need to handle demand for gesture events
    }

    func cancel() {
        if let gesture = gestureRecognizer {
            view?.removeGestureRecognizer(gesture)
        }
        subscriber = nil
        view = nil
        gestureRecognizer = nil
    }
}

/// Custom publisher for UIControl events
struct UIControlPublisher: Publisher {
    typealias Output = UIControl
    typealias Failure = Never

    let control: UIControl
    let event: UIControl.Event

    func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: event)
        subscriber.receive(subscription: subscription)
    }
}

/// Subscription implementation for UIControl events
final class UIControlSubscription<S: Subscriber>: Subscription where S.Input == UIControl, S.Failure == Never {
    private var subscriber: S?
    private weak var control: UIControl?
    private let event: UIControl.Event

    init(subscriber: S, control: UIControl, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.event = event

        control.addTarget(self, action: #selector(eventOccurred), for: event)
    }

    @objc private func eventOccurred() {
        guard let control = control else { return }
        _ = subscriber?.receive(control)
    }

    func request(_ demand: Subscribers.Demand) {
        // We don't need to handle demand for control events
    }

    func cancel() {
        control?.removeTarget(self, action: #selector(eventOccurred), for: event)
        subscriber = nil
        control = nil
    }
}
