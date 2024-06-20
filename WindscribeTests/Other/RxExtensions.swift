//
//  RxExtensions.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-28.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

extension Single {
    func wait(_ timeInMs: Int) -> PrimitiveSequence<Trait, Element> {
        return delaySubscription(RxTimeInterval.milliseconds(timeInMs), scheduler: MainScheduler.asyncInstance)
    }
}
