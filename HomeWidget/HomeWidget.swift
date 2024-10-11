//
//  HomeWidget.swift
//  HomeWidget
//
//  Created by Yalcin on 2020-11-13.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import WidgetKit
import SwiftUI
import NetworkExtension
import Swinject
import AppIntents
import os
struct Provider: TimelineProvider {
    // MARK: Dependencies
    private var container: Container = {
        let container = Container(isIntentExt: true)
        return container
    }()

    func getLogger() -> FileLogger {
        return container.resolve(FileLogger.self) ?? FileLoggerImpl()
    }

    func getPreferences() -> Preferences {
        return container.resolve(Preferences.self) ?? SharedSecretDefaults()
    }

    func getVPNManager() -> IntentVPNManager? {
        return container.resolve(IntentVPNManager.self)
    }

    func placeholder(in context: Context) -> SimpleEntry {
        return snapshotEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(snapshotEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        entries.append(snapshotEntry)
        getLogger().logD(self, "Getting widget timeline")
        if let vpnManager = getVPNManager() {
            vpnManager.setup {
                vpnManager.checkConnection {
                    getLogger().logD(self, "Checking connection for manager: isConnected \($0)")
                    let statusValue = $0 ? TextsAsset.Status.on : TextsAsset.Status.off
                    let preferences = getPreferences()
                    let wasConnectionRequested = preferences.getConnectionRequested()
                    if let countryCode = preferences.getcountryCodeKey(),
                       let serverName = preferences.getServerNameKey(),
                       let nickName = preferences.getNickNameKey() {
                        let entry = SimpleEntry(date: Date(),
                                                status: statusValue,
                                                name: serverName,
                                                nickname: nickName,
                                                countryCode: countryCode,
                                                wasConnectionRequested: wasConnectionRequested)

                        entries.append(entry)
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        getLogger().logD(self, "\("Logging Widget state where is connected is: \(String(describing: timeline.entries.last?.status))")")
                        completion(timeline)
                    }
                }
            }
        } else {
            getLogger().logD(self, "No VPN manager.")
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let status: String
    let name: String
    let nickname: String
    let countryCode: String
    let wasConnectionRequested: Bool
}

let snapshotEntry = SimpleEntry(
    date: Date(),
    status: TextsAsset.Status.off,
    name: "Toronto",
    nickname: "The 6",
    countryCode: "CA",
    wasConnectionRequested: false
);

struct HomeWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily

    var isConnected: Bool {
        return entry.status == TextsAsset.Status.on
    }
    var isWidgetSmall: Bool {
        return widgetFamily == .systemSmall
    }

    var connectedBlue = Color(red: 0/255.0, green: 106/255.0, blue: 255/255.0)
    var seaGreen = Color(red: 85/255.0, green: 255/255.0, blue: 138/255.0)
    var midnight = Color(red: 2/255.0, green: 13/255.0, blue: 28/255.0)

    var body: some View {
        ZStack {
            HStack {
                VStack {
                    Image("main-logo").resizable()
                        .frame(width: 24, height: 24).padding(.bottom, 3)
                    HStack {
                        VStack(alignment: .leading, spacing: 3, content: {
                            ZStack {
                                Capsule().fill(isConnected ? midnight.opacity(0.25) : Color.white.opacity(0.25)).frame(width: 36, height: 20)
                                Text(entry.status).foregroundColor(isConnected ? seaGreen : Color.white).font(.custom("IBMPlexSans-Bold", size: 10))
                            }
                            Text(entry.name).foregroundColor(Color.white).font(.custom("IBMPlexSans-Bold", size: isWidgetSmall ? 16 : 21))
                            Text(entry.nickname).foregroundColor(Color.white.opacity(0.7)).font(.custom("IBMPlexSans-Regular", size: isWidgetSmall ? 12 : 16))
                        })
                        Spacer()
                        if !isWidgetSmall {
                            VStack {
                                if isConnected {
                                    if #available(iOSApplicationExtension 17.0, *) {
                                        Button(intent: Disconnect()) {
                                            ConnectButtonImage()
                                        }.buttonStyle(PlainButtonStyle())
                                    } else {
                                        ConnectButtonImage()
                                    }
                                } else {
                                    if #available(iOSApplicationExtension 17.0, *) {
                                        Button(intent: Connect()) {
                                            DisconnectButtonImage()
                                        }.buttonStyle(PlainButtonStyle())
                                    } else {
                                        DisconnectButtonImage()
                                    }
                                }
                            }
                        }
                    }
                }
            }.padding([.trailing, .leading], 16)
                .widgetBackground(
                    ZStack {
                        Image(entry.countryCode).opacity(0.3).scaledToFill()
                        isConnected ? LinearGradient(gradient: Gradient(colors: [connectedBlue, connectedBlue.opacity(0.1)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [.black, Color.black.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
                    }
                )
        }
    }
}

struct ConnectButtonImage: View {
    var body: some View {
        ZStack {
            Image("connect-button").resizable().frame(width: 64, height: 64)
            Image("connect-button-ring").resizable().frame(width: 75, height: 75)
        }
    }
}

struct DisconnectButtonImage: View {
    var body: some View {
        Image("disconnected-button").resizable().frame(width: 64, height: 64)
            .padding(5)
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
