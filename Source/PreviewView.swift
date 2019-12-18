//
//  CKPreviewView.swift
//  CameKit
//
//  Created by John on 08/01/2019.
//  Copyright © 2019 CameKit. All rights reserved.
//

import UIKit
import AVFoundation

@objc public class PreviewView: UIView {
    private var lastScale: CGFloat = 1.0

    @objc private(set) public var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let previewLayer = previewLayer {
                layer.addSublayer(previewLayer)
            }
        }
    }

    @objc public var session: BaseSession? {
        didSet {
            oldValue?.stop()

            if let session = session {
                previewLayer = AVCaptureVideoPreviewLayer(session: session.session)
                session.previewLayer = previewLayer
                session.overlayView = self
                session.start()
            }
        }
    }

    @objc private(set) public var gridView: GridView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let gridView = self.gridView {
                addSubview(gridView)
            }
        }
    }

    /// 显示网格
    @objc public var showGrid: Bool = false {
        didSet {
            if showGrid == oldValue { return }

            if showGrid {
                gridView = GridView(frame: bounds)
            } else {
                gridView = nil
            }
        }
    }

    @objc public var autorotate: Bool = false {
        didSet {
            if !autorotate {
                previewLayer?.connection?.videoOrientation = .portrait
            }
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

    public override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        gridView?.frame = bounds

        if autorotate {
            previewLayer?.connection?.videoOrientation = UIDevice.current.orientation.videoOrientation
        }
    }

    private func setupView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        addGestureRecognizer(tapGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(recognizer:)))
        addGestureRecognizer(pinchGestureRecognizer)
    }

    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        if let point = previewLayer?.captureDevicePointConverted(fromLayerPoint: location) {
            session?.focus(at: point)
        }
    }

    @objc private func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .began {
            recognizer.scale = lastScale
        }

        let zoom = max(1.0, min(10.0, recognizer.scale))
        session?.zoom = Double(zoom)

        if recognizer.state == .ended {
            lastScale = zoom
        }
    }
}
