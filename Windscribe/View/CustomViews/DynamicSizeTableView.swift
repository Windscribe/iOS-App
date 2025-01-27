//
//  DynamicSizeTableView.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-07-27.
//  Copyright © 2021 Windscribe. All rights reserved.
//
import UIKit

public class DynamicSizeTableView: PlainTableView {
    var maxHeight = CGFloat.infinity

    override public var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override public var intrinsicContentSize: CGSize {
        let height = min(maxHeight, contentSize.height)
        return CGSize(width: contentSize.width,
                      height: height)
    }
}
