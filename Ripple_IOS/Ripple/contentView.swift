//
//  ContentView.swift
//  Ripple
//
//  Created by Rowan  Rothe on 2024-02-18.
//

// import libraries
import SwiftUI

struct CircleStruct: Identifiable {
    var id = UUID()
    var color: Color = .white
    var lineWidth: Double = 1.0
    var center: CGPoint = .zero
    var radius: CGFloat = .zero
    var opacity: CGFloat = 1
}

final class UnfairLock {
    private var _lock: UnsafeMutablePointer<os_unfair_lock>

    init() {
        _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    deinit {
        _lock.deallocate()
    }

    func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        os_unfair_lock_lock(_lock)
        defer { os_unfair_lock_unlock(_lock) }
        return try f()
    }
}

// create ContentView struct named "View"
struct ContentView: View {
    // circle vars
    @State private var maxCircleRadius: CGFloat = 75
    
    // circle array
    @State private var circleArray: [CircleStruct] = []
    
    // set mutex lock
    let lock = UnfairLock()
    
    // create body with the struct
    var body: some View {
        // creates a z stack (for overlapping elements)
        ZStack {
            
            Canvas { context, size in
                // draw circles for each one in the array
                for circle in circleArray {
                    // draw new circle
                    let circleRect = CGRect(x: circle.center.x - circle.radius, y: circle.center.y - circle.radius, width: circle.radius * 2, height: circle.radius * 2)
                    context.stroke(Path(ellipseIn: circleRect), with: .color(Color.white.opacity(circle.opacity)), lineWidth: 1)
                }
            }
            .background(Color.black) // set black background
            .edgesIgnoringSafeArea(.all) // ignore safe areas
            // handle gestures
            .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            let newCircle = CircleStruct(center: value.location, radius: 0)

                            lock.locked {
                                circleArray.append(newCircle)
                            }

                            Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
                                lock.locked {
                                    if let index = circleArray.firstIndex(where: { $0.id == newCircle.id }), circleArray[index].radius < maxCircleRadius {
                                        circleArray[index].radius += 1
                                        circleArray[index].opacity -= 0.015
                                    } else {
                                        timer.invalidate()
                                        if let index = circleArray.firstIndex(where: { $0.id == newCircle.id }) {
                                            circleArray.remove(at: index)
                                        }
                                    }
                                }
                            }
                        }
                )
            .edgesIgnoringSafeArea(.all)
        }
        // set frame size to infinite and ignore safe edges
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

// enable the preview of the ContentView struct
#Preview {
    ContentView()
}
