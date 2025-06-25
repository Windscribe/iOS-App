//
//  MenuEntryView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 06/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct MenuEntryView: View {
    let item: any MenuEntryHeaderType
    let isDarkMode: Bool
    let action: (MenuEntryActionResponseType) -> Void

    init(item: any MenuEntryHeaderType, isDarkMode: Bool, action: @escaping (MenuEntryActionResponseType) -> Void) {
        self.item = item
        self.action = action
        self.isDarkMode = isDarkMode
    }

    var body: some View {
        VStack {
            if item.action != nil || item.secondaryEntries.count != 0 {
                MenuEntryInteractiveView(item: item, isDarkMode: isDarkMode, action: action)
            } else {
                MenuEntryInfoView(item: item, isDarkMode: isDarkMode)
            }
        }
        .background(Color.from(.backgroundColor, isDarkMode))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct MenuEntryHeaderView: View {
    let item: any MenuEntryItemType
    let isDarkMode: Bool
    let action: (MenuEntryActionResponseType) -> Void
    var isActionLeading: Bool { item.title.isEmpty && item.icon.isEmpty}

    var body: some View {
        HStack(spacing: 12) {
            if !item.icon.isEmpty {
                Image(item.icon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(.from(.iconColor, isDarkMode))
            }
            if !item.title.isEmpty {
                Text(item.title)
                    .foregroundColor(.from(.titleColor, isDarkMode))
                    .font(.medium(.callout))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let mainAction = item.action {
                MenuEntryActionView(
                    actionType: mainAction,
                    isAlignLeading: isActionLeading,
                    isDarkMode: isDarkMode,
                    action: { actionType in
                        action(actionType)
                    }
                )
            }
        }
    }
}

struct MenuEntryHeaderActionView: View {
    let item: any MenuEntryItemType
    let isDarkMode: Bool
    let action: (MenuEntryActionResponseType) -> Void

    var body: some View {
        if let parentId = getButtonParentId() {
            Button {
                action(.button(parentId: parentId))
            } label: {
                MenuEntryHeaderView(item: item, isDarkMode: isDarkMode, action: action)
            }
        } else {
            MenuEntryHeaderView(item: item, isDarkMode: isDarkMode, action: action)
        }
    }

    func getButtonParentId() -> Int? {
        switch item.action {
        case let .button(_, parentId):
            return parentId
        default:
            return nil
        }
    }
}

struct MenuEntryInteractiveView: View {
    let item: any MenuEntryHeaderType
    let isDarkMode: Bool
    let action: (MenuEntryActionResponseType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                MenuEntryHeaderActionView(item: item, isDarkMode: isDarkMode, action: action)
                if let message = item.message {
                    MenuInfoText(isDarkMode: isDarkMode,
                                 text: message)
                }
            }
            .padding(14)
            if item.secondaryEntries.count > 0 {
                VStack(spacing: 14) {
                    ForEach(item.secondaryEntries, id: \.self) { entry in
                        if entry.hasSeparator {
                            Rectangle()
                                .fill(Color.from(.separatorColor, isDarkMode))
                                .frame(height: 1)
                        }
                        MenuEntryHeaderActionView(item: entry, isDarkMode: isDarkMode, action: action)
                            .padding(.horizontal, 14)
                    }
                }
                .padding(.bottom, 14)
            }
        }
    }
}

struct MenuEntryInfoView: View {
    let item: any MenuEntryHeaderType
    let isDarkMode: Bool
    var body: some View {
        HStack {
            Text(item.title)
                .foregroundColor(.from(.titleColor, isDarkMode))
                .font(.medium(.callout))
            Spacer()
            if let message = item.message {
                Text(message)
                    .font(.regular(.callout))
                    .foregroundColor(.infoGrey)
            }
        }
        .padding(14)
    }
}

struct MenuEntryActionView: View {
    let actionType: MenuEntryActionType
    let isAlignLeading: Bool
    let isDarkMode: Bool
    let action: (MenuEntryActionResponseType) -> Void

    var body: some View {
        switch actionType {
        case let .multiple(currentOption, options, parentId):
            MenuMultipleActionView(isDarkMode: isDarkMode,
                                   currentOption: currentOption,
                                   options: options,
                                   parentId: parentId,
                                   isAlignLeading: isAlignLeading,
                                   actionType: actionType,
                                   action: action)
        case let .toggle(isSelected, parentId):
            Button(action: {
                action(.toggle(isSelected: !isSelected, parentId: parentId))
            }, label: {
                if let imageName = actionType.getImageName(for: isDarkMode) {
                    Image(imageName)
                        .resizable()
                        .frame(width: 40, height: 22)
                }
            })
        case let .button(title, parentId), let .link(title, parentId):
            MenuButtonActionView(isDarkMode: isDarkMode,
                                 title: title,
                                 actionType: actionType,
                                 action: {
                action(.button(parentId: parentId))
            })
        case let .buttonFile(title, fileTypes, parentId):
            MenuFileButtonActionView(isDarkMode: isDarkMode,
                                     title: title,
                                     parentId: parentId,
                                     fileTypes: fileTypes,
                                     actionType: actionType,
                                     action: action)
        case let .buttonFileExport(title, documentInfo, parentId):
            if let documentInfo = documentInfo {
                MenuFileExportButtonActionView(isDarkMode: isDarkMode,
                                               title: title,
                                               parentId: parentId,
                                               documentInfo: documentInfo,
                                               actionType: actionType,
                                               action: action)
            }
        case let .none(title, parentId):
            Button(action: {
                action(.none(parentId: parentId))
            }, label: {
                Text(title)
                    .foregroundColor(.from(.titleColor, isDarkMode))
                    .font(.medium(.callout))
            })
            .frame(alignment: .trailing)
        case let .file(value, fileType, parentId):
            MenuFileSelectionView(isDarkMode: isDarkMode,
                                  value: value,
                                  parentId: parentId,
                                  fileTypes: fileType,
                                  actionType: actionType,
                                  action: action)
        case let .infoLink(message, parentId):
            DescriptionWithLearnMore(description: message, isDarkMode: isDarkMode) {
                action(.infoLink(parentId: parentId))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case let .field(value, placeHolder, parentId):
            MenuFieldView(isDarkMode: isDarkMode,
                          value: value,
                          placeHolder: placeHolder,
                          parentId: parentId,
                          action: action)
        }
    }
}

struct MenuMultipleActionView: View {
    let isDarkMode: Bool
    let currentOption: String
    let options: [MenuOption]
    let parentId: Int
    let isAlignLeading: Bool
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionResponseType) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    action(.multiple(newOption: option.fieldKey, parentId: parentId))
                }, label: {
                    HStack {
                        Text(option.title)
                        if option.title == currentOption {
                            Image(ImagesAsset.CheckMarkButton.off)
                        }
                    }
                })
            }
        } label: {
            HStack(spacing: 8) {
                Text(currentOption)
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .font(.regular(.callout))
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                }
                if isAlignLeading {
                    Spacer()
                }
            }
        }
    }
}

struct MenuFieldView: View {
    let isDarkMode: Bool
    let value: String
    let placeHolder: String
    let parentId: Int
    let action: (MenuEntryActionResponseType) -> Void

    @State private var isEditing = false
    @State private var editedValue = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        if isEditing {
            HStack(spacing: 4) {
                TextField(placeHolder, text: $editedValue)
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .font(.regular(.callout))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .focused($isTextFieldFocused)
                Button(action: {
                    isEditing = false
                    isTextFieldFocused = false
                    editedValue = value == placeHolder ? "" : value
                }, label: {
                    HStack {
                        Image(ImagesAsset.closeCross)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.from(.infoColor, isDarkMode))
                    }
                })
                Button(action: {
                    isEditing = false
                    isTextFieldFocused = false
                    action(.field(value: editedValue, parentId: parentId))
                }, label: {
                    HStack {
                        Image(ImagesAsset.greenCheckMark)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.eletricBlue)
                    }
                })
            }
        } else {
            Button(action: {
                isEditing = true
                isTextFieldFocused = true
                editedValue = value == placeHolder ? "" : value
            }, label: {
                HStack {
                    Text(value)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                        .font(.regular(.callout))
                    Image(ImagesAsset.editPencil)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
    }
}

struct MenuButtonActionView: View {
    let isDarkMode: Bool
    let title: String?
    let actionType: MenuEntryActionType
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack {
                if let title = title {
                    Text(title)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                        .font(.regular(.callout))
                }
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                }
            }
        })
    }
}

struct MenuInfoText: View {
    let isDarkMode: Bool
    var text: String

    var body: some View {
        Text(text)
            .foregroundColor(.from(.infoColor, isDarkMode))
            .font(.regular(.footnote))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuFileButtonActionView: View {
    let isDarkMode: Bool
    let title: String?
    let parentId: Int
    let fileTypes: [UTType]
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionResponseType) -> Void

    @State private var isImporterPresented = false

    var body: some View {
        Button(action: {
            isImporterPresented = true
        }, label: {
            HStack {
                if let title = title {
                    Text(title)
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                }
            }
        })
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: fileTypes,
            allowsMultipleSelection: false
        ) { result in
            if let selectedURL = try? result.get().first {
                action(.file(selecteURL: selectedURL, parentId: parentId))
            }
        }
    }
}

struct MenuFileExportButtonActionView: View {
    let isDarkMode: Bool
    let title: String?
    let parentId: Int
    let documentInfo: DocumentFormatInfo
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionResponseType) -> Void

    @State private var isExporterPresented = false
    @State private var exportURL: URL?
    @State private var document: MultiFormatDocument?

    var body: some View {
        Button(action: {
            document = MultiFormatDocument(documentInfo: documentInfo)
            isExporterPresented = true
        }, label: {
            HStack {
                if let title = title {
                    Text(title)
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                }
            }
        })
        .fileExporter(
                    isPresented: $isExporterPresented,
                    document: document,
                    contentType: documentInfo.type,
                    defaultFilename: documentInfo.tempFileName
                ) { result in
                    switch result {
                    case .success:
                        action(.buttonFileExport(success: true, parentId: parentId))
                    case .failure:
                        action(.buttonFileExport(success: false, parentId: parentId))
                    }
                }
    }
}

struct MenuFileSelectionView: View {
    let isDarkMode: Bool
    let value: String
    let parentId: Int
    let fileTypes: [UTType]
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionResponseType) -> Void

    @State private var isImporterPresented = false

    var body: some View {
        Button(action: {
            isImporterPresented = true
        }, label: {
            HStack {
                Text(value)
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .font(.regular(.callout))
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                        .foregroundColor(.from(.infoColor, isDarkMode))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: fileTypes,
            allowsMultipleSelection: false
        ) { result in
            if let selectedURL = try? result.get().first {
                action(.file(selecteURL: selectedURL, parentId: parentId))
            } else {
                action(.file(selecteURL: nil, parentId: parentId))
            }
        }
    }
}
