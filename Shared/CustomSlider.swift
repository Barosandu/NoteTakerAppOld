//
//  CustomSlider.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 20.04.2022.
//

import Foundation
import SwiftUI

protocol CustomSliderDelegate {
    func update()
}


struct CustomSlider<BackgroundView: View>: View {
    @EnvironmentObject var scrollEvent: ScrollEnv
    
    @State var scrolling = true
    
    @Binding var value: CGFloat
    var lowerBound: CGFloat
    var upperBound: CGFloat
    var backgroundView: () -> BackgroundView
    
    @State var rectangleWidth: CGFloat = 0
    
    
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.alwaysShowsDecimalSeparator = true
        formatter.minimum = NSNumber(value: 0)
        formatter.maximum = NSNumber(value: 100)
        return formatter
    }()
    
    var body: some View {
        
        HStack {
            GeometryReader { g in
                SliderView(value: $value, range: lowerBound...upperBound, width: g.size.width - 20, scrollEvent: self._scrollEvent)
                
                    
                    
                    
                    .background(
                        self.backgroundView()
                            .frame(height: 20, alignment: .center)
                            .clipShape(Capsule())
                        
                    )
                    
            
            }
            
            
            TextField("V", value: self.$value, formatter: formatter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
            
        }
        
    }
}

struct SliderView: XViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CustomSliderView {
        let slider = CustomSliderView(valuel: self.$value, ww: self.value, in: self.range, width: width, s: self._scrollEvent)
        slider.delegate = context.coordinator
        return slider
    }
    
    func updateUIViewController(_ uiViewController: CustomSliderView, context: Context) {
        
    }
    
    
    
    typealias UIViewControllerType = CustomSliderView
    
    
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: CustomSliderDelegate {
        func update() {
            
        }
        
        var parent: SliderView
        init(_ parent: SliderView) {
            self.parent = parent
        }
    }
    
    func makeNSViewController(context: Context) -> CustomSliderView {
        let slider = CustomSliderView(valuel: self.$value, ww: self.value, in: self.range, width: width, s: self._scrollEvent)
        slider.delegate = context.coordinator
        return slider
    }
    
    func updateNSViewController(_ nsViewController: CustomSliderView, context: Context) {}
    
    typealias NSViewControllerType = CustomSliderView
    
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat>
    var width: CGFloat
    @EnvironmentObject var scrollEvent: ScrollEnv
}

extension Binding {
    
    
    @discardableResult
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

#if os(iOS)
protocol CustomSliderViewProtocol: XViewController, UIGestureRecognizerDelegate {}
#elseif os(macOS)
protocol CustomSliderViewProtocol: XViewController {}
#endif

class CustomSliderView: XViewController, CustomSliderViewProtocol {
    var value: Binding<CGFloat>
    var range: ClosedRange<CGFloat>
    var nsCircleView: XView!
    var width: CGFloat
    
    
    var xOffsetConstraint: NSLayoutConstraint!
    
    var delegate: CustomSliderDelegate!
    
    var maxDotOffset: CGFloat {
        get {
            let dif = self.range.upperBound - self.range.lowerBound
            let dview = self.width
            
            let dv = self.range.upperBound - self.range.lowerBound
            return dv / dif * dview
        }
    }
    
    var minDotOffset: CGFloat {
        get {
            let dif = self.range.upperBound - self.range.lowerBound
            let dview = self.width
            
            let dv: CGFloat = 0
            return dv / dif * dview
        }
    }
    
    
    var dotOffset: CGFloat {
        get {
            let dif = self.range.upperBound - self.range.lowerBound
            let dview = self.width
            
            let dv = self.value.wrappedValue - self.range.lowerBound
            return dv / dif * dview
        }
        set {
            let dvpdif = newValue / self.width
            let dif = self.range.upperBound - self.range.lowerBound
            let dv = dvpdif * dif
            let v = dv + self.range.lowerBound
            self.value.wrappedValue = v
        }
    }
    
    var scrollEvent: EnvironmentObject<ScrollEnv>
    init(valuel: Binding<CGFloat>, ww: CGFloat, in range: ClosedRange<CGFloat>, width: CGFloat, s: EnvironmentObject<ScrollEnv>) {
        self.width = width
        self.range = range
        self.value = valuel
        self.scrollEvent = s
        super.init(nibName: nil, bundle: nil)
        
    }
    
    override func loadView() {
        self.view = XView(frame: .init(x: 0, y: 0, width: 250, height: 250))
    }
    
    func cta() -> CGFloat {
        self.dotOffset < self.width ? self.dotOffset : self.width
    }
    
    func updateConstraints() {
        self.xOffsetConstraint.constant = cta()
        
    }
    
    #if os(iOS)
    var dragGestureRecogniser: UIPanGestureRecognizer!
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        
        return true
    }
    #endif
    
    override func viewDidLoad() {

        let circleView = Color.white.frame(width: 20, height: 20, alignment: .center).clipShape(Circle())
        #if os(iOS)
        self.nsCircleView = XHostingView(rootView: circleView).view
        self.nsCircleView.backgroundColor = .clear
        self.dragGestureRecogniser = UIPanGestureRecognizer.init()
        self.dragGestureRecogniser.delegate = self
        self.dragGestureRecogniser.addTarget(self, action: #selector(self.mouseDragged(_:)))
        self.view.addGestureRecognizer(dragGestureRecogniser)
        
        #elseif os(macOS)
        self.nsCircleView = XHostingView(rootView: circleView)
        #endif
        self.view.addSubview(self.nsCircleView)
        self.nsCircleView.translatesAutoresizingMaskIntoConstraints = false
        self.nsCircleView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.xOffsetConstraint = self.nsCircleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: cta())
        NotificationCenter.default.addObserver(forName: .didChangeColorFromSelection, object: nil, queue: nil) { not in
            self.updateConstraints()
        }
        self.xOffsetConstraint.isActive = true
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #if os(macOS)
    override func mouseEntered(with event: XEvent) {
//        updateConstraints()
    }
    
    override func mouseDragged(with event: XEvent) {
        self.dotOffset = max(min(self.dotOffset + event.deltaX, self.maxDotOffset), self.minDotOffset)
        updateConstraints()
		NotificationCenter.default.post(name: .sliderDidChangeValues, object: nil)
    }
    #endif
    
    
    #if os(iOS)
    
    var oldDotOffset: CGFloat = .zero
    
    @objc
    func mouseDragged(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.oldDotOffset = self.dotOffset
        }
        
        let r = sender.translation(in: self.view).x
        self.dotOffset = max(min(self.oldDotOffset + r, self.maxDotOffset), self.minDotOffset)
        updateConstraints()
    }
    #endif
    
    
    
    
}


