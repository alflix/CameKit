//
//  CameraViewController.swift
//  Worker
//
//  Created by John on 2019/12/12.
//  Copyright © 2019 Ganguo. All rights reserved.
//

import UIKit
import UICircularProgressRing
import SnapKit
import SwifterSwift

enum CameraType {
    case photo(image: UIImage)
    case video(url: URL, duration: Float, snapShot: UIImage)
}

class CameraViewController: UIViewController {
    var doneBlock: ((_ resource: CameraType) -> Void)?

    lazy private var progressRing: UICircularTimerRing = {
        let ring = UICircularTimerRing()
        ring.outerRingColor = .backgroundGray
        ring.innerRingColor = .maize
        ring.shouldShowValueText = false
        ring.style = .ontop
        ring.outerRingWidth = 7
        ring.innerRingWidth = 6.8
        ring.innerRingSpacing = 0.2
        ring.startAngle = -90
        ring.isUserInteractionEnabled = true
        return ring
    }()

    @IBOutlet private weak var progressRingBackgroundView: UIView!
    @IBOutlet private weak var previewView: PreviewView! {
        didSet {
            let session = VideoSession()
            previewView.autorotate = true
            previewView.session = session
            previewView.previewLayer?.videoGravity = .resizeAspectFill
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewView.session?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    func setupSubViews() {
        progressRingBackgroundView.addSubview(progressRing)
        progressRing.snp.makeConstraints { (make) in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        progressRing.onTap { [weak self] (_) in
            self?.takePicyture()
        }
        progressRing.onLongPress { [weak self] (ges) in
            guard let self = self else { return }
            switch ges.state {
            case .began:
                self.record()
            case .ended:
                self.stopRecord()
            case .cancelled:
                self.stopRecord()
            default:
                ()
            }
        }
    }

    func takePicyture() {
        guard let session = self.previewView.session as? VideoSession else { return }
        session.capture({ [weak self] (image, _) in
            self?.capturePhoto(image: image)
        }) { (_) in
        }
    }

    func record() {
        guard let session = self.previewView.session as? VideoSession else { return }
        if session.isRecording {
            progressRing.resetTimer()
            session.stopRecording()
        } else {
            progressRing.startTimer(to: 15) { [weak progressRing] (state) in
                guard case UICircularTimerRing.State.finished = state else { return }
                progressRing?.resetTimer()
                session.stopRecording()
            }
            session.record({ [weak self] (url, duration, snapShot) in
                guard let self = self else { return }
                guard duration > 0.3 else {
                    self.capturePhoto(image: snapShot)
                    return
                }
                print(url)
                guard let viewController = UIStoryboard.main?.instantiateViewController(withClass: VideoPreviewViewController.self) else { return }
                viewController.url = url
                viewController.doneBlock = { [weak self] in
                    self?.doneBlock?(CameraType.video(url: url, duration: duration, snapShot: snapShot))
                    self?.dismiss(animated: true, completion: nil)
                }
                self.navigationController?.pushViewController(viewController, animated: true)
            }) { (_) in
            }
        }
    }

    func stopRecord() {
        guard let session = self.previewView.session as? VideoSession else { return }
        progressRing.resetTimer()
        session.stopRecording()
    }

    func capturePhoto(image: UIImage) {
        print("拍照")
        guard let photosViewController = UIStoryboard.main?.instantiateViewController(withClass: PhotoPreviewViewController.self) else { return }
        photosViewController.image = image
        photosViewController.doneBlock = { [weak self] in
            self?.doneBlock?(CameraType.photo(image: image))
            self?.dismiss(animated: true, completion: nil)
        }
        navigationController?.pushViewController(photosViewController, animated: true)
    }
}

extension CameraViewController {
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func rotate(_ sender: Any) {
        if let session = self.previewView.session as? VideoSession {
            session.cameraPosition = session.cameraPosition == .front ? .back : .front
        }
    }
}
