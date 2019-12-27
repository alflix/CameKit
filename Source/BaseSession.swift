//
//  CKSession.swift
//  CameKit
//
//  Created by John on 08/01/2019.
//  Copyright © 2019 CameKit. All rights reserved.
//

import AVFoundation
import UIKit

public extension UIDeviceOrientation {
    /// 处理视频的旋转问题
    var videoOrientation: AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}

private extension BaseSession.DeviceType {
    var captureDeviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .frontCamera, .backCamera:
            return .builtInWideAngleCamera
        case .microphone:
            return .builtInMicrophone
        }
    }

    var captureMediaType: AVMediaType {
        switch self {
        case .frontCamera, .backCamera:
            return .video
        case .microphone:
            return .audio
        }
    }

    var capturePosition: AVCaptureDevice.Position {
        switch self {
        case .frontCamera:
            return .front
        case .backCamera:
            return .back
        case .microphone:
            return .unspecified
        }
    }
}

extension BaseSession.CameraPosition {
    var deviceType: BaseSession.DeviceType {
        switch self {
        case .back:
            return .backCamera
        case .front:
            return .frontCamera
        }
    }
}

@objc public protocol CKFSessionDelegate: class {
    @objc func didChangeValue(session: BaseSession, value: Any, key: String)
}

public typealias RecordCallback = (_ url: URL, _ recordedDuration: Float, _ thumbImage: UIImage) -> Void
public typealias CaptureCallback = (UIImage, AVCaptureResolvedPhotoSettings) -> Void

@objc public class BaseSession: NSObject {
    /// 输入设备类型
    @objc public enum DeviceType: UInt {
        case frontCamera, backCamera, microphone
    }

    /// 相机位置
    @objc public enum CameraPosition: UInt {
        case front, back
    }

    /// 闪光灯模式
    @objc public enum FlashMode: UInt {
        case off, on, auto
    }

    @objc public let session: AVCaptureSession
    /// 预览层
    @objc public var previewLayer: AVCaptureVideoPreviewLayer?
    /// 预览层的容器（overlayView.layer.addSublayer(previewLayer)）
    @objc public var overlayView: UIView?
    /// 缩放等级
    @objc public var zoom = 1.0

    @objc public weak var delegate: CKFSessionDelegate?

    @objc override init() {
        session = AVCaptureSession()
    }

    @objc deinit {
        session.stopRunning()
    }

    @objc public func start() {
        session.startRunning()
    }

    @objc public func stop() {
        session.stopRunning()
    }

    @objc public func focus(at point: CGPoint) {
        //
    }

    /// 根据 DeviceType 输出 AVCaptureDeviceInput
    @objc public static func captureDeviceInput(type: DeviceType) throws -> AVCaptureDeviceInput {
        let captureDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [type.captureDeviceType],
            mediaType: type.captureMediaType,
            position: type.capturePosition)

        guard let captureDevice = captureDevices.devices.first else {
            throw CustomError.captureDeviceNotFound
        }

        return try AVCaptureDeviceInput(device: captureDevice)
    }

    /// 设置输入格式
    /// - Parameters:
    ///   - input: AVCaptureDeviceInput
    ///   - width: 宽度
    ///   - height: 高度
    ///   - frameRate: 帧率
    @objc public static func deviceInputFormat(input: AVCaptureDeviceInput, width: Int, height: Int, frameRate: Int = 30) -> AVCaptureDevice.Format? {
        for format in input.device.formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dimension.width >= width && dimension.height >= height {
                for range in format.videoSupportedFrameRateRanges {
                    if Int(range.maxFrameRate) >= frameRate && Int(range.minFrameRate) <= frameRate {
                        return format
                    }
                }
            }
        }
        return nil
    }
}
