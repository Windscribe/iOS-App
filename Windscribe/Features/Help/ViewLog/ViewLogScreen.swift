//
//  ViewLogScreen.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct ViewLogScreen: View {
    @Environment(\.logger) private var logger
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        ViewLogContentView(viewModel: ViewLogScreenViewModel(logger: logger))
            .navigationTitle(TextsAsset.Debug.viewLog)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct ViewLogContentView: View {
    @State var viewModel: ViewLogScreenViewModel

    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var pinchFontSize: CGFloat = 12
    @State private var lastMagnificationValue: CGFloat = 1.0

    private let minFontSize: CGFloat = 8
    private let maxFontSize: CGFloat = 16

    var body: some View {
        BaseContentView {
            ZStack {
                if viewModel.showProgress {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(
                                tint: .from(.iconColor, lookAndFeel.isDarkMode)
                            )
                        )
                } else {
                    LogTextView(
                        text: viewModel.logContent,
                        fontSize: pinchFontSize,
                        textColor: lookAndFeel.isDarkMode ? .white : .black
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value - lastMagnificationValue
                                lastMagnificationValue = value

                                let adjustmentFactor: CGFloat = 6.0
                                let adjustment = delta * adjustmentFactor
                                let newFont = pinchFontSize + adjustment
                                pinchFontSize = min(
                                    max(newFont, minFontSize),
                                    maxFontSize
                                )
                            }
                            .onEnded { _ in
                                lastMagnificationValue = 1.0
                            }
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadLog()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shareLog()
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(
                            .from(.iconColor, lookAndFeel.isDarkMode)
                        )
                })
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showShareSheet },
            set: { viewModel.showShareSheet = $0 }
        )) {
            ShareSheetView(items: [viewModel.logContent])
        }
    }
}

@available(iOS 17.0, *)
private struct LogTextView: UIViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let textColor: UIColor

    func makeUIView(context _: Context) -> LogUITextView {
        let textView = LogUITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.showsVerticalScrollIndicator = true
        textView.textContainerInset = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.allowsNonContiguousLayout = true
        return textView
    }

    func updateUIView(_ textView: LogUITextView, context _: Context) {
        textView.font = .monospacedSystemFont(
            ofSize: fontSize,
            weight: .regular
        )
        textView.textColor = textColor

        guard textView.text != text else { return }
        textView.setLogText(text)
    }
}

@available(iOS 17.0, *)
private final class LogUITextView: UITextView {
    private var isInitialBottomScrollPending = false
    private var previousBottomOffset: CGFloat?
    private var stableLayoutCount = 0

    func setLogText(_ text: String) {
        self.text = text
        selectedRange = NSRange(location: textStorage.length, length: 0)
        isInitialBottomScrollPending = !text.isEmpty
        previousBottomOffset = nil
        stableLayoutCount = 0
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard isInitialBottomScrollPending,
              window != nil,
              bounds.height > 0,
              textStorage.length > 0 else {
            return
        }

        let lastCharacter = NSRange(
            location: textStorage.length - 1,
            length: 1
        )
        layoutManager.ensureLayout(forCharacterRange: lastCharacter)
        scrollRangeToVisible(lastCharacter)

        let bottomOffset = max(
            -adjustedContentInset.top,
            contentSize.height - bounds.height + adjustedContentInset.bottom
        )
        let previousBottomOffset = previousBottomOffset
        self.previousBottomOffset = bottomOffset
        setContentOffset(
            CGPoint(x: contentOffset.x, y: bottomOffset),
            animated: false
        )

        if let previousBottomOffset,
           abs(previousBottomOffset - bottomOffset) < 0.5 {
            stableLayoutCount += 1
        } else {
            stableLayoutCount = 0
        }

        guard stableLayoutCount < 2 else {
            isInitialBottomScrollPending = false
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.setNeedsLayout()
        }
    }
}
