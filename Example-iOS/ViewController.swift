//
//  ViewController.swift
//  Example-iOS
//
//  Created by laprasDrum on 2019/04/25.
//  Copyright © 2019 calap. All rights reserved.
//

import UIKit
import AVFoundation

import FrontCamera

class ViewController: UIViewController {

    var camera: FrontCamera?

    @IBAction func didPhotoButtonTouch(_ sender: Any) {
        checkPermission { [weak self] (granted) in
            guard granted else { return }
            self?.camera = FrontCamera()
            DispatchQueue.main.async {
                self?.camera?.capture(then: { (image) in
                    // use image for what you want to
                })
            }
        }
    }

    func checkPermission(callback: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            callback(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                callback(granted)
            }

        default:
            callback(false)
        }
    }
}

