//
//  CKGridView.swift
//  CameKit
//
//  Created by John on 18/01/2019.
//  Copyright © 2019 CameKit. All rights reserved.
//

import UIKit

@objc public class GridView: UIView {
    @objc public var color: UIColor = UIColor.white.withAlphaComponent(0.5) {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.clear
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.0)

        let pairs: [[CGPoint]] = [
            [CGPoint(x: rect.width / 3.0, y: rect.minY), CGPoint(x: rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: 2 * rect.width / 3.0, y: rect.minY), CGPoint(x: 2 * rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: rect.minX, y: rect.height / 3.0), CGPoint(x: rect.maxX, y: rect.height / 3.0)],
            [CGPoint(x: rect.minX, y: 2 * rect.height / 3.0), CGPoint(x: rect.maxX, y: 2 * rect.height / 3.0)]
        ]

        for pair in pairs {
            context.addLines(between: pair)
        }

        context.strokePath()
    }
}
