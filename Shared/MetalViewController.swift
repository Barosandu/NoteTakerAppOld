//
//  MetalViewController.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 27.04.2022.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Metal
import MetalKit
import SwiftUI

struct EditGraphView: XViewControllerRepresentable {
    func makeUIViewController(context: Context) -> EditGraphViewController {
        return EditGraphViewController(scrollEnv: self._scrollEnv)
    }
    
    func updateUIViewController(_ uiViewController: EditGraphViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = EditGraphViewController
    
    @EnvironmentObject var scrollEnv: ScrollEnv
    
    
    func makeNSViewController(context: Context) -> EditGraphViewController {
        return EditGraphViewController(scrollEnv: self._scrollEnv)
    }
    
    func updateNSViewController(_ nsViewController: EditGraphViewController, context: Context) {
        
    }
    
    typealias NSViewControllerType = EditGraphViewController
    
    
    
}

class EditGraphViewController: XViewController {
    var renderer: Renderer!
    var mtkView: MTKView!
    var sEnv: EnvironmentObject<ScrollEnv>
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>) {
        self.sEnv = scrollEnv
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView = MTKView(frame: XRect(x: 0, y: 0, width: 300, height: 300))
        let mdevice = MTLCreateSystemDefaultDevice()
        mtkView.device = mdevice
        renderer = Renderer(scrollEnv: self.sEnv)
        mtkView.framebufferOnly = false
        mtkView.delegate = renderer
        self.view.addSubview(mtkView)
        self.mtkView.translatesAutoresizingMaskIntoConstraints = false
        self.mtkView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.mtkView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.mtkView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.mtkView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
    
    }
    
    override func loadView() {
        self.view = MTKView()
    }
}

struct MAXLEN {
    static var equation = 50
}

public class Renderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var queue: MTLCommandQueue!
    var computeState: MTLComputePipelineState!
    var sEnv: EnvironmentObject<ScrollEnv>
    
    
    
    var offsetScaleBuffer: MTLBuffer!
    var offsetScaleValue = matrix_float2x2([0, 0], [0, 0])
    
    var equationBuffer: MTLBuffer!
    var equationValue: [CChar] = []
    
    var equationLengthBuffer: MTLBuffer!
    var equationLengthValue: Int = 0
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>) {
        self.sEnv = scrollEnv
        super.init()
        registerShaders()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//        view.setFrameSize(NSSize(width: size.width, height: size.height))
    }
    
    public func draw(in view: MTKView) {
        if let drawable = view.currentDrawable,
           let commandBuffer = queue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            commandEncoder.setComputePipelineState(computeState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            
            commandEncoder.setBuffer(self.offsetScaleBuffer, offset: 0, index: 0)
            commandEncoder.setBuffer(self.equationBuffer, offset: 0, index: 1)
            commandEncoder.setBuffer(self.equationLengthBuffer, offset: 0, index: 2)
            
            
            
            
            self.offsetScaleValue[0][0] = Float(self.sEnv.wrappedValue.graphOffset.x)
            self.offsetScaleValue[0][1] = Float(self.sEnv.wrappedValue.graphOffset.y)
            self.offsetScaleValue[1][1] = Float(self.sEnv.wrappedValue.graphScale)
            #if os(macOS)
            self.offsetScaleValue[1][0] = Float(UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? 1 : 0)
            #elseif os(iOS)
            self.offsetScaleValue[1][0] = Float(view.traitCollection.userInterfaceStyle == .dark ? 1 : 0)
            #endif
            self.equationValue = Array(self.sEnv.wrappedValue.firstSelected().textValue.replacingOccurrences(of: "{", with: "(").replacingOccurrences(of: "}", with: ")")).map({ c in
                return CChar(c.asciiValue!)
            })
//            //print(self.equationValue)
            self.equationLengthValue = self.equationValue.count
            
//            //print(self.equationValue.map({ ii in
//                UnicodeScalar(Int(ii))!
//            }))
            
            
            let offsetScalePointer = self.offsetScaleBuffer.contents()
            memcpy(offsetScalePointer, &offsetScaleValue, MemoryLayout<matrix_float2x2>.size)
            
            let eqPointer = self.equationBuffer.contents()
            memcpy(eqPointer, &equationValue, MemoryLayout<CChar>.size * MAXLEN.equation)
            
            let lenPointer = self.equationLengthBuffer.contents()
            memcpy(lenPointer, &equationLengthValue, MemoryLayout<Int>.size)
            
            
            
            let threadGroupCount = MTLSizeMake(10, 10, 1)
            let threadGroups = MTLSizeMake(drawable.texture.width / threadGroupCount.width, drawable.texture.height / threadGroupCount.height, 1)
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
	
    func registerShaders() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.queue = device.makeCommandQueue()
        let library = device.makeDefaultLibrary()!
        let kernel = library.makeFunction(name: "compute_graph")!
        self.computeState = try! device.makeComputePipelineState(function: kernel)
        self.offsetScaleBuffer = device.makeBuffer(length: MemoryLayout<matrix_float2x2>.size, options: [])
        self.equationBuffer = device.makeBuffer(length: MAXLEN.equation * MemoryLayout<CChar>.size, options: [])
        self.equationLengthBuffer = device.makeBuffer(length: MemoryLayout<Int>.size, options: [])
    }
}
