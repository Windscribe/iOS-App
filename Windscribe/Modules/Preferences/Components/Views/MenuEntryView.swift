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
    let action: (MenuEntryActionResponseType) -> Void

    init(item: any MenuEntryHeaderType, action: @escaping (MenuEntryActionResponseType) -> Void) {
        self.item = item
        self.action = action
    }

    var body: some View {
        VStack {
            if item.action != nil || item.secondaryEntries.count != 0 {
                MenuEntryInteractiveView(item: item, action: action)
            } else {
                MenuEntryInfoView(item: item)
            }
        }
        .background(.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct MenuEntryHeaderView: View {
    let item: any MenuEntryItemType
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
                    .foregroundColor(.white)
            }
            if !item.title.isEmpty {
                Text(item.title)
                    .foregroundColor(.white)
                    .font(.medium(.callout))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let mainAction = item.action {
                MenuEntryActionView(actionType: mainAction, isAlignLeading: isActionLeading, action: { actionType in
                    action(actionType)
                })
            }
        }
    }
}

struct MenuEntryInteractiveView: View {
    let item: any MenuEntryHeaderType
    let action: (MenuEntryActionResponseType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                MenuEntryHeaderView(item: item, action: action)
                if let message = item.message {
                    MenuInfoText(text: message)
                }
            }
            .padding(14)
            if item.secondaryEntries.count > 0 {
                VStack(spacing: 14) {
                    ForEach(item.secondaryEntries, id: \.self) { entry in
                        if entry.hasSeparator {
                            Rectangle()
                                .fill(Color.nightBlue)
                                .frame(height: 1)
                        }
                        MenuEntryHeaderView(item: entry, action: action)
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
        .padding(14)
    }
}

struct MenuEntryActionView: View {
    let actionType: MenuEntryActionType
    let isAlignLeading: Bool
    let action: (MenuEntryActionResponseType) -> Void

    var body: some View {
        switch actionType {
        case let .multiple(currentOption, options, parentId):
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option, action: {
                        action(.multiple(newOption: option, parentId: parentId))
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
                    if isAlignLeading {
                        Spacer()
                    }
                }
            }
        case let .toggle(isSelected, parentId):
            Button(action: {
                action(.toggle(isSelected: !isSelected, parentId: parentId))
            }, label: {
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: 40, height: 22)
                }
            })
        case let .button(title, parentId), let .link(title, parentId):
            MenuButtonActionView(title: title, actionType: actionType, action: {
                action(.button(parentId: parentId))
            })
        case let .buttonFile(title, fileTypes, parentId):
            MenuFileButtonActionView(title: title,
                                     parentId: parentId,
                                     fileTypes: fileTypes,
                                     actionType: actionType,
                                     action: action)
        case let .buttonFileExport(title, documentInfo, parentId):
            if let documentInfo = documentInfo {
                MenuFileExportButtonActionView(title: title,
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
                    .foregroundColor(.white)
                    .font(.medium(.callout))
            })
            .frame(maxWidth: .infinity, alignment: .center)
        case let .file(value, fileType, parentId):
            MenuFileSelectionView(value: value,
                                  parentId: parentId,
                                  fileTypes: fileType,
                                  actionType: actionType,
                                  action: action)
        case let .infoLink(message, parentId):
            Button {
                action(.infoLink(parentId: parentId))
            } label: {
                Text(message)
                    .foregroundColor(.infoGrey)
                    .font(.regular(.footnote))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case let .field(value, placeHolder, parentId):
            MenuFieldView(value: value, placeHolder: placeHolder, parentId: parentId, action: action)
        }
    }
}

struct MenuFieldView: View {
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
                    .foregroundColor(.infoGrey)
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
                            .foregroundColor(.infoGrey)
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
                        .foregroundColor(.infoGrey)
                        .font(.regular(.callout))
                    Image(ImagesAsset.editPencil)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.infoGrey)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
    }
}

struct MenuButtonActionView: View {
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
    }
}

struct MenuInfoText: View {
    var text: String

    var body: some View {
        Text(text)
            .foregroundColor(.infoGrey)
            .font(.regular(.footnote))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuFileButtonActionView: View {
    let title: String?
    let parentId: Int
    let fileTypes: [UTType]
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionResponseType) -> Void

    @State private var isImporterPresented = false

    var body: some View {
        MenuButtonActionView(title: title, actionType: actionType, action: {
            isImporterPresented = true
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
    let title: String?
    let parentId: Int
    let documentInfo: DocumentFormatInfo
    let actionType: MenuEntryActionType
    let action: (MenuEntryActionResponseType) -> Void

    @State private var isExporterPresented = false
    @State private var exportURL: URL?
    @State private var document: MultiFormatDocument?

    var body: some View {
        MenuButtonActionView(title: title, actionType: actionType, action: {
            document = MultiFormatDocument(documentInfo: documentInfo)
            isExporterPresented = true
        })
        .fileExporter(
                    isPresented: $isExporterPresented,
                    document: document,
                    contentType: documentInfo.type,
                    defaultFilename: documentInfo.tempFileName
                ) { result in
                    switch result {
                    case .success(let url): print("Exported to: \(url)")
                    case .failure(let error): print("Export failed: \(error)")
                    }
                }
    }
}

struct MenuFileSelectionView: View {
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
                    .foregroundColor(Color.white.opacity(0.7))
                    .font(.regular(.callout))
                if let imageName = actionType.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                        .foregroundColor(Color.white.opacity(0.7))
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
            }
        }
    }
}
