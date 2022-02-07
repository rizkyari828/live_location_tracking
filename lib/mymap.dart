import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_map_live/directions_model.dart';
import 'package:google_map_live/directions_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

class MyMap extends StatefulWidget {
  final String user_id;
  MyMap(this.user_id);
  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final loc.Location location = loc.Location();
  late GoogleMapController _controller;
  bool _added = false;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37.773972, -122.431297),
    zoom: 11.5,
  );

  // late GoogleMapController _googleMapController;
  Marker? _origin;
  Marker? _destination;
  Directions? _info;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //       body: StreamBuilder(
  //     stream: FirebaseFirestore.instance.collection('location').snapshots(),
  //     builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
  //       if (_added) {
  //         mymap(snapshot);
  //       }
  //       if (!snapshot.hasData) {
  //         return Center(child: CircularProgressIndicator());
  //       }
  //       return GoogleMap(
  //         mapType: MapType.normal,
  //         markers: {
  // Marker(
  //     position: LatLng(
  //       snapshot.data!.docs.singleWhere(
  //           (element) => element.id == widget.user_id)['latitude'],
  //       snapshot.data!.docs.singleWhere(
  //           (element) => element.id == widget.user_id)['longitude'],
  //     ),
  //     markerId: MarkerId('id'),
  //     icon: BitmapDescriptor.defaultMarkerWithHue(
  //         BitmapDescriptor.hueMagenta)),
  //         },
  //         initialCameraPosition: CameraPosition(
  //             target: LatLng(
  //               snapshot.data!.docs.singleWhere(
  //                   (element) => element.id == widget.user_id)['latitude'],
  //               snapshot.data!.docs.singleWhere(
  //                   (element) => element.id == widget.user_id)['longitude'],
  //             ),
  //             zoom: 14.47),
  //         onMapCreated: (GoogleMapController controller) async {
  //           setState(() {
  //             _controller = controller;
  //             _added = true;
  //           });
  //         },
  //       );
  //     },
  //   ));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Google Maps'),
        actions: [
          // if (_origin != null)
          TextButton(
            onPressed: () => _controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _origin!.position,
                  zoom: 14.5,
                  tilt: 50.0,
                ),
              ),
            ),
            style: TextButton.styleFrom(
              primary: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('ORIGIN'),
          ),
          // if (_destination != null)
          TextButton(
            onPressed: () => _controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _destination!.position,
                  zoom: 14.5,
                  tilt: 50.0,
                ),
              ),
            ),
            style: TextButton.styleFrom(
              primary: Colors.blue,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('DEST'),
          )
        ],
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('location').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (_added) {
              mymap(snapshot);
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(
                        snapshot.data!.docs.singleWhere((element) =>
                            element.id == widget.user_id)['latitude'],
                        snapshot.data!.docs.singleWhere((element) =>
                            element.id == widget.user_id)['longitude'],
                      ),
                      zoom: 14.47),
                  onMapCreated: (GoogleMapController controller) async {
                    setState(() {
                      _controller = controller;
                      _added = true;
                    });
                  },
                  markers: {
                    Marker(
                        position: LatLng(
                          snapshot.data!.docs.singleWhere((element) =>
                              element.id == widget.user_id)['latitude'],
                          snapshot.data!.docs.singleWhere((element) =>
                              element.id == widget.user_id)['longitude'],
                        ),
                        markerId: MarkerId('id'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueMagenta)),
                    if (_origin != null) _origin!,
                    if (_destination != null) _destination!
                  },
                  polylines: {
                    if (_info != null)
                      Polyline(
                        polylineId: const PolylineId('overview_polyline'),
                        color: Colors.red,
                        width: 5,
                        points: _info!.polylinePoints!
                            .map((e) => LatLng(e.latitude, e.longitude))
                            .toList(),
                      ),
                  },
                  onLongPress: _addMarker,
                ),
                if (_info != null)
                  Positioned(
                    top: 20.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6.0,
                          )
                        ],
                      ),
                      child: Text(
                        '${_info?.totalDistance}, ${_info?.totalDuration}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        onPressed: () => _controller.animateCamera(
          _info != null
              ? CameraUpdate.newLatLngBounds(_info!.bounds!, 100.0)
              : CameraUpdate.newCameraPosition(_initialCameraPosition),
        ),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  void _addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      // Origin is not set OR Origin/Destination are both set
      // Set origin
      // setState(() {
      //   _origin = Marker(
      //     markerId: const MarkerId('origin'),
      //     infoWindow: const InfoWindow(title: 'Origin'),
      //     icon:
      //         BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      //     position: pos,
      //   );
      // Reset destination
      _destination = null;

      // Reset info
      _info = null;
      // });
    } else {
      // Origin is already set
      // Set destination
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: pos,
        );
      });

      // Get directions
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin?.position, destination: pos);
      setState(() => _info = directions);
    }
  }

  Future<void> mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    await _controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(
              snapshot.data!.docs.singleWhere(
                  (element) => element.id == widget.user_id)['latitude'],
              snapshot.data!.docs.singleWhere(
                  (element) => element.id == widget.user_id)['longitude'],
            ),
            zoom: 14.47)));
    setState(() {
      _origin = Marker(
          position: LatLng(
            snapshot.data!.docs.singleWhere(
                (element) => element.id == widget.user_id)['latitude'],
            snapshot.data!.docs.singleWhere(
                (element) => element.id == widget.user_id)['longitude'],
          ),
          markerId: MarkerId('id'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueMagenta));
    });
  }
}
