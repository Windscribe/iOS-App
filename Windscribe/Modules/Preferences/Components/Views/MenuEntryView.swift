//
//  MenuEntryView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 06/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct MenuEntryView: View {
    let item: any MenuEntryHeaderType
    let action: (MenuEntryActionType) -> Void

    init(item: any MenuEntryHeaderType, action: @escaping (MenuEntryActionType) -> Void) {
        self.item = item
        self.action = action
    }

    var body: some View {
        VStack {
            if let mainAction = item.mainAction {
                MenuEntryInteractiveView(item: item, mainAction: mainAction, action: action)
            } else {
                MenuEntryInfoView(item: item)
            }
        }
        .padding(14)
        .background(.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct MenuEntryInteractiveView: View {
    let item: any MenuEntryHeaderType
    let mainAction: MenuEntryActionType
    let action: (MenuEntryActionType) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if !item.icon.isEmpty {
                    Image(item.icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.white)
                }
                if !item.title.isEmpty {
                    Text(item.title)
                        .foregroundColor(.white)
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                MenuEntryActionView(actionType: mainAction, action: { actionType in
                    action(actionType)
                })
            }
            .frame(height: 24)
            if let message = item.message {
                HStack {
                    Text(message)
                        .foregroundColor(.infoGrey)
                        .font(.regular(.footnote))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct MenuEntryInfoView: View {
    let item: any MenuEntryHeaderType
    var body: some View {
        HStack {
            Text(item.title)
                .foregroundColor(.white)
                .font(.medium(.callout))
            Spacer()
            if let message = item.message {
                Text(message)
                    .font(.regular(.callout))
                    .foregroundColor(.infoGrey)
            }
        }
    }
}

struct MenuEntryActionView: View {
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionType) -> Void

    var body: some View {
        switch actionType {
        case let .multiple(currentOption, options):
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option, action: {
                        action(.multiple(currentOption: option, options: options))
                    })
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentOption)
                        .foregroundColor(.infoGrey)
                        .font(.regular(.callout))
                    if let imageName = actionType.imageName {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.infoGrey)
                    }
                }
            }
        case let .toggle(isSelected):
            Button(action: {
                action(.toggle(isSelected: !isSelected))
            }, label: {
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: 40, height: 22)
                }
            })
        case let .button(title), let .link(title):
            Button(action: {
                action(.button(title: title))
            }, label: {
                HStack {
                    if let title = title {
                        Text(title)
                            .foregroundColor(.infoGrey)
                            .font(.regular(.callout))
                    }
                    if let imageName = actionType.imageName {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.infoGrey)
                    }
                }
            })
        case let .none(title):
            Button(action: {
                action(.button(title: title))
            }, label: {
                Text(title)
                    .foregroundColor(.white)
                    .font(.medium(.callout))
                    .frame(maxWidth: .infinity, alignment: .center)
            })
        }
    }
}
