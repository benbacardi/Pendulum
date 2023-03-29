//
//  ImageGalleryOverlay.swift
//  Pendulum
//
//  Created by Ben Cardy on 29/03/2023.
//

import SwiftUI


class PinchZoomView: UIView {
    
    weak var delegate: PinchZoomViewDelgate?
    
    private(set) var scale: CGFloat = 0 {
        didSet {
            delegate?.pinchZoomView(self, didChangeScale: scale)
        }
    }
    
    private(set) var anchor: UnitPoint = .center {
        didSet {
            delegate?.pinchZoomView(self, didChangeAnchor: anchor)
        }
    }
    
    private(set) var offset: CGSize = .zero {
        didSet {
            delegate?.pinchZoomView(self, didChangeOffset: offset)
        }
    }
    
    private(set) var isPinching: Bool = false {
        didSet {
            delegate?.pinchZoomView(self, didChangePinching: isPinching)
        }
    }
    
    private var startLocation: CGPoint = .zero
    private var location: CGPoint = .zero
    private var numberOfTouches: Int = 0
    private var lastScaleValue: CGFloat = 1.0
    
    init() {
        super.init(frame: .zero)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        pinchGesture.cancelsTouchesInView = false
        addGestureRecognizer(pinchGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            isPinching = true
            startLocation = gesture.location(in: self)
            anchor = UnitPoint(x: startLocation.x / bounds.width, y: startLocation.y / bounds.height)
            numberOfTouches = gesture.numberOfTouches
            
        case .changed:
            if gesture.numberOfTouches != numberOfTouches {
                // If the number of fingers being used changes, the start location needs to be adjusted to avoid jumping.
                let newLocation = gesture.location(in: self)
                let jumpDifference = CGSize(width: newLocation.x - location.x, height: newLocation.y - location.y)
                startLocation = CGPoint(x: startLocation.x + jumpDifference.width, y: startLocation.y + jumpDifference.height)
                
                numberOfTouches = gesture.numberOfTouches
            }
            
            scale = gesture.scale
            
            location = gesture.location(in: self)
            offset = CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
            
        case .ended, .cancelled, .failed:
            self.lastScaleValue = 1.0
                        withAnimation(.interactiveSpring()) {
                            isPinching = false
                            scale = 1.0
                            anchor = .center
                            offset = .zero
                        }
        default:
            break
        }
    }
    
}

protocol PinchZoomViewDelgate: AnyObject {
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize)
}

struct PinchZoom: UIViewRepresentable {
    
    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var offset: CGSize
    @Binding var isPinching: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PinchZoomView {
        let pinchZoomView = PinchZoomView()
        pinchZoomView.delegate = context.coordinator
        return pinchZoomView
    }
    
    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }
    
    class Coordinator: NSObject, PinchZoomViewDelgate {
        var pinchZoom: PinchZoom
        
        init(_ pinchZoom: PinchZoom) {
            self.pinchZoom = pinchZoom
        }
        
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool) {
            pinchZoom.isPinching = isPinching
        }
        
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat) {
            pinchZoom.scale = scale
        }
        
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint) {
            pinchZoom.anchor = anchor
        }
        
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize) {
            pinchZoom.offset = offset
        }
    }
}

struct PinchToZoom: ViewModifier {
    @State var scale: CGFloat = 1.0
    @State var anchor: UnitPoint = .center
    @State var offset: CGSize = .zero
    @State var isPinching: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .offset(offset)
            .overlay(PinchZoom(scale: $scale, anchor: $anchor, offset: $offset, isPinching: $isPinching))
    }
}

extension View {
    func pinchToZoom() -> some View {
        self.modifier(PinchToZoom())
    }
}


public struct ImageViewer: View {
    
    @EnvironmentObject var imageViewerController: ImageViewerController
    
    let image: Image
    
    @State var dragOffset: CGSize = CGSize.zero
    @State var dragOffsetPredicted: CGSize = CGSize.zero

    @ViewBuilder
    public var body: some View {
        ZStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(x: self.dragOffset.width, y: self.dragOffset.height)
                .rotationEffect(.init(degrees: Double(self.dragOffset.width / 30)))
                .pinchToZoom()
//                .simultaneousGesture(DragGesture()
//                    .onChanged { value in
//                        self.dragOffset = value.translation
//                        self.dragOffsetPredicted = value.predictedEndTranslation
//                    }
//                    .onEnded { value in
//                        if((abs(self.dragOffset.height) + abs(self.dragOffset.width) > 570) || ((abs(self.dragOffsetPredicted.height)) / (abs(self.dragOffset.height)) > 3) || ((abs(self.dragOffsetPredicted.width)) / (abs(self.dragOffset.width))) > 3) {
//                            withAnimation(.spring()) {
//                                self.dragOffset = self.dragOffsetPredicted
//                            }
////                            self.viewerShown = false
//                            self.imageViewerController.images = []
//
//
//                            return
//                        }
//                        withAnimation(.interactiveSpring()) {
//                            self.dragOffset = .zero
//                        }
//                    }
//                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(red: 0.12, green: 0.12, blue: 0.12, opacity: (1.0 - Double(abs(self.dragOffset.width) + abs(self.dragOffset.height)) / 1000)).edgesIgnoringSafeArea(.all))
        .zIndex(1)
        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        .onAppear() {
            self.dragOffset = .zero
            self.dragOffsetPredicted = .zero
        }
    }
}




struct ImageGalleryOverlay: View {
    
    @EnvironmentObject var imageViewerController: ImageViewerController
    
    @State private var draggedOffset: CGSize = .zero
    @State private var distanceBeyond: CGFloat = .zero
    
    var body: some View {
        if !imageViewerController.images.isEmpty {
            ZStack {
                Rectangle()
                    .opacity(distanceBeyond > 0 ? ((150 - distanceBeyond) / 150.0) : 1)
//                PinchToZoomImage(image: imageViewerController.images.first!.image()!)
                TabView() {
                    ForEach(imageViewerController.images) { eventPhoto in
                        if let image = eventPhoto.image() {
                            ImageViewer(image: image)
                                .offset(y: draggedOffset.height)
//                            PinchToZoomImage(image: image)
//                            ZoomableImageView(image: image)
//                            PhotoDetailView(image: image)
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .pinchToZoom()
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .gesture(DragGesture()
                .onChanged { value in
                    draggedOffset = value.translation
                    withAnimation {
                        distanceBeyond = value.translation.height - 100
                    }
                }
                .onEnded { value in
                    if distanceBeyond > 0 {
                        imageViewerController.dismiss()
                    }
                    withAnimation {
                        draggedOffset = .zero
                        distanceBeyond = .zero
                    }
                }
            )
            .edgesIgnoringSafeArea(.all)
            .statusBarHidden()
        } else {
            EmptyView()
        }
    }
}

struct ImageGalleryOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ImageGalleryOverlay()
            .environmentObject(ImageViewerController())
    }
}
