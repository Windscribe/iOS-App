//
//  UITextView+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Swinject
import UIKit

extension UITextView {
    private var logger: FileLogger {
        return Assembler.resolve(FileLogger.self)
    }

    func htmlText(htmlData: Data, font: UIFont = UIFont.text(size: 16), foregroundColor: UIColor = .white) {
        do {
            let attributedString = try NSAttributedString(
                data: htmlData,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )

            let htmlString = NSMutableAttributedString(attributedString: attributedString).then {
                $0.addAttribute(.foregroundColor,
                                        value: foregroundColor,
                                        range: NSRange(location: 0,
                                                       length: attributedString.length))
                $0.addAttribute(.font,
                                        value: font,
                                        range: NSRange(location: 0,
                                                       length: attributedString.length))
            }

            attributedText = htmlString
        } catch {
            logger.logE(
                "HTMLTextView", "Error occured when converting notifications HTML string. \(error.localizedDescription)")
            return
        }
    }

    func scrollToBottom() {
        if text.count > 0 {
            let location = text.count - 1
            let bottom = NSMakeRange(location, 1)
            scrollRangeToVisible(bottom)
        }
    }
}
