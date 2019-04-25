//
//  UIInterfaceOrientation+VideoOrientation.swift
//  FrontCamera
//
//  Created by laprasDrum on 2019/02/14.
//  Copyright © 2019 calap. All rights reserved.
//

import UIKit
import AVFoundation

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation {
        print("\(String(describing: UIApplication.shared.statusBarOrientation.rawValue))")
        switch self {
        case .unknown, .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        @unknown default:
            fatalError()
        }
    }
}
