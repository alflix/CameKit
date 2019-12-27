//
//  VideoPreviewViewController.swift
//  Demo
//
//  Created by John on 2019/12/26.
//  Copyright © 2019 MessageUI. All rights reserved.
//

import UIKit
import ZFPlayer
import GGUI

class VideoControlView: UIView, ZFPlayerMediaControl {
    weak var player: ZFPlayerController?
    @IBOutlet private weak var playStateBtn: UIButton!
    var backBlock: VoidBlock?
    var doneBlock: VoidBlock?

    override func awakeFromNib() {
        super.awakeFromNib()
        onTap { [weak self] (_) in
            guard let self = self else { return }
            if self.playStateBtn.isHidden {
                self.player?.currentPlayerManager.pause!()
            }
        }
    }

    func videoPlayer(_ videoPlayer: ZFPlayerController, playStateChanged state: ZFPlayerPlaybackState) {
        switch state {
        case .playStatePlaying:
            playStateBtn.isHidden = true
        case .playStatePaused, .playStatePlayStopped:
            playStateBtn.isHidden = false
        default:
            ()
        }
    }

    @IBAction func play(_ sender: Any) {
        if player?.currentPlayerManager.playState == .playStatePlayStopped {
            player?.currentPlayerManager.replay!()
        } else {
            player?.currentPlayerManager.play!()
        }
    }

    @IBAction func handleCancel(_ sender: Any) {
        player?.currentPlayerManager.stop!()
        backBlock?()
    }

    @IBAction func handleSend(_ sender: Any) {
        player?.currentPlayerManager.stop!()
        doneBlock?()
    }
}

class VideoPreviewViewController: UIViewController {
    var doneBlock: (() -> Void)?
    var url: URL?

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var videoControlView: VideoControlView!

    private let manager = ZFAVPlayerManager()
    private var player: ZFPlayerController!

    override func viewDidLoad() {
        super.viewDidLoad()
        manager.shouldAutoPlay = false
        player = ZFPlayerController.player(withPlayerManager: manager, containerView: view)
        player.pauseWhenAppResignActive = false
        player.controlView = videoControlView
        if let url = url {
            manager.assetURL = url
        }

        videoControlView.backBlock = {
            self.navigationController?.popViewController(animated: true)
        }

        videoControlView.doneBlock = {
            self.doneBlock?()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
