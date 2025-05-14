//
//  MenuEntryView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 06/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct MenuEntryView: View {
    let item: any MenuEntryItemType
    let action: (MenuEntryActionType) -> Void

    init(item: any MenuEntryItemType, action: @escaping (MenuEntryActionType) -> Void) {
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct MenuEntryInteractiveView: View {
    let item: any MenuEntryItemType
    let mainAction: MenuEntryActionType
    let action: (MenuEntryActionType) -> Void

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 12) {
                    Image(item.icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.white)

                    Text(item.title)
                        .foregroundColor(.white)
                        .font(.bold(.callout))
                    Spacer()
                    MenuEntryActionView(actionType: mainAction, action: { actionType in
                        action(actionType)
                    })
                }
                if item.secondaryAction.count > 0 {
                    VStack {
                        ForEach(item.secondaryAction, id: \.self) { actionType in
                            MenuEntryActionView(actionType: actionType, action: { actionType in
                                action(actionType)
                            })
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            if let message = item.message {
                HStack {
                    Text(message)
                        .foregroundColor(Color.white.opacity(0.7))
                        .font(.regular(.footnote))
                    Spacer()
                }
                .padding(16)
            }
        }
    }
}

struct MenuEntryInfoView: View {
    let item: any MenuEntryItemType
    var body: some View {
        HStack {
            Text(item.title)
                .foregroundColor(.white)
                .font(.regular(.callout))
            Spacer()
            if let message = item.message {
                Text(message)
                    .foregroundColor(.white)
                    .font(.regular(.callout))
            }
        }
        .padding(16)
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
                        .foregroundColor(Color.white.opacity(0.7))
                        .font(.regular(.callout))
                    if let imageName = actionType.imageName {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
        case let .single(isSelected):
            Button(action: {
                action(.single(isSelected: !isSelected))
            }, label: {
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: 45, height: 25)
                        .cornerRadius(12)
                }
            })
        case let .button(title):
            Button(action: {
                action(.button(title: title))
            }, label: {
                HStack {
                    if let title = title {
                        Text(title)
                            .foregroundColor(Color.white.opacity(0.7))
                            .font(.regular(.callout))
                    }
                    if let imageName = actionType.imageName {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            })
        case let .none(title):
                Button(action: {
                    action(.button(title: title))
                }, label: {
                    Text(title)
                        .foregroundColor(Color.white.opacity(0.7))
                        .font(.regular(.callout))
                })

        case let .secondary(title), let .info(title):
            Button(action: {
                action(.button(title: title))
            }, label: {
                HStack {
                    if let title = title {
                        Text(title)
                            .foregroundColor(Color.white.opacity(0.7))
                            .font(.regular(.callout))
                    }
                    Spacer()
                    if let imageName = actionType.imageName {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            })
        }
    }
}
