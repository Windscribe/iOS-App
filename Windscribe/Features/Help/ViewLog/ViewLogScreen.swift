//
//  ViewLogScreen.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

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

    @State private var scrollProxy: ScrollViewProxy?
    @State private var pinchFontSize: CGFloat = 12
    @State private var lastMagnificationValue: CGFloat = 1.0

    let minFontSize: CGFloat = 8
    let maxFontSize: CGFloat = 16
    let logID = "debugLog"

    var body: some View {
        BaseContentView {
            ZStack {
                if viewModel.showProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .from(.iconColor, lookAndFeel.isDarkMode)))
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(viewModel.logContent)
                                .font(.system(size: pinchFontSize, design: .monospaced))
                                .foregroundColor(lookAndFeel.isDarkMode ? .white : .black)
                                .padding()
                                .id(logID)
                                .drawingGroup(opaque: false)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value - lastMagnificationValue
                                            lastMagnificationValue = value

                                            let adjustmentFactor: CGFloat = 6.0
                                            let adjustment = delta * adjustmentFactor
                                            let newFont = pinchFontSize + adjustment
                                            pinchFontSize = min(max(newFont, minFontSize), maxFontSize)
                                        }
                                        .onEnded { _ in
                                            lastMagnificationValue = 1.0
                                        }
                                )
                        }
                        .onAppear {
                            scrollProxy = proxy
                            scrollToBottom()
                        }
                        .onChange(of: viewModel.logContent) { _, _ in
                            scrollToBottom()
                        }
                    }
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
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
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

    private func scrollToBottom() {
        Task.delayed(0.75) {
            withAnimation(.easeOut(duration: 0.25)) {
                scrollProxy?.scrollTo(logID, anchor: .bottom)
            }
        }
    }
}
