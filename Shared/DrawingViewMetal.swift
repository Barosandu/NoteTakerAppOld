//
//  DrawingViewMetal.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 13.05.2022.
//

import Foundation
import Foundation
import AppKit
import Metal
import MetalKit
import SwiftUI

struct DrawViewMetal: NSViewControllerRepresentable {
    @EnvironmentObject var scrollEnv: ScrollEnv
    
    
    func makeNSViewController(context: Context) -> DrawViewController{
        return DrawViewController(scrollEnv: self._scrollEnv)
    }
    
    func updateNSViewController(_ nsViewController: DrawViewController, context: Context) {
        
    }
    
    typealias NSViewControllerType = DrawViewController
    
    
    
}

class DrawViewController: NSViewController {
    var renderer: DrawRenderer!
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
        renderer = DrawRenderer(scrollEnv: self.sEnv)
        mtkView.framebufferOnly = false
        mtkView.delegate = renderer
        self.view.addSubview(mtkView)
        self.mtkView.translatesAutoresizingMaskIntoConstraints = false
        self.mtkView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.mtkView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.mtkView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.mtkView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        
    }
    
    override func magnify(with event: XEvent) {
        renderer.magnify(with: event, in: self)
    }
    
    override func scrollWheel(with event: XEvent) {
        renderer.scrollWheel(with: event, in: self)
    }
    
    override func mouseDown(with event: XEvent) {
        renderer.mouseDown(with: event, in: self)
    }
    
    override func mouseDragged(with event: XEvent) {
        renderer.mouseDragged(with: event, in: self)
    }
    
    override func mouseUp(with event: XEvent) {
        renderer.mouseUp(with: event, in: self)
    }
    
    
    override func loadView() {
        self.view = MTKView()
    }
}


public class DrawRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var queue: MTLCommandQueue!
    var computeState: MTLComputePipelineState!
    var sEnv: EnvironmentObject<ScrollEnv>
    
    var offsetScaleBuffer: MTLBuffer!
    var offsetScaleValue = matrix_float2x2([0, 0], [0, 0])
    
    var pixelToStrokeNumberBuffer: MTLBuffer!
    var pixelToStrokeNumberValue: [Int] = []
    
    
    var trueOffset: CGPoint = .zero
    var trueScale: CGFloat = 1
    
    func magnify(with event: XEvent, in vc: NSViewController) {
        //print("Magnify")
    }
    
    func scrollWheel(with event: XEvent, in vc: NSViewController) {
        //print("Scroll")
    }
    
    func mouseDown(with event: XEvent, in vc: NSViewController) {
        //print("Down")
    }
    
    func mouseDragged(with event: XEvent, in vc: NSViewController) {
        //print("Drag")
    }
    
    func mouseUp(with event: XEvent, in vc: NSViewController) {
        //print("Up")
    }
    
    
    init(scrollEnv: EnvironmentObject<ScrollEnv>) {
        self.sEnv = scrollEnv
        super.init()
        registerShaders()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if let drawable = view.currentDrawable,
           let commandBuffer = queue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            commandEncoder.setComputePipelineState(computeState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            
            commandEncoder.setBuffer(self.offsetScaleBuffer, offset: 0, index: 0)
            commandEncoder.setBuffer(self.pixelToStrokeNumberBuffer, offset: 0, index: 1)
            
            
            
            self.offsetScaleValue[0][0] = Float(self.trueOffset.x)
            self.offsetScaleValue[0][1] = Float(self.trueOffset.y)
            self.offsetScaleValue[1][1] = Float(self.trueScale)
            self.offsetScaleValue[1][0] = Float(UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? 1 : 0)
            
            let offsetScalePointer = self.offsetScaleBuffer.contents()
            memcpy(offsetScalePointer, &offsetScaleValue, MemoryLayout<matrix_float2x2>.size)
            
            let pixelToStrokeNumberPointer = self.pixelToStrokeNumberBuffer.contents()
            memcpy(pixelToStrokeNumberPointer, &pixelToStrokeNumberValue, MemoryLayout<matrix_float4x4>.size)
            
            
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
        let library = try! device.makeDefaultLibrary()!
        let kernel = library.makeFunction(name: "compute_draw")!
        self.computeState = try! device.makeComputePipelineState(function: kernel)
        self.offsetScaleBuffer = device.makeBuffer(length: MemoryLayout<matrix_float2x2>.size, options: [])
        self.pixelToStrokeNumberBuffer = device.makeBuffer(length: MemoryLayout<Int>.size, options: [])
    }
}
