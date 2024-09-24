//
//  SymbolPicker.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/07/2024.
//

import SwiftUI

let SYMBOLS = ["airplane", "airplane.circle", "airplane.circle.fill", "allergens", "allergens.fill", "ant", "ant.circle", "ant.circle.fill", "ant.fill", "app.gift", "app.gift.fill", "archivebox", "archivebox.circle", "archivebox.circle.fill", "archivebox.fill", "arrowshape.down", "arrowshape.down.circle", "arrowshape.down.circle.fill", "arrowshape.down.fill", "arrowshape.left", "arrowshape.left.circle", "arrowshape.left.circle.fill", "arrowshape.left.fill", "arrowshape.right", "arrowshape.right.circle", "arrowshape.right.circle.fill", "arrowshape.right.fill", "arrowshape.up", "arrowshape.up.circle", "arrowshape.up.circle.fill", "arrowshape.up.fill", "backpack", "backpack.circle", "backpack.circle.fill", "backpack.fill", "bag", "bag.circle", "bag.circle.fill", "bag.fill", "balloon", "balloon.2", "balloon.2.fill", "balloon.fill", "barcode", "basket", "basket.fill", "bell", "bell.circle", "bell.circle.fill", "bell.fill", "bird", "bird.circle", "bird.circle.fill", "bird.fill", "birthday.cake", "birthday.cake.fill", "bolt", "bolt.circle", "bolt.circle.fill", "bolt.fill", "bolt.shield", "bolt.shield.fill", "bolt.square", "bolt.square.fill", "book", "book.circle", "book.circle.fill", "book.closed", "book.closed.circle", "book.closed.circle.fill", "book.closed.fill", "book.fill", "bookmark", "bookmark.circle", "bookmark.circle.fill", "bookmark.fill", "bookmark.square", "bookmark.square.fill", "books.vertical", "books.vertical.circle", "books.vertical.circle.fill", "books.vertical.fill", "briefcase", "briefcase.circle", "briefcase.circle.fill", "briefcase.fill", "bubble", "bubble.circle", "bubble.circle.fill", "bubble.fill", "bubble.right", "bubble.right.circle", "bubble.right.circle.fill", "bubble.right.fill", "bubbles.and.sparkles", "bubbles.and.sparkles.fill", "burst", "burst.fill", "calendar", "calendar.circle", "calendar.circle.fill", "camera", "camera.circle", "camera.circle.fill", "camera.fill", "camera.macro", "camera.macro.circle", "camera.macro.circle.fill", "car", "car.circle", "car.circle.fill", "car.fill", "carrot", "carrot.fill", "cart", "cart.circle", "cart.circle.fill", "cart.fill", "case", "case.fill", "cat", "cat.circle", "cat.circle.fill", "cat.fill", "character.book.closed", "character.book.closed.fill", "checkmark.seal", "checkmark.seal.fill", "circle", "circle.dashed", "circle.dotted", "circle.fill", "circle.grid.3x3", "circle.grid.3x3.circle", "circle.grid.3x3.circle.fill", "circle.grid.3x3.fill", "circle.hexagongrid", "circle.hexagongrid.circle", "circle.hexagongrid.circle.fill", "circle.hexagongrid.fill", "circle.hexagonpath", "circle.hexagonpath.fill", "circle.square", "circle.square.fill", "clipboard", "clipboard.fill", "clock", "clock.circle", "clock.circle.fill", "clock.fill", "cloud", "cloud.circle", "cloud.circle.fill", "cloud.fill", "creditcard", "creditcard.circle", "creditcard.circle.fill", "creditcard.fill", "cross", "cross.circle", "cross.circle.fill", "cross.fill", "crown", "crown.fill", "cup.and.saucer", "cup.and.saucer.fill", "diamond", "diamond.circle", "diamond.circle.fill", "diamond.fill", "doc", "doc.circle", "doc.circle.fill", "doc.fill", "doc.on.clipboard", "doc.on.clipboard.fill", "doc.on.doc", "doc.on.doc.fill", "doc.richtext", "doc.richtext.fill", "doc.text.image", "doc.text.image.fill", "dog", "dog.circle", "dog.circle.fill", "dog.fill", "dot.square", "dot.square.fill", "drop.halffull", "envelope", "envelope.circle", "envelope.circle.fill", "envelope.fill", "envelope.open", "envelope.open.fill", "eraser", "eraser.fill", "eraser.line.dashed", "eraser.line.dashed.fill", "eyedropper", "eyedropper.full", "eyedropper.halffull", "eyes", "face.dashed", "face.smiling", "face.smiling.inverse", "fan", "fan.fill", "figure", "figure.2.arms.open", "figure.and.child.holdinghands", "figure.arms.open", "figure.roll", "figure.run", "figure.stand", "figure.walk", "figure.wave", "film", "film.circle", "film.circle.fill", "film.fill", "fireworks", "fish", "fish.circle", "fish.circle.fill", "fish.fill", "flag", "flag.circle", "flag.circle.fill", "flag.fill", "flag.square", "flag.square.fill", "flashlight.off.circle", "flashlight.off.circle.fill", "flashlight.off.fill", "flashlight.on.circle", "flashlight.on.circle.fill", "flashlight.on.fill", "folder", "folder.circle", "folder.circle.fill", "folder.fill", "fork.knife", "fork.knife.circle", "fork.knife.circle.fill", "gauge.with.dots.needle.bottom.0percent", "gauge.with.dots.needle.bottom.50percent", "gearshape", "gearshape.2", "gearshape.2.fill", "gearshape.circle", "gearshape.circle.fill", "gearshape.fill", "giftcard", "giftcard.fill", "globe", "globe.americas", "globe.americas.fill", "globe.asia.australia", "globe.asia.australia.fill", "globe.central.south.asia", "globe.central.south.asia.fill", "globe.europe.africa", "globe.europe.africa.fill", "greetingcard", "greetingcard.fill", "gyroscope", "hammer", "hammer.circle", "hammer.circle.fill", "hammer.fill", "hand.raised", "hand.raised.circle", "hand.raised.circle.fill", "hand.raised.fill", "hand.thumbsdown", "hand.thumbsdown.circle", "hand.thumbsdown.circle.fill", "hand.thumbsdown.fill", "hand.thumbsup", "hand.thumbsup.circle", "hand.thumbsup.circle.fill", "hand.thumbsup.fill", "handbag", "handbag.circle", "handbag.circle.fill", "handbag.fill", "hare", "hare.circle", "hare.circle.fill", "hare.fill", "heart", "heart.circle", "heart.circle.fill", "heart.fill", "heart.square", "heart.square.fill", "hexagon", "hexagon.fill", "highlighter", "hockey.puck", "hockey.puck.circle", "hockey.puck.circle.fill", "hockey.puck.fill", "house", "house.circle", "house.circle.fill", "house.fill", "key", "key.fill", "key.horizontal", "key.horizontal.fill", "keyboard", "keyboard.fill", "ladybug", "ladybug.circle", "ladybug.circle.fill", "ladybug.fill", "lamp.ceiling", "lamp.ceiling.fill", "lamp.ceiling.inverse", "lamp.desk", "lamp.desk.fill", "lamp.floor", "lamp.floor.fill", "lamp.table", "lamp.table.fill", "lanyardcard", "lanyardcard.fill", "laptopcomputer", "laser.burst", "lasso", "lasso.badge.sparkles", "leaf", "leaf.circle", "leaf.circle.fill", "leaf.fill", "level", "level.fill", "light.panel", "light.panel.fill", "lightbulb", "lightbulb.circle", "lightbulb.circle.fill", "lightbulb.fill", "line.3.crossed.swirl.circle", "line.3.crossed.swirl.circle.fill", "link", "link.badge.plus", "link.circle", "link.circle.fill", "list.bullet.clipboard", "list.bullet.clipboard.fill", "list.clipboard", "list.clipboard.fill", "lizard", "lizard.circle", "lizard.circle.fill", "lizard.fill", "lock", "lock.circle", "lock.circle.dotted", "lock.circle.fill", "lock.fill", "lock.square", "lock.square.fill", "loupe", "magazine", "magazine.fill", "magnifyingglass", "magnifyingglass.circle", "magnifyingglass.circle.fill", "mail", "mail.fill", "mail.stack", "mail.stack.fill", "map", "map.circle", "map.circle.fill", "map.fill", "mappin", "mappin.and.ellipse", "mappin.and.ellipse.circle", "mappin.and.ellipse.circle.fill", "mappin.circle", "mappin.circle.fill", "mappin.square", "mappin.square.fill", "menucard", "menucard.fill", "microbe", "microbe.circle", "microbe.circle.fill", "microbe.fill", "moon", "moon.circle", "moon.circle.fill", "moon.fill", "moon.stars", "moon.stars.circle", "moon.stars.circle.fill", "moon.stars.fill", "movieclapper", "movieclapper.fill", "mug", "mug.fill", "mustache", "mustache.fill", "newspaper", "newspaper.circle", "newspaper.circle.fill", "newspaper.fill", "nosign", "nosign.app", "nosign.app.fill", "note", "note.text", "octagon", "octagon.fill", "paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill", "paintpalette", "paintpalette.fill", "paperclip", "paperclip.badge.ellipsis", "paperclip.circle", "paperclip.circle.fill", "paperplane", "paperplane.circle", "paperplane.circle.fill", "paperplane.fill", "party.popper", "party.popper.fill", "pawprint", "pawprint.circle", "pawprint.circle.fill", "pawprint.fill", "peacesign", "pencil", "pencil.and.list.clipboard", "pencil.and.outline", "pencil.and.ruler", "pencil.and.ruler.fill", "pencil.and.scribble", "pencil.circle", "pencil.circle.fill", "pencil.line", "pentagon", "pentagon.fill", "person", "person.circle", "person.circle.fill", "person.crop.circle", "person.crop.circle.fill", "person.crop.square", "person.crop.square.fill", "person.fill", "personalhotspot", "personalhotspot.circle", "personalhotspot.circle.fill", "phone", "phone.circle", "phone.circle.fill", "phone.fill", "photo", "photo.artframe", "photo.circle", "photo.circle.fill", "photo.fill", "photo.on.rectangle.angled", "pianokeys", "pianokeys.inverse", "pin", "pin.circle", "pin.circle.fill", "pin.fill", "pin.square", "pin.square.fill", "pip", "pip.fill", "play", "play.circle", "play.circle.fill", "play.fill", "play.rectangle", "play.rectangle.fill", "play.square", "play.square.fill", "popcorn", "popcorn.circle", "popcorn.circle.fill", "popcorn.fill", "powersleep", "printer", "printer.fill", "qrcode", "questionmark.app", "questionmark.app.fill", "rays", "record.circle", "record.circle.fill", "rectangle.and.paperclip", "rectangle.and.pencil.and.ellipsis", "rectangle.dashed.and.paperclip", "rectangle.fill.on.rectangle.angled.fill", "rectangle.fill.on.rectangle.fill", "rectangle.on.rectangle", "rectangle.on.rectangle.angled", "rectangle.on.rectangle.square", "rectangle.on.rectangle.square.fill", "rectangle.stack", "rectangle.stack.fill", "rhombus", "rhombus.fill", "ruler", "ruler.fill", "scissors", "scissors.circle", "scissors.circle.fill", "screwdriver", "screwdriver.fill", "scribble", "scribble.variable", "scroll", "scroll.fill", "seal", "seal.fill", "shield", "shield.fill", "shield.lefthalf.filled", "shippingbox", "shippingbox.circle", "shippingbox.circle.fill", "shippingbox.fill", "signature", "slowmo", "smallcircle.filled.circle", "smallcircle.filled.circle.fill", "sparkle", "sparkles", "sparkles.tv", "sparkles.tv.fill", "square", "square.and.pencil", "square.and.pencil.circle", "square.and.pencil.circle.fill", "square.dashed", "square.dashed.inset.filled", "square.dotted", "square.fill", "square.fill.on.square.fill", "square.grid.2x2", "square.grid.2x2.fill", "square.on.square", "star", "star.circle", "star.circle.fill", "star.fill", "star.square", "star.square.fill", "stethoscope", "stethoscope.circle", "stethoscope.circle.fill", "stop", "stop.circle", "stop.circle.fill", "stop.fill", "studentdesk", "suit.club", "suit.club.fill", "suit.diamond", "suit.diamond.fill", "suit.spade", "suit.spade.fill", "sun.horizon", "sun.horizon.fill", "sun.max", "sun.max.circle", "sun.max.circle.fill", "sun.max.fill", "sun.min", "sun.min.fill", "sunglasses", "sunglasses.fill", "swatchpalette", "swatchpalette.fill", "swirl.circle.righthalf.filled", "swirl.circle.righthalf.filled.inverse", "tag", "tag.circle", "tag.circle.fill", "tag.fill", "tag.square", "tag.square.fill", "target", "teddybear", "teddybear.fill", "text.book.closed", "text.book.closed.fill", "theatermask.and.paintbrush", "theatermask.and.paintbrush.fill", "theatermasks", "theatermasks.circle", "theatermasks.circle.fill", "theatermasks.fill", "ticket", "ticket.fill", "timelapse", "tortoise", "tortoise.circle", "tortoise.circle.fill", "tortoise.fill", "tray", "tray.circle", "tray.circle.fill", "tray.fill", "tray.full", "tray.full.fill", "tree", "tree.circle", "tree.circle.fill", "tree.fill", "tshirt", "tshirt.circle", "tshirt.circle.fill", "tshirt.fill", "tv", "tv.circle", "tv.circle.fill", "tv.fill", "viewfinder", "viewfinder.circle", "viewfinder.circle.fill", "viewfinder.rectangular", "wallet.pass", "wallet.pass.fill", "wand.and.rays", "wand.and.stars", "waterbottle", "waterbottle.fill", "wineglass", "wineglass.fill", "wrench.adjustable", "wrench.adjustable.fill", "wrench.and.screwdriver", "wrench.and.screwdriver.fill", "xmark.app", "xmark.app.fill", "xmark.seal", "xmark.seal.fill"]

struct SymbolPicker: View {
    
    let symbols: [String] = SYMBOLS
    
    @Binding var selectedSymbol: String
    
    var onSelect: (() -> ())? = nil
    
    @State private var searchTerm: String = ""
    @FocusState private var searchBoxSelected
    
    var filteredSymbols: [String] {
        let st = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if st == "" {
            return symbols
        }
        return symbols.filter { $0.contains(st) }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: $searchTerm.animation())
                        .focused($searchBoxSelected)
                }
                .padding(.vertical, 8)
                .padding(.leading, 10)
                .padding(.trailing, 15)
                .foregroundColor(.secondary)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                if searchBoxSelected {
                    Button(action: {
                        searchBoxSelected = false
                        searchTerm = ""
                    }) {
                        Text("Cancel")
                    }
                }
            }
            ScrollViewReader { value in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 10)], spacing: 10) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            Button(action: {
                                withAnimation {
                                    selectedSymbol = symbol
                                }
                                self.onSelect?()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedSymbol == symbol ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                                        .aspectRatio(1, contentMode: .fit)
                                    Image(systemName: symbol)
                                        .font(.title)
                                        .foregroundStyle(selectedSymbol == symbol ? Color.white : Color.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .id(symbol)
                        }
                    }
                    .onAppear {
                        value.scrollTo(selectedSymbol, anchor: .center)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .padding(10)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct SymbolPickerTest: View {
    @State private var typeName: String = ""
    @State private var icon: String = "envelope"
    @State private var showPicker: Bool = false
    var body: some View {
        Form {
            HStack {
                Button(action: { showPicker = true }) {
                    Image(systemName: icon)
                }
                TextField("Name", text: $typeName)
            }
        }
        .sheet(isPresented: $showPicker) {
            SymbolPicker(selectedSymbol: $icon) {
                showPicker = false
            }
        }
    }
}

#Preview {
    SymbolPickerTest()
}
