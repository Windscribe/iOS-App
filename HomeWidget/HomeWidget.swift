//
//  HomeWidget.swift
//  HomeWidget
//
//  Created by Yalcin on 2020-11-13.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import NetworkExtension
import Swinject

struct Provider: IntentTimelineProvider {


    // MARK: Dependencies
    private var container: Container = {
        let container = Container()
        container.injectCore()
        return container
      }()

    func getLogger() -> FileLogger {
        return container.resolve(FileLogger.self) ?? FileLoggerImpl()
    }

    func getPreferences() -> Preferences {
      return container.resolve(Preferences.self) ?? SharedSecretDefaults()
    }

    func placeholder(in context: Context) -> SimpleEntry {
        return snapshotEntry
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(snapshotEntry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        entries.append(snapshotEntry)
        if let selectedServerCredentialsType = getPreferences().getServerCredentialTypeKey(),
            selectedServerCredentialsType == TextsAsset.iKEv2 {
            NEVPNManager.shared().loadFromPreferences { error in
                if error == nil {
                    var statusValue = TextsAsset.Status.off
                    switch NEVPNManager.shared().connection.status {
                    case .connected:
                        statusValue = TextsAsset.Status.on
                    case .disconnected:
                        statusValue = TextsAsset.Status.off
                    default:
                        statusValue = TextsAsset.Status.off
                    }
                    if let countryCode = getPreferences().getcountryCodeKey(),
                       let serverName = getPreferences().getServerNameKey(),
                       let nickName = getPreferences().getNickNameKey() {
                        let entry = SimpleEntry(date: Date(), status: statusValue, name: serverName, nickname: nickName, countryCode: countryCode)
                        entries.append(entry)
                    }
                }
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }
        } else {
            NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
                if error == nil {
                    var statusValue = TextsAsset.Status.off
                    switch managers?.first?.connection.status {
                    case .connected:
                        statusValue = TextsAsset.Status.on
                    case .disconnected:
                        statusValue = TextsAsset.Status.off
                    default:
                        statusValue = TextsAsset.Status.off
                    }
                    if let countryCode = getPreferences().getcountryCodeKey(),
                        let serverName = getPreferences().getServerNameKey(),
                        let nickName = getPreferences().getNickNameKey() {
                        let entry = SimpleEntry(date: Date(),
                                                status: statusValue,
                                                name: serverName,
                                                nickname: nickName,
                                                countryCode: countryCode)
                        entries.append(entry)
                    }
                }
                let timeline = Timeline(entries: entries, policy: .atEnd)
                self.getLogger().logD(self, "\("Logging Widget state where is connected is: \(String(describing: timeline.entries.first?.status))")")

                completion(timeline)
            }
        }

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
        HStack {
            VStack( content: {
                Image("main-logo").resizable()
                    .frame(width: 24, height: 24).padding(.bottom, 3)
                HStack(content: {
                    VStack(alignment: .leading, spacing: 3, content: {
                        ZStack {
                            Capsule().fill(isConnected ? midnight.opacity(0.25) : Color.white.opacity(0.25)).frame(width: 36, height: 20)
                            Text(entry.status).foregroundColor(isConnected ? seaGreen : Color.white).font(.custom("IBMPlexSans-Bold", size: 10))
                        }
                        Text(entry.name).foregroundColor(Color.white).font(.custom("IBMPlexSans-Bold", size: isWidgetSmall ? 16 : 21))
                        Text(entry.nickname).foregroundColor(Color.white.opacity(0.7)).font(.custom("IBMPlexSans-Regular", size: isWidgetSmall ? 12 : 16))
                    })
                    if !isWidgetSmall {
                        Spacer()
                        VStack(content: {
                            Button(action: {
                            }) {
                                if isConnected {
                                    ZStack {
                                        Image("connect-button").resizable().frame(width: 64, height: 64)
                                        Image("connect-button-ring").resizable().frame(width: 75, height: 75)
                                    }
                                } else {
                                    Image("disconnected-button").resizable().frame(width: 64, height: 64)
                                }
                            }.buttonStyle(PlainButtonStyle())
                        })
                    }
                })
            })
        }.padding([.trailing, .leading], 16)
        .widgetBackground(
            ZStack {
                Image(entry.countryCode).opacity(0.3).scaledToFill()
                isConnected ? LinearGradient(gradient: Gradient(colors: [connectedBlue, connectedBlue.opacity(0.1)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [.black, Color.black.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
            }
        )
    }
}

@main
struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
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
