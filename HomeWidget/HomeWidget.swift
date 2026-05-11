//
//  HomeWidget.swift
//  HomeWidget
//
//  Created by Yalcin on 2020-11-13.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import AppIntents
import NetworkExtension
import os
import SwiftUI
import Swinject
import WidgetKit

struct Provider: TimelineProvider {
    let resolver = ContainerResolver()

    fileprivate var logger: FileLogger {
        return resolver.getLogger()
    }

    fileprivate var preferences: Preferences {
        return resolver.getPreferences()
    }

    init() {
        LocalizationBridge.setup(resolver.getLocalizationService())
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        logger.logD("AppIntents", message)
        #endif
    }

    func placeholder(in _: Context) -> SimpleEntry {
        return snapshotEntry
    }

    func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(snapshotEntry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        autoreleasepool {
            var entries: [SimpleEntry] = []
            entries.append(snapshotEntry)
            debugLog("Getting widget timeline")
            let protocolType = self.preferences.getActiveManagerKey() ?? VPNProtocolType.wireGuard.identifier
            getActiveManager(for: protocolType) { result in
                autoreleasepool {
                    switch result {
                    case let .success(manager):
                        if let entry = buildSimpleEntry(manager: manager) {
                            debugLog("Updated widget with status: \(manager.connection.status)")
                            entries.append(entry)
                        }
                    case let .failure(failure):
                        debugLog("No VPN Configuration found Error: \(failure).")
                        let entry = buildErrorEntry(failure: failure)
                        entries.append(entry)
                    }
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                }
            }
        }
    }

    private func buildSimpleEntry(manager: NEVPNManager) -> SimpleEntry? {
        let status: WidgetStatus = manager.connection.status == .connected ? .connected : .disconnected
        if let countryCode = preferences.getcountryCodeKey(),
           let serverName = preferences.getServerNameKey(),
           let nickName = preferences.getNickNameKey()
        {
            let entry = SimpleEntry(date: Date(),
                                    status: status,
                                    name: serverName,
                                    nickname: nickName,
                                    countryCode: countryCode)
            return entry
        }
        return nil
    }

    private func buildErrorEntry(failure: Error) -> SimpleEntry {
        return SimpleEntry(date: Date(),
                           status: WidgetStatus.error(failure.localizedDescription),
                           name: "", nickname: "", countryCode: "CA")
    }
}

enum WidgetStatus: Equatable {
    case disconnected
    case connected
    case error(String)
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let status: WidgetStatus
    let name: String
    let nickname: String
    let countryCode: String
    var statusDescription: String {
        switch status {
        case .disconnected:
            return TextsAsset.Status.off
        case .connected:
            return TextsAsset.Status.on
        case let .error(e):
            return e
        }
    }
}

let snapshotEntry = SimpleEntry(
    date: Date(),
    status: WidgetStatus.disconnected,
    name: "Toronto",
    nickname: "The 6",
    countryCode: "CA"
)

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily

    var isConnected: Bool {
        return (entry as SimpleEntry).status == WidgetStatus.connected
    }

    var isWidgetSmall: Bool {
        return widgetFamily == .systemSmall
    }

    var connectedBlue = Color(red: 0 / 255.0, green: 106 / 255.0, blue: 255 / 255.0)
    var midnight = Color(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0)

    var body: some View {
        ZStack {
            if isWidgetSmall {
                VStack {
                    HStack (alignment: .top, content: {
                        Image("widgetLogo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Spacer()
                        ConnectButton(isConnected: isConnected, isWidgetSmall: isWidgetSmall)
                    })
                    HStack {
                        VStack (alignment: .leading, spacing: 2, content: {
                            ConnectionInfoBubble(isConnected: isConnected,
                                                 description: entry.statusDescription)
                            .padding(.bottom, 4)
                            Text(entry.name).foregroundColor(Color.white)
                                .font(.bold(.callout))
                            Text(entry.nickname).foregroundColor(Color.white)
                                .font(.regular(.caption1))
                        })
                        Spacer()
                    }
                }
                Spacer()
            } else {
                HStack {
                    VStack (alignment: .leading, content: {
                        Image("widgetLogo")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.bottom, 10)
                        ConnectionInfoBubble(isConnected: isConnected,
                                             description: entry.statusDescription)
                        Text(entry.name).foregroundColor(Color.white)
                            .font(.bold(.title3))
                        Text(entry.nickname).foregroundColor(Color.white)
                            .font(.regular(.callout))
                        Spacer()
                    })
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            ConnectButton(isConnected: isConnected, isWidgetSmall: isWidgetSmall)
                            Spacer()
                        }
                    }
                }
            }
        }
        .widgetBackground(
            ZStack {
                Image(entry.countryCode)
                    .resizable()
                    .scaledToFit()
                    .mask(
                        ElipseGradientView()
                    )
                    .opacity(0.2)
                    .padding(.horizontal, isWidgetSmall ? 0 : 33)
                    .padding(.vertical, isWidgetSmall ? 40 : 0)
                if isConnected {
                    ConnectedGradient()
                } else {
                    DisconnectedGradient()
                }
            }.background(Color.nightBlue)
        )
    }
}

struct ConnectButton: View {
    var isConnected: Bool
    let isWidgetSmall: Bool
    var body: some View {
        if isConnected {
            if #available(iOSApplicationExtension 17.0, *) {
                Button(intent: Disconnect()) {
                    ConnectButtonImage(isWidgetSmall: isWidgetSmall)
                }.buttonStyle(PlainButtonStyle())
            } else {
                ConnectButtonImage(isWidgetSmall: isWidgetSmall)
            }
        } else {
            if #available(iOSApplicationExtension 17.0, *) {
                Button(intent: Connect()) {
                    DisconnectButtonImage(isWidgetSmall: isWidgetSmall)
                }.buttonStyle(PlainButtonStyle())
            } else {
                DisconnectButtonImage(isWidgetSmall: isWidgetSmall)
            }
        }
    }
}

struct ConnectButtonImage: View {
    let isWidgetSmall: Bool
    var insideSize: CGFloat { isWidgetSmall ? 48 : 64.0 }
    var outsideSize: CGFloat { isWidgetSmall ? 58 : 75.0 }
    var body: some View {
        ZStack {
            Image(ImagesAsset.connectButton).resizable().frame(width: insideSize, height: insideSize)
            Image(ImagesAsset.connectButtonRing).resizable().frame(width: outsideSize, height: outsideSize)
        }
    }
}

struct DisconnectButtonImage: View {
    let isWidgetSmall: Bool
    var size: CGFloat { isWidgetSmall ? 48 : 64.0 }
    var body: some View {
        Image(ImagesAsset.disconnectedButton).resizable().frame(width: size, height: size)
            .padding(5)
    }
}

struct ElipseGradientView: View {
    var body: some View {
        EllipticalGradient(
            stops: [
                Gradient.Stop(color: .white, location: 0.00),
                Gradient.Stop(color: .white.opacity(0), location: 1.00),
            ],
            center: UnitPoint(x: 0.5, y: 0.5)
        )
    }
}

struct DisconnectedGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: .white.opacity(0), location: 0.00),
                Gradient.Stop(color: .white, location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.5, y: 0.5),
            endPoint: UnitPoint(x: 0.5, y: 0)
        ).opacity(0.15)
    }
}

struct ConnectedGradient: View {
    var body: some View {
        LinearGradient(
        stops: [
        Gradient.Stop(color: Color(red: 0, green: 0.42, blue: 1).opacity(0), location: 0.00),
        Gradient.Stop(color: Color(red: 0, green: 0.42, blue: 1), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.5),
        endPoint: UnitPoint(x: 0.5, y: 0)
        )
    }
}

struct ConnectionInfoBubble: View {
    let isConnected: Bool
    let description: String
    var body: some View {
        HStack {
            Text(description)
                .font(.semiBold(.caption2))
                .foregroundColor(isConnected ? .seaGreen : .white)
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
        .padding(.bottom, 3)
        .background(isConnected ? .seaGreen.opacity(0.1) : Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(isConnected ? .seaGreen.opacity(0.1) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

@available(iOSApplicationExtension 17.0, *)
struct IntentButton: View {
    let intent: any AppIntent

    var body: some View {
        Button(intent: intent) {
            Text("")
                .background(Color.indigo)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }.opacity(0.01)
    }
}

@main
struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Windscribe")
        .description("")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeWidget_Previews: PreviewProvider {
    static var previews: some View {
        HomeWidgetEntryView(entry: snapshotEntry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
