//
//  FrontCamera.swift
//  FrontCamera
//
//  Created by laprasDrum on 2019/02/14.
//  Copyright © 2019 calap. All rights reserved.
//

import UIKit
import AVFoundation

/// Calls a front camera input device.
/// this camera takes photo frame from video stream without shutter sound.
///
///     let camera = FrontCamera()
///     camera.capture { (image) in
///         // You can use image (UIImage) for
///         // - save on the device
///         // - post on Web
///     }
///
public final class FrontCamera: NSObject {
    private let session = AVCaptureSession()
    private let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: AVMediaType.video,
                                                 position: .front)!
    private var cameraInput: AVCaptureDeviceInput {
        return try! AVCaptureDeviceInput(device: camera)
    }
    private let output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
        return output
    }()

    var videoOrientation: AVCaptureVideoOrientation? {
        get {
            return output.connection(with: .video)?.videoOrientation
        }
        set (orientation) {
            if let orientation = orientation {
                output.connection(with: .video)?.videoOrientation = orientation
            }
        }
    }

    public typealias CaptureCallBack = (UIImage) -> Void
    private var captureCallback: CaptureCallBack?

    // https://stackoverflow.com/questions/17820812/ios-avfoundation-image-capture-dark/22995641#22995641
    private let stabilizerTime: TimeInterval = 0.5
    private var canTake = false

    public override init() {
        super.init()
        let input = cameraInput
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            session.addOutput(output)
        }
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
    }

    public func capture(then callback: @escaping CaptureCallBack) {
        videoOrientation = UIApplication.shared.statusBarOrientation.videoOrientation
        captureCallback = callback
        prepare()
    }
}

private extension FrontCamera {
    func prepare() {
        session.startRunning()
        Timer.scheduledTimer(withTimeInterval: stabilizerTime, repeats: false) { (_) in
            self.canTake = true
        }
    }

    func stop() {
        session.stopRunning()
    }

    func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) ->UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return image
    }
}

extension FrontCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard canTake, let callback = captureCallback, let outputImage = getImageFromSampleBuffer(sampleBuffer: sampleBuffer) else {
            return
        }
        canTake = false
        stop()
        callback(outputImage)
        captureCallback = nil
    }
}
