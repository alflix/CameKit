//
//  CKVideoSession.swift
//  CameKit
//
//  Created by John on 09/01/2019.
//  Copyright © 2019 CameKit. All rights reserved.
//

import AVFoundation

extension BaseSession.FlashMode {
    var captureTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

@objc public class VideoSession: BaseSession {
    /// 是否允许拍照，允许的话，在拍摄时间小于 0.5 秒的时候，会输出 UIImage (videoCaptureCallback)
    public var allowTakePhoto: Bool = true
    /// 视频输出
    let movieOutput = AVCaptureMovieFileOutput()
    /// 图片输出
    let photoOutput = AVCapturePhotoOutput()
    /// 视频输出回调
    var recordCallback: (URL) -> Void = { (_) in }
    /// 错误回调
    var errorCallback: (Error) -> Void = { (_) in }
    /// 图片输出回调
    public var captureCallback: (UIImage, AVCaptureResolvedPhotoSettings) -> Void = { (_, _) in }
    /// 拍摄时间小于 0.5 秒的时候，图片输出回调
    public var videoCaptureCallback: (UIImage, AVCaptureResolvedPhotoSettings) -> Void = { (_, _) in }
    /// 是否正在录像
    @objc public private(set) var isRecording = false
    /// 输出图片时，是否正在录像
    @objc public private(set) var isVideoCapture = false
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
            if let oldValue = oldValue {
                session.removeInput(oldValue)
            }

            if let captureDeviceInput = captureDeviceInput {
                session.addInput(captureDeviceInput)
            }
        }
    }

    /// 缩放
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

    /// 闪光灯模式
    @objc public var flashMode = BaseSession.FlashMode.off {
        didSet {
            guard let device = captureDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()
                if device.isTorchModeSupported(flashMode.captureTorchMode) {
                    device.torchMode = flashMode.captureTorchMode
                }
                device.unlockForConfiguration()
            } catch {
                //
            }
        }
    }

    @objc public init(position: CameraPosition = .back) {
        super.init()

        defer {
            cameraPosition = position
            do {
                let microphoneInput = try BaseSession.captureDeviceInput(type: .microphone)
                session.addInput(microphoneInput)
            } catch let error {
                print(error.localizedDescription)
            }
        }

        session.sessionPreset = .hd1920x1080
        session.addOutput(movieOutput)
        if allowTakePhoto {
            session.addOutput(photoOutput)
        }
    }

    /// 开始录像
    @objc public func record(url: URL? = nil, _ callback: @escaping (URL) -> Void, error: @escaping (Error) -> Void) {
        if isRecording { return }

        recordCallback = callback
        errorCallback = error

        let fileUrl: URL = url ?? {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            return fileUrl
            }()

        if let connection = movieOutput.connection(with: .video) {
            connection.videoOrientation = UIDevice.current.orientation.videoOrientation
        }
        movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }

    /// 拍照
    @objc public func capture(_ callback: @escaping (UIImage, AVCaptureResolvedPhotoSettings) -> Void, _ error: @escaping (Error) -> Void) {
        captureCallback = callback
        errorCallback = error
        isVideoCapture = false
        capture()
    }

    /// 调用拍照方法
    @objc func capture() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode.captureFlashMode
        if let connection = photoOutput.connection(with: .video) {
            connection.videoOrientation = UIDevice.current.orientation.videoOrientation
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// 停止录像
    @objc public func stopRecording() {
        if !isRecording { return }
        movieOutput.stopRecording()
    }

    /// 切换摄像头
    @objc public func togglePosition() {
        cameraPosition = cameraPosition == .back ? .front : .back
    }

    @objc public func setWidth(_ width: Int, height: Int, frameRate: Int) {
        guard
            let input = captureDeviceInput,
            let format = BaseSession.deviceInputFormat(input: input, width: width, height: height, frameRate: frameRate)
            else {
                return
        }
        do {
            try input.device.lockForConfiguration()
            input.device.activeFormat = format
            input.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            input.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            input.device.unlockForConfiguration()
        } catch {
            //
        }
    }
}

extension VideoSession: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL,
                           from connections: [AVCaptureConnection]) {
        isRecording = true
    }

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        defer {
            recordCallback = { (_) in }
            errorCallback = { (_) in }
        }

        if let error = error {
            errorCallback(error)
            return
        }
        if CMTimeGetSeconds(output.recordedDuration) < 0.5 {
            isVideoCapture = true
            capture()
            return
        }
        recordCallback(outputFileURL)
    }
}

extension VideoSession: AVCapturePhotoCaptureDelegate {
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

        guard let image = UIImage(data: data) else {
            errorCallback(CustomError.error("Cannot get photo"))
            return
        }
        if isVideoCapture {
            videoCaptureCallback(image, photo.resolvedSettings)
        } else {
            captureCallback(image, photo.resolvedSettings)
        }
    }
}
