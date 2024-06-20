//
//  WSTouchView.swift
//  Windscribe
//
//  Created by Thomas on 22/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit

class WSTouchView: UIView {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        configNormal()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        configHighlight()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        configNormal()
    }

    @objc public func configHighlight() {
    }
    @objc public func configNormal() {
    }
}

class WSTouchStackView: UIStackView {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        configNormal()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        configHighlight()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        configNormal()
    }

    @objc public func configHighlight() {
    }
    @objc public func configNormal() {
    }
}

class WSTouchTableViewCell: UITableViewCell {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        configNormal()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        configHighlight()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        configNormal()
    }

    @objc public func configHighlight() {
    }
    @objc public func configNormal() {
    }
}
