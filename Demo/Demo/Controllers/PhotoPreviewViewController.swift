//
//  PhotoPreviewViewController.swift
//  Demo
//
//  Created by John on 2019/12/26.
//  Copyright © 2019 MessageUI. All rights reserved.
//

import UIKit
import GGUI

class PhotoPreviewViewController: UIViewController, UIScrollViewDelegate {
    var doneBlock: (() -> Void)?
    var image: UIImage?
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.image
        let space = (Size.screenHeight - Size.screenWidth * (192/108))/2.0
        topConstraint.constant = space
        bottomConstraint.constant = space
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func handleCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func handleSend(_ sender: Any) {
        doneBlock?()
    }
}
