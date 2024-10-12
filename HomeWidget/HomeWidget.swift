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
    let resolver = ContainerResolver()

    fileprivate var logger: FileLogger {
        return resolver.getLogger()
    }

    fileprivate var preferences: Preferences {
        return resolver.getPreferences()
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
        logger.logD(self, "Getting widget timeline")
        getActiveManager { result in
            switch result {
                case .success(let manager):
                    if let entry = buildSimpleEntry(manager: manager) {
                        entries.append(entry)
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        logger.logD(self, "Updated widget with status:  \(manager.connection.status)")
                        completion(timeline)
                    }
                case .failure(let failure):
                    logger.logD(self, "No VPN Configuration found Error: \(failure).")
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
            }
        }
    }

    private func buildSimpleEntry(manager: NEVPNManager) -> SimpleEntry? {
        let statusValue = manager.connection.status == NEVPNStatus.connected ? TextsAsset.Status.on : TextsAsset.Status.off
        if let countryCode = preferences.getcountryCodeKey(),
           let serverName = preferences.getServerNameKey(),
           let nickName = preferences.getNickNameKey() {
           let entry = SimpleEntry(date: Date(), status: statusValue, name: serverName, nickname: nickName, countryCode: countryCode)
           return entry
        }
      return nil
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let status: String
    let name: String
    let nickname: String
    let countryCode: String
}

let snapshotEntry = SimpleEntry(
    date: Date(),
    status: TextsAsset.Status.off,
    name: "Toronto",
    nickname: "The 6",
    countryCode: "CA"
)

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
