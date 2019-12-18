//
//  CKPhotoSession.swift
//  CameKit
//
//  Created by John on 08/01/2019.
//  Copyright © 2019 CameKit. All rights reserved.
//

import UIKit
import AVFoundation

extension BaseSession.FlashMode {
    var captureFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

@objc public class PhotoSession: BaseSession {
    /// 相机检测类型
    @objc public enum CameraDetection: UInt {
        case none, faces
    }
    /// 闪光灯
    @objc public var flashMode = BaseSession.FlashMode.off
    /// 图片输出
    let photoOutput = AVCapturePhotoOutput()
    /// 包含识别出人脸的框的数组
    var faceDetectionBoxes: [UIView] = []
    /// 成功回调
    var captureCallback: (UIImage, AVCaptureResolvedPhotoSettings) -> Void = { (_, _) in }
    /// 错误回调
    var errorCallback: (Error) -> Void = { (_) in }

    /// 相机位置
    @objc public var cameraPosition = CameraPosition.back {
        didSet {
            do {
                let deviceInput = try BaseSession.captureDeviceInput(type: cameraPosition.deviceType)
                captureDeviceInput = deviceInput
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    /// 重设 DeviceInput
    var captureDeviceInput: AVCaptureDeviceInput? {
        didSet {
            faceDetectionBoxes.forEach({ $0.removeFromSuperview() })
            faceDetectionBoxes = []

            if let oldValue = oldValue {
                session.removeInput(oldValue)
            }

            if let captureDeviceInput = captureDeviceInput {
                session.addInput(captureDeviceInput)
            }
        }
    }

    /// 相机识别类型
    @objc public var cameraDetection = CameraDetection.none {
        didSet {
            if oldValue == cameraDetection { return }

            for output in session.outputs where output is AVCaptureMetadataOutput {
                 session.removeOutput(output)
            }

            faceDetectionBoxes.forEach({ $0.removeFromSuperview() })
            faceDetectionBoxes = []

            if cameraDetection == .faces {
                let metadataOutput = AVCaptureMetadataOutput()
                session.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                if metadataOutput.availableMetadataObjectTypes.contains(.face) {
                    metadataOutput.metadataObjectTypes = [.face]
                }
            }
        }
    }

    @objc public init(position: CameraPosition = .back, detection: CameraDetection = .none) {
        super.init()

        defer {
            cameraPosition = position
            cameraDetection = detection
        }

        session.sessionPreset = .high
        session.addOutput(photoOutput)
    }

    @objc deinit {
        faceDetectionBoxes.forEach({ $0.removeFromSuperview() })
    }

    /// 调用拍照方法
    @objc public func capture(_ callback: @escaping (UIImage, AVCaptureResolvedPhotoSettings) -> Void, _ error: @escaping (Error) -> Void) {
        captureCallback = callback
        errorCallback = error

        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode.captureFlashMode

        if let connection = photoOutput.connection(with: .video) {
            if resolution.width > 0, resolution.height > 0 {
                connection.videoOrientation = .portrait
            } else {
                connection.videoOrientation = UIDevice.current.orientation.videoOrientation
            }
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc public func togglePosition() {
        cameraPosition = cameraPosition == .back ? .front : .back
    }

    @objc public override var zoom: Double {
        didSet {
            guard let device = captureDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = CGFloat(zoom)
                device.unlockForConfiguration()
            } catch {
                //
            }

            if let delegate = self.delegate {
                delegate.didChangeValue(session: self, value: zoom, key: "zoom")
            }
        }
    }

    @objc public var resolution = CGSize.zero {
        didSet {
            guard let deviceInput = captureDeviceInput else { return }
            do {
                try deviceInput.device.lockForConfiguration()

                if
                    resolution.width > 0, resolution.height > 0,
                    let format = BaseSession.deviceInputFormat(input: deviceInput,
                                                              width: Int(resolution.width),
                                                              height: Int(resolution.height))
                {
                    deviceInput.device.activeFormat = format
                } else {
                    session.sessionPreset = .high
                }

                deviceInput.device.unlockForConfiguration()
            } catch {
                //
            }
        }
    }

    @objc public override func focus(at point: CGPoint) {
        if let device = captureDeviceInput?.device, device.isFocusPointOfInterestSupported {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            } catch let error {
                print("Error while focusing at point \(point): \(error)")
            }
        }
    }
}

extension PhotoSession: AVCapturePhotoCaptureDelegate {
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            captureCallback = { (_, _) in }
            errorCallback = { (_) in }
        }

        if let error = error {
            errorCallback(error)
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            errorCallback(CustomError.error("Cannot get photo file data representation"))
            return
        }

        processPhotoData(data: data, resolvedSettings: photo.resolvedSettings)
    }

    // swiftlint:disable function_parameter_count
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                            previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                            resolvedSettings: AVCaptureResolvedPhotoSettings,
                            bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        defer {
            captureCallback = { (_, _) in }
            errorCallback = { (_) in }
        }

        if let error = error {
            errorCallback(error)
            return
        }

        guard
            let photoSampleBuffer = photoSampleBuffer, let previewPhotoSampleBuffer = previewPhotoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer,
                                                                        previewPhotoSampleBuffer: previewPhotoSampleBuffer) else
        {
            errorCallback(CustomError.error("Cannot get photo file data representation"))
            return
        }

        processPhotoData(data: data, resolvedSettings: resolvedSettings)
    }

    private func processPhotoData(data: Data, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        guard let image = UIImage(data: data) else {
            errorCallback(CustomError.error("Cannot get photo"))
            return
        }

        if
            resolution.width > 0, resolution.height > 0,
            let transformedImage = Utils.cropAndScale(image, width: Int(resolution.width),
                                                        height: Int(resolution.height),
                                                        orientation: UIDevice.current.orientation,
                                                        mirrored: cameraPosition == .front)
        {
            captureCallback(transformedImage, resolvedSettings)
            return
        }
        captureCallback(image, resolvedSettings)
    }
}

extension PhotoSession: AVCaptureMetadataOutputObjectsDelegate {
    /// 人脸检测相关
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let faceMetadataObjects = metadataObjects.filter({ $0.type == .face })

        if faceMetadataObjects.count > faceDetectionBoxes.count {
            for _ in 0..<faceMetadataObjects.count - faceDetectionBoxes.count {
                let view = UIView()
                view.layer.borderColor = UIColor.green.cgColor
                view.layer.borderWidth = 1
                overlayView?.addSubview(view)
                faceDetectionBoxes.append(view)
            }
        } else if faceMetadataObjects.count < faceDetectionBoxes.count {
            for _ in 0..<faceDetectionBoxes.count - faceMetadataObjects.count {
                faceDetectionBoxes.popLast()?.removeFromSuperview()
            }
        }

        for i in 0..<faceMetadataObjects.count {
            if let transformedMetadataObject = previewLayer?.transformedMetadataObject(for: faceMetadataObjects[i]) {
                faceDetectionBoxes[i].frame = transformedMetadataObject.bounds
            } else {
                faceDetectionBoxes[i].frame = CGRect.zero
            }
        }
    }
}
