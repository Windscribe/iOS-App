//
//  MenuEntryViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 06/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UniformTypeIdentifiers
import SwiftUI

struct DocumentFormatInfo: Hashable {
    let fileData: Data
    let type: UTType
    let tempFileName: String
}

struct MenuOption: Hashable {
    let title: String
    let fieldKey: String
}

struct MultiFormatDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText, .json]

    let documentInfo: DocumentFormatInfo

    init(documentInfo: DocumentFormatInfo) {
        self.documentInfo = documentInfo
    }

    init(configuration: ReadConfiguration) throws {
        self.documentInfo = DocumentFormatInfo(fileData: configuration.file.regularFileContents ?? Data(),
                                               type: configuration.contentType, tempFileName: "TempFileName.txt")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: documentInfo.fileData)
    }
}

enum MenuEntryActionType: Hashable {
    case multiple(currentOption: String, options: [MenuOption], parentId: Int)
    case toggle(isSelected: Bool, parentId: Int)
    case button(title: String?, parentId: Int)
    case buttonFile(title: String, fileTypes: [UTType], parentId: Int)
    case buttonFileExport(title: String,
                          documentInfo: DocumentFormatInfo?,
                          parentId: Int)
    case link(title: String?, parentId: Int)
    case none(title: String, parentId: Int)
    case file(value: String, fileTypes: [UTType], parentId: Int)
    case infoLink(message: AttributedString, parentId: Int)
    case field(value: String, placeHolder: String, parentId: Int)

    var imageName: String? {
        switch self {
        case .multiple:
            ImagesAsset.dropDownIcon
        case let .toggle(isSelected, _):
            isSelected ? ImagesAsset.SwitchButton.on : ImagesAsset.SwitchButton.off
        case .button, .buttonFile, .buttonFileExport:
            ImagesAsset.serverWhiteRightArrow
        case .link:
            ImagesAsset.externalLink
        case .file:
            ImagesAsset.editPencil
        default:
            nil
        }
    }

    var parentId: Int {
        switch self {
        case let .multiple(_, _, parentId),
            let .toggle(_, parentId),
            let .button(_, parentId),
            let .link(_, parentId),
            let .none(_, parentId),
            let .file(_, _, parentId),
            let .buttonFile(_, _, parentId),
            let .buttonFileExport(_, _, parentId),
            let .infoLink(_, parentId),
            let .field(_, _, parentId):
            return parentId
        }
    }
}

enum MenuEntryActionResponseType {
    case multiple(newOption: String, parentId: Int)
    case toggle(isSelected: Bool, parentId: Int)
    case button(parentId: Int)
    case link(parentId: Int)
    case none(parentId: Int)
    case file(selecteURL: URL, parentId: Int)
    case fileExport(parentId: Int)
    case infoLink(parentId: Int)
    case field(value: String, parentId: Int)

    var parentId: Int {
        switch self {
        case let .multiple(_, parentId),
            let .toggle(_, parentId),
            let .button(parentId),
            let .link(parentId),
            let .none(parentId),
            let .file(_, parentId),
            let .fileExport(parentId),
            let .infoLink(parentId),
            let .field(_, parentId):
            return parentId
        }
    }
}

struct MenuSecondaryEntryItem: MenuEntryItemType {
    var id: Int
    var title: String
    var icon: String
    var action: MenuEntryActionType?

    static func == (lhs: MenuSecondaryEntryItem, rhs: MenuSecondaryEntryItem) -> Bool {
        lhs.id == rhs.id
    }

    init(entry: any MenuEntryItemType) {
        id = entry.id
        title = entry.title
        icon = entry.icon
        action = entry.action
    }

    var hasSeparator: Bool {
        !(title.isEmpty && icon.isEmpty)
    }

    var isFixedHeight: Bool {
        switch action {
        case .infoLink:
            return false
        default:
            return true
        }
    }
}

protocol MenuEntryHeaderType: MenuEntryItemType {
    var id: Int { get }
    var title: String { get }
    var icon: String { get }
    var message: String? { get }
    var action: MenuEntryActionType? { get }
    var secondaryEntries: [MenuSecondaryEntryItem] { get }
}

protocol MenuEntryItemType: Hashable {
    var id: Int { get }
    var title: String { get }
    var icon: String { get }
    var action: MenuEntryActionType? { get }
}

extension MenuEntryItemType {
    func makeInfoLink(from description: String) -> AttributedString {
        var info = AttributedString("\(description) \(TextsAsset.learnMore)")
        if let range = info.range(of: TextsAsset.learnMore) {
            info[range].foregroundColor = .learnBlue
        }
        return info
    }
}
