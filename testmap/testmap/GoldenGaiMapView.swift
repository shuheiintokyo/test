import SwiftUI
import MapKit

struct GoldenGaiMapView: View {
    // Golden Gai location
    let goldenGaiLocation = CLLocationCoordinate2D(
        latitude: 35.6938,
        longitude: 139.7047
    )
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 35.6938,
            longitude: 139.7047
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.05,
            longitudeDelta: 0.05
        )
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [Location(coordinate: goldenGaiLocation)]) { location in
            MapMarker(coordinate: location.coordinate, tint: .red)
        }
        .ignoresSafeArea()
        .onAppear {
            // Animate zoom in after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 4.0)) {
                    region.span = MKCoordinateSpan(
                        latitudeDelta: 0.005,
                        longitudeDelta: 0.005
                    )
                }
            }
        }
    }
}

// Helper struct for the map annotation
struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    GoldenGaiMapView()
}
