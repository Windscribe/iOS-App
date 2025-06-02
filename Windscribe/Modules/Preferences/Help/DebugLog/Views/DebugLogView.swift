//
//  DebugLogView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct DebugLogView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var viewModel: DebugLogViewModelImpl

    @State private var scrollProxy: ScrollViewProxy?
    @State private var pinchFontSize: CGFloat = 12
    @State private var lastMagnificationValue: CGFloat = 1.0

    let minFontSize: CGFloat = 8
    let maxFontSize: CGFloat = 16
    let logID = "debugLog"

    init(viewModel: any DebugLogViewModel) {
        guard let model = viewModel as? DebugLogViewModelImpl else {
            fatalError("DebugLogView must be initialized properly with ViewModelImpl")
        }
        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue.ignoresSafeArea()

            if viewModel.showProgress {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.logContent)
                            .font(.system(size: pinchFontSize, design: .monospaced))
                            .foregroundColor(viewModel.isDarkMode ? .white : .black)
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
                    .onChange(of: viewModel.logContent) { _ in
                        scrollToBottom()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadLog()
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    shareLog()
                },label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                })
            }
        }
    }

    private func scrollToBottom() {
        Task.delayed(0.75) {
            withAnimation(.easeOut(duration: 0.25)) {
                scrollProxy?.scrollTo(logID, anchor: .bottom)
            }
        }
    }

    private func shareLog() {
        let logText = viewModel.logContent
        let activityVC = UIActivityViewController(activityItems: [logText], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
           let rootVC = scene.windows
            .first(where: { $0.isKeyWindow })?.rootViewController {

            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}

struct DebugLogText: View {
    let content: String
    let fontSize: CGFloat
    let color: Color

    var body: some View {
        Text(content)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundColor(color)
            .padding()
    }
}
