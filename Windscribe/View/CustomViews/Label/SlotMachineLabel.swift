//
//  SlotMachineLabel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 03/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class SlotMachineLabel: UIView {

    // Properties
    private var characterViews: [CharacterRollerView] = []
    private var currentText: String = ""
    private var blurLabel: BlurredLabel?

    var font: UIFont = UIFont.systemFont(ofSize: 16) {
        didSet {
            updateFont()
            blurLabel?.font = font
        }
    }

    var textColor: UIColor = .white {
        didSet {
            updateTextColor()
            blurLabel?.textColor = textColor
        }
    }

    var textAlignment: NSTextAlignment = .right {
        didSet {
            updateLayout()
            blurLabel?.textAlignment = textAlignment
        }
    }

    var isBlurring: Bool = false {
        didSet {
            updateBlurState()
        }
    }

    var blurRadius: Double = 10 {
        didSet {
            blurLabel?.blurRadius = blurRadius
        }
    }

    // Animation configuration
    private let baseDuration: TimeInterval = 1.2
    private let staggerRange: (min: TimeInterval, max: TimeInterval) = (0.0, 0.05)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = false
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    private func updateBlurState() {
        if isBlurring {
            addBlurOverlay()
        } else {
            removeBlurOverlay()
        }
    }

    private func addBlurOverlay() {
        guard blurLabel == nil else { return }

        guard !currentText.isEmpty else { return }

        let blur = BlurredLabel(frame: bounds).then {
            $0.font = font
            $0.textColor = textColor
            $0.textAlignment = textAlignment
            $0.text = currentText
            $0.blurRadius = blurRadius
            $0.isUserInteractionEnabled = false
            $0.backgroundColor = .clear
        }

        addSubview(blur)
        blurLabel = blur

        // Set isBlurring AFTER adding to view hierarchy and force display
        blur.isBlurring = true
        blur.setNeedsDisplay()
        blur.layer.displayIfNeeded()

        // Hide original character views
        characterViews.forEach { $0.isHidden = true }
    }

    private func removeBlurOverlay() {
        blurLabel?.removeFromSuperview()
        blurLabel = nil

        // Show original character views
        characterViews.forEach { $0.isHidden = false }
    }

    func setText(_ newText: String, animated: Bool = true) {
        if !animated {
            currentText = newText
            updateCharactersImmediate(newText)

            // If blur is ON but overlay doesn't exist yet, create it now
            if isBlurring && blurLabel == nil && !newText.isEmpty {
                addBlurOverlay()
            } else if let blur = blurLabel {
                blur.text = newText
                blur.setNeedsDisplay()
            }
            return
        }

        animateTextChange(from: currentText, to: newText)
        currentText = newText

        // If blur is ON but overlay doesn't exist yet, create it now
        if isBlurring && blurLabel == nil && !newText.isEmpty {
            addBlurOverlay()
        } else if let blur = blurLabel {
            blur.text = newText
            blur.setNeedsDisplay()
        }
    }

    private func updateFont() {
        characterViews.forEach { $0.font = font }
        updateLayout()
    }

    private func updateTextColor() {
        characterViews.forEach { $0.textColor = textColor }
    }

    private func updateLayout() {
        guard !characterViews.isEmpty else { return }

        let totalWidth = characterViews.reduce(0) { $0 + $1.intrinsicContentSize.width }
        let maxHeight = characterViews.map { $0.intrinsicContentSize.height }.max() ?? 0
        let viewHeight = bounds.height > 0 ? bounds.height : maxHeight

        var xOffset: CGFloat = 0

        // Calculate starting position based on alignment
        // Use max of bounds.width and totalWidth to avoid negative offsets
        let containerWidth = max(bounds.width, totalWidth)

        switch textAlignment {
        case .right:
            xOffset = max(0, containerWidth - totalWidth)  // Ensure never negative
        case .center:
            xOffset = max(0, (containerWidth - totalWidth) / 2)
        case .left:
            xOffset = 0
        default:
            xOffset = 0
        }

        for view in characterViews {
            let size = view.intrinsicContentSize
            view.frame = CGRect(x: xOffset, y: 0, width: size.width, height: viewHeight)
            xOffset += size.width
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
        blurLabel?.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        guard !characterViews.isEmpty else {
            // Return default size when no characters
            let defaultSize = ("0" as NSString).size(withAttributes: [.font: font])
            return CGSize(width: defaultSize.width, height: defaultSize.height)
        }

        let totalWidth = characterViews.reduce(0) { $0 + $1.intrinsicContentSize.width }
        let maxHeight = characterViews.map { $0.intrinsicContentSize.height }.max() ?? 0
        return CGSize(width: totalWidth, height: maxHeight)
    }

    private func updateCharactersImmediate(_ text: String) {
        characterViews.forEach { $0.removeFromSuperview() }
        characterViews.removeAll()

        for char in text {
            let charView = CharacterRollerView(character: String(char), font: font, textColor: textColor)
            charView.isHidden = isBlurring  // Hide immediately if blur is active
            addSubview(charView)
            characterViews.append(charView)
        }

        invalidateIntrinsicContentSize()
        updateLayout()
    }

    private func animateTextChange(from oldText: String, to newText: String) {
        let oldChars = Array(oldText)
        let newChars = Array(newText)

        // If lengths match, just update existing views
        if oldChars.count == newChars.count {
            // Mark layout as needed before updating characters
            invalidateIntrinsicContentSize()
            setNeedsLayout()

            for i in 0..<newChars.count {
                let newChar = String(newChars[i])
                if i < characterViews.count {
                    let view = characterViews[i]
                    let delay = TimeInterval.random(in: staggerRange.min...staggerRange.max)
                    view.animateToCharacter(newChar, delay: delay, duration: baseDuration)
                }
            }

            // Force layout with correct sizes before animations execute
            layoutIfNeeded()
            return
        }

        // Different lengths - recreate all views
        // Remove old views with fade
        for view in characterViews {
            fadeOutAndRemove(view: view)
        }
        characterViews.removeAll()

        // Create new views - start with "0" for digits, actual char for dots
        for char in newText {
            let charString = String(char)
            let initialChar = charString == "." ? "." : "0"
            let charView = CharacterRollerView(character: initialChar, font: font, textColor: textColor)
            charView.alpha = 0
            charView.isHidden = isBlurring  // Hide immediately if blur is active
            addSubview(charView)
            characterViews.append(charView)
        }

        // Update our size and layout
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()

        // Now animate - fade in and slot machine effect
        for (index, char) in newText.enumerated() {
            guard index < characterViews.count else { continue }
            let charView = characterViews[index]
            let charString = String(char)

            // Fade in
            let fadeDelay = TimeInterval.random(in: 0.0...0.05)
            UIView.animate(withDuration: 0.3, delay: fadeDelay) {
                charView.alpha = 1.0
            }

            // Animate digits with slot machine (dots already set correctly)
            if charString != "." {
                let animDelay = TimeInterval.random(in: staggerRange.min...staggerRange.max)
                charView.animateToCharacter(charString, delay: animDelay, duration: baseDuration)
            }
        }
    }

    private func fadeOutAndRemove(view: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            view.alpha = 0
            view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            view.removeFromSuperview()
        })
    }

    private func fadeIn(view: UIView, delay: TimeInterval) {
        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3, delay: delay, options: .curveEaseOut, animations: {
            view.alpha = 1
            view.transform = .identity
        })
    }
}

private class CharacterRollerView: UIView {

    private let characterLabel: UILabel
    private var currentCharacter: String

    var font: UIFont {
        didSet {
            characterLabel.font = font
            invalidateIntrinsicContentSize()
        }
    }

    var textColor: UIColor {
        didSet {
            characterLabel.textColor = textColor
        }
    }

    init(character: String, font: UIFont, textColor: UIColor) {
        self.currentCharacter = character
        self.font = font
        self.textColor = textColor
        self.characterLabel = UILabel()

        super.init(frame: .zero)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = false

        characterLabel.do {
            $0.font = font
            $0.textColor = textColor
            $0.text = currentCharacter
            $0.textAlignment = .center
            $0.backgroundColor = .clear
            $0.isUserInteractionEnabled = false
        }
        addSubview(characterLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        characterLabel.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        let size = (currentCharacter as NSString).size(withAttributes: [.font: font])
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    func animateToCharacter(_ newCharacter: String, delay: TimeInterval, duration: TimeInterval) {
        // Don't animate dots
        if newCharacter == "." || currentCharacter == "." {
            characterLabel.text = newCharacter
            currentCharacter = newCharacter
            invalidateIntrinsicContentSize()
            return
        }

        // Update current character first so size is correct
        currentCharacter = newCharacter
        invalidateIntrinsicContentSize()

        // Then animate
        performSlotMachineAnimation(to: newCharacter, delay: delay, duration: duration)
    }

    private func performSlotMachineAnimation(to newCharacter: String, delay: TimeInterval, duration: TimeInterval) {
        let randomDurationVariation = TimeInterval.random(in: -0.1...0.1)
        let finalDuration = duration + randomDurationVariation

        // Always use intrinsic size for animation (reflects current character size)
        let charSize = intrinsicContentSize
        let digitHeight = charSize.height
        let digitWidth = charSize.width

        // Create a container for rolling digits
        let rollerHeight: CGFloat = digitHeight * 12 // Show 12 digits rolling

        let rollerView = UIView(frame: CGRect(x: 0, y: 0, width: digitWidth, height: rollerHeight))
        rollerView.clipsToBounds = false

        // Generate random digits for rolling effect
        var digits: [String] = []
        for _ in 0..<10 {
            digits.append(String(Int.random(in: 0...9)))
        }
        digits.append(newCharacter) // Final character
        digits.append(newCharacter) // Extra for smooth stop

        // Create labels for each digit
        for (index, digit) in digits.enumerated() {
            let label = UILabel(
                frame: CGRect(x: 0, y: CGFloat(index) * digitHeight, width: digitWidth, height: digitHeight)).then {
                    $0.text = digit
                    $0.font = font
                    $0.textColor = textColor
                    $0.textAlignment = .center

            }

            rollerView.addSubview(label)
        }

        // Add roller to view
        addSubview(rollerView)
        characterLabel.alpha = 0

        // Animate roller
        let finalYPosition = -CGFloat(digits.count - 2) * digitHeight

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Initial fast scroll with blur
            UIView.animate(withDuration: finalDuration * 0.7, delay: 0, options: .curveEaseIn, animations: {
                rollerView.frame.origin.y = finalYPosition * 0.7
                rollerView.alpha = 0.6 // Motion blur effect
            }, completion: { _ in
                // Final part with spring
                UIView.animate(withDuration: finalDuration * 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: .curveEaseOut, animations: {
                    rollerView.frame.origin.y = finalYPosition
                    rollerView.alpha = 1.0
                }, completion: { [weak self] _ in
                    guard let self = self else { return }

                    // Clean up and show final character
                    self.characterLabel.text = newCharacter
                    self.characterLabel.alpha = 1
                    rollerView.removeFromSuperview()
                })
            })
        }
    }
}
