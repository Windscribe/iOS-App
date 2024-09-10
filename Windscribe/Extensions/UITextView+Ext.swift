//
//  UITextView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject

extension UITextView {
    private  var logger: FileLogger {
        return  Assembler.resolve(FileLogger.self)
    }

    func htmlText(htmlData: Data,
                  font: UIFont = UIFont.text(size: 16),
                  foregroundColor: UIColor = .white) {
        do {
            let attrString = try NSAttributedString(
                data: htmlData,
                options: [
                    NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
            let htmlString = NSMutableAttributedString(attributedString: attrString)
            htmlString.addAttribute(.foregroundColor,
                                    value: foregroundColor,
                                    range: NSRange(location: 0,
                                                   length: attrString.length))
            htmlString.addAttribute(.font,
                                    value: font,
                                    range: NSRange(location: 0,
                                                   length: attrString.length))
            attributedText = htmlString
        } catch let error {
            logger.logE("HTMLTextView", "Error occured when converting notifications HTML string. \(error.localizedDescription)")
            return
        }
    }

    func scrollToBottom() {
        if self.text.count > 0 {
            let location = self.text.count - 1
            let bottom = NSMakeRange(location, 1)
            self.scrollRangeToVisible(bottom)
        }
    }
}
