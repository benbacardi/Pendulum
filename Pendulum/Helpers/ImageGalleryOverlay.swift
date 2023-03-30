//
//  ImageGalleryOverlay.swift
//  Pendulum
//
//  Created by Ben Cardy on 29/03/2023.
//

import SwiftUI

//
//class PinchZoomView: UIView {
//
//    weak var delegate: PinchZoomViewDelgate?
//
//    private(set) var scale: CGFloat = 0 {
//        didSet {
//            delegate?.pinchZoomView(self, didChangeScale: scale)
//        }
//    }
//
//    private(set) var anchor: UnitPoint = .center {
//        didSet {
//            delegate?.pinchZoomView(self, didChangeAnchor: anchor)
//        }
//    }
//
//    private(set) var offset: CGSize = .zero {
//        didSet {
//            delegate?.pinchZoomView(self, didChangeOffset: offset)
//        }
//    }
//
//    private(set) var isPinching: Bool = false {
//        didSet {
//            delegate?.pinchZoomView(self, didChangePinching: isPinching)
//        }
//    }
//
//    private var startLocation: CGPoint = .zero
//    private var location: CGPoint = .zero
//    private var numberOfTouches: Int = 0
//    private var lastScaleValue: CGFloat = 1.0
//
//    init() {
//        super.init(frame: .zero)
//
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
//        pinchGesture.cancelsTouchesInView = false
//        addGestureRecognizer(pinchGesture)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError()
//    }
//
//    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
//
//        switch gesture.state {
//        case .began:
//            isPinching = true
//            startLocation = gesture.location(in: self)
//            anchor = UnitPoint(x: startLocation.x / bounds.width, y: startLocation.y / bounds.height)
//            numberOfTouches = gesture.numberOfTouches
//
//        case .changed:
//            if gesture.numberOfTouches != numberOfTouches {
//                // If the number of fingers being used changes, the start location needs to be adjusted to avoid jumping.
//                let newLocation = gesture.location(in: self)
//                let jumpDifference = CGSize(width: newLocation.x - location.x, height: newLocation.y - location.y)
//                startLocation = CGPoint(x: startLocation.x + jumpDifference.width, y: startLocation.y + jumpDifference.height)
//
//                numberOfTouches = gesture.numberOfTouches
//            }
//
//            scale = gesture.scale
//
//            location = gesture.location(in: self)
//            offset = CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
//
//        case .ended, .cancelled, .failed:
//            self.lastScaleValue = 1.0
//                        withAnimation(.interactiveSpring()) {
//                            isPinching = false
//                            scale = 1.0
//                            anchor = .center
//                            offset = .zero
//                        }
//        default:
//            break
//        }
//    }
//
//}
//
//protocol PinchZoomViewDelgate: AnyObject {
//    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool)
//    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat)
//    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint)
//    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize)
//}
//
//struct PinchZoom: UIViewRepresentable {
//
//    @Binding var scale: CGFloat
//    @Binding var anchor: UnitPoint
//    @Binding var offset: CGSize
//    @Binding var isPinching: Bool
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    func makeUIView(context: Context) -> PinchZoomView {
//        let pinchZoomView = PinchZoomView()
//        pinchZoomView.delegate = context.coordinator
//        return pinchZoomView
//    }
//
//    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }
//
//    class Coordinator: NSObject, PinchZoomViewDelgate {
//        var pinchZoom: PinchZoom
//
//        init(_ pinchZoom: PinchZoom) {
//            self.pinchZoom = pinchZoom
//        }
//
//        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool) {
//            pinchZoom.isPinching = isPinching
//        }
//
//        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat) {
//            pinchZoom.scale = scale
//        }
//
//        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint) {
//            pinchZoom.anchor = anchor
//        }
//
//        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize) {
//            pinchZoom.offset = offset
//        }
//    }
//}
//
//struct PinchToZoom: ViewModifier {
//    @State var scale: CGFloat = 1.0
//    @State var anchor: UnitPoint = .center
//    @State var offset: CGSize = .zero
//    @State var isPinching: Bool = false
//
//    func body(content: Content) -> some View {
//        content
//            .scaleEffect(scale, anchor: anchor)
//            .offset(offset)
//            .overlay(PinchZoom(scale: $scale, anchor: $anchor, offset: $offset, isPinching: $isPinching))
//    }
//}
//
//extension View {
//    func pinchToZoom() -> some View {
//        self.modifier(PinchToZoom())
//    }
//}
//
//
//public struct ImageViewer: View {
//
//    @EnvironmentObject var imageViewerController: ImageViewerController
//
//    let image: Image
//
//    @State var dragOffset: CGSize = CGSize.zero
//    @State var dragOffsetPredicted: CGSize = CGSize.zero
//
//    @ViewBuilder
//    public var body: some View {
//        ZStack {
//            image
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .offset(x: self.dragOffset.width, y: self.dragOffset.height)
//                .rotationEffect(.init(degrees: Double(self.dragOffset.width / 30)))
//                .pinchToZoom()
////                .simultaneousGesture(DragGesture()
////                    .onChanged { value in
////                        self.dragOffset = value.translation
////                        self.dragOffsetPredicted = value.predictedEndTranslation
////                    }
////                    .onEnded { value in
////                        if((abs(self.dragOffset.height) + abs(self.dragOffset.width) > 570) || ((abs(self.dragOffsetPredicted.height)) / (abs(self.dragOffset.height)) > 3) || ((abs(self.dragOffsetPredicted.width)) / (abs(self.dragOffset.width))) > 3) {
////                            withAnimation(.spring()) {
////                                self.dragOffset = self.dragOffsetPredicted
////                            }
//////                            self.viewerShown = false
////                            self.imageViewerController.images = []
////
////
////                            return
////                        }
////                        withAnimation(.interactiveSpring()) {
////                            self.dragOffset = .zero
////                        }
////                    }
////                )
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
////        .background(Color(red: 0.12, green: 0.12, blue: 0.12, opacity: (1.0 - Double(abs(self.dragOffset.width) + abs(self.dragOffset.height)) / 1000)).edgesIgnoringSafeArea(.all))
//        .zIndex(1)
//        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
//        .onAppear() {
//            self.dragOffset = .zero
//            self.dragOffsetPredicted = .zero
//        }
//    }
//}



struct MyImageView: View {
    let image: Image
    
    @State private var imageScale: CGFloat = 1
    @State private var oldScale: CGFloat = 1
    
    @State private var canDrag: Bool = true
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
//        GeometryReader { proxy in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(imageScale)
                .offset(self.dragOffset)
                .gesture(canDrag ?
                         DragGesture()
                             .onChanged { value in
                                 self.dragOffset = value.translation
                             }
                             .onEnded { value in
//                                 self.dragOffset = .zero
                             } : nil)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            self.canDrag = false
                            imageScale = value
                        }
                        .onEnded { value in
                            self.canDrag = true
                            if imageScale < 1 {
                                withAnimation {
                                    imageScale = 1
                                }
                            }
//                            imageScale = 1
                        }
                )
//        }
    }
    
}






struct ImageModifier: ViewModifier {
    private var contentSize: CGSize
    private var min: CGFloat = 1.0
    private var max: CGFloat = 3.0
    @State var currentScale: CGFloat = 1.0

    init(contentSize: CGSize) {
        self.contentSize = contentSize
    }
    
    var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded {
            if currentScale <= min { currentScale = max } else
            if currentScale >= max { currentScale = min } else {
                currentScale = ((max - min) * 0.5 + min) < currentScale ? max : min
            }
        }
    }
    
    func body(content: Content) -> some View {
        ScrollView([.horizontal, .vertical]) {
            content
                .frame(width: contentSize.width * currentScale, height: contentSize.height * currentScale, alignment: .center)
                .modifier(PinchToZoom(minScale: min, maxScale: max, scale: $currentScale))
        }
        .gesture(doubleTapGesture)
        .animation(.easeInOut, value: currentScale)
    }
}

class PinchZoomView: UIView {
    let minScale: CGFloat
    let maxScale: CGFloat
    var isPinching: Bool = false
    var scale: CGFloat = 1.0
    let scaleChange: (CGFloat) -> Void
    
    init(minScale: CGFloat,
           maxScale: CGFloat,
         currentScale: CGFloat,
         scaleChange: @escaping (CGFloat) -> Void) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.scale = currentScale
        self.scaleChange = scaleChange
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
            
        case .changed, .ended:
            if gesture.scale <= minScale {
                scale = minScale
            } else if gesture.scale >= maxScale {
                scale = maxScale
            } else {
                scale = gesture.scale
            }
            scaleChange(scale)
        case .cancelled, .failed:
            isPinching = false
            scale = 1.0
        default:
            break
        }
    }
}

struct PinchZoom: UIViewRepresentable {
    let minScale: CGFloat
    let maxScale: CGFloat
    @Binding var scale: CGFloat
    @Binding var isPinching: Bool
    
    func makeUIView(context: Context) -> PinchZoomView {
        let pinchZoomView = PinchZoomView(minScale: minScale, maxScale: maxScale, currentScale: scale, scaleChange: { scale = $0 })
        return pinchZoomView
    }
    
    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }
}

struct PinchToZoom: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    @Binding var scale: CGFloat
    @State var anchor: UnitPoint = .center
    @State var isPinching: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .animation(.spring(), value: isPinching)
            .overlay(PinchZoom(minScale: minScale, maxScale: maxScale, scale: $scale, isPinching: $isPinching))
    }
}









import QuickLook

class MyQLPreviewController: QLPreviewController {
        
       override func viewWillLayoutSubviews() {
          super.viewWillLayoutSubviews()
                        
          // Hide share button.
          if let navigationController = children.first as? UINavigationController,
          let shareItem = navigationController.toolbar.items?.first as? UIBarButtonItem {
             shareItem.isEnabled = false
             shareItem.tintColor = .clear
          }
       }
}

struct PreviewController: UIViewControllerRepresentable {
    let imageViewerController: ImageViewerController
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: context.coordinator,
            action: #selector(context.coordinator.dismiss)
        )
        if let showParticularImage = self.imageViewerController.image {
            controller.currentPreviewItemIndex = self.imageViewerController.images.firstIndex(of: showParticularImage) ?? 1
        }
        let navigationController = UINavigationController(rootViewController: controller)

        //        let layoutContainerView  = controller.view.subviews[1] as! UINavigationBar
//        layoutContainerView.subviews[2].subviews[1].isHidden = true
        
        return navigationController
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func updateUIViewController(
        _ uiViewController: UINavigationController, context: Context) {}
}



class Coordinator: QLPreviewControllerDataSource {
    let parent: PreviewController
    
    init(parent: PreviewController) {
        self.parent = parent
    }
    
    func numberOfPreviewItems(
        in controller: QLPreviewController
    ) -> Int {
        return self.parent.imageViewerController.images.count
    }
    
    func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
    ) -> QLPreviewItem {
        return self.parent.imageViewerController.urls[index] as NSURL
    }
    
    @objc func dismiss() {
        self.parent.imageViewerController.dismiss()
        Task {
            do {
                let temporaryDirectory = FileManager.default.temporaryDirectory
                try FileManager.default.contentsOfDirectory(atPath: temporaryDirectory.path).forEach { file in
                    let fileURL = temporaryDirectory.appendingPathComponent(file)
                    try FileManager.default.removeItem(atPath: fileURL.path)
                }
            } catch {
                appLogger.error("Error cleaning up temporary directory: \(error.localizedDescription)")
            }
        }
    }
    
}



struct PhotoView: View {
    
    @State var scale: CGFloat = 1
    @State var scaleAnchor: UnitPoint = .center
    @State var lastScale: CGFloat = 1
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    @State var debug = ""
    
    let image: UIImage
    
    var body: some View {
        GeometryReader { geometry in
            let magnificationGesture = MagnificationGesture()
                .onChanged{ gesture in
                    scaleAnchor = .center
                    scale = lastScale * gesture
                }
                .onEnded { _ in
                    fixOffsetAndScale(geometry: geometry)
                }
            
            let dragGesture = DragGesture()
                .onChanged { gesture in
                    var newOffset = lastOffset
                    newOffset.width += gesture.translation.width
                    newOffset.height += gesture.translation.height
                    offset = newOffset
                }
                .onEnded { _ in
                    fixOffsetAndScale(geometry: geometry)
                }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .position(x: geometry.size.width / 2,
                          y: geometry.size.height / 2)
                .scaleEffect(scale, anchor: scaleAnchor)
                .offset(offset)
                .gesture(dragGesture)
                .gesture(magnificationGesture)
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func fixOffsetAndScale(geometry: GeometryProxy) {
        let newScale: CGFloat = .minimum(.maximum(scale, 1), 4)
        let screenSize = geometry.size
        
        let originalScale = image.size.width / image.size.height >= screenSize.width / screenSize.height ?
            geometry.size.width / image.size.width :
            geometry.size.height / image.size.height
        
        let imageWidth = (image.size.width * originalScale) * newScale
        
        var width: CGFloat = .zero
        if imageWidth > screenSize.width {
            let widthLimit: CGFloat = imageWidth > screenSize.width ?
                (imageWidth - screenSize.width) / 2
                : 0

            width = offset.width > 0 ?
                .minimum(widthLimit, offset.width) :
                .maximum(-widthLimit, offset.width)
        }
        
        let imageHeight = (image.size.height * originalScale) * newScale
        var height: CGFloat = .zero
        if imageHeight > screenSize.height {
            let heightLimit: CGFloat = imageHeight > screenSize.height ?
                (imageHeight - screenSize.height) / 2
                : 0

            height = offset.height > 0 ?
                .minimum(heightLimit, offset.height) :
                .maximum(-heightLimit, offset.height)
        }
        
        let newOffset = CGSize(width: width, height: height)
        lastScale = newScale
        lastOffset = newOffset
        withAnimation() {
            offset = newOffset
            scale = newScale
        }
    }
}




struct ImageGalleryOverlay: View {
    
    @EnvironmentObject var imageViewerController: ImageViewerController
    
    var body: some View {
        if !imageViewerController.images.isEmpty {
            PreviewController(imageViewerController: imageViewerController)
                .edgesIgnoringSafeArea(.bottom)
//                TabView() {
//                    ForEach(imageViewerController.images) { eventPhoto in
//                        if let image = eventPhoto.uiImage() {
//                            PhotoView(image: image)
////                            GeometryReader { proxy in
////                                image
////                                    .resizable()
////                                    .aspectRatio(contentMode: .fit)
////                                    .frame(width: proxy.size.width, height: proxy.size.height)
////                                    .clipShape(Rectangle())
////                                    .modifier(ImageModifier(contentSize: CGSize(width: proxy.size.width, height: proxy.size.height)))
////                            }
////                            MyImageView(image: image)
//                        }
//                    }
//                }
//                .tabViewStyle(.page)
//                .edgesIgnoringSafeArea(.all)
//                VStack {
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            imageViewerController.dismiss()
//                        }) {
//                            Image(systemName: "multiply")
//                                .padding(5)
//                        }
//                        .font(.title)
//                        .foregroundColor(.white)
//                        .padding()
//                    }
//                    Spacer()
//                }
//            }
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
