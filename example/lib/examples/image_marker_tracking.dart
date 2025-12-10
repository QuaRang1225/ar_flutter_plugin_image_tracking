import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class ImageMarkerTracking extends StatefulWidget {
  const ImageMarkerTracking({Key? key}) : super(key: key);

  @override
  State<ImageMarkerTracking> createState() => _ImageMarkerTrackingState();
}

class _ImageMarkerTrackingState extends State<ImageMarkerTracking> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  ARAnchor? anchor;
  ARNode? node;

  // 마커 이미지의 실제 크기 저장 (미터 단위)
  double? markerPhysicalWidth;
  double? markerPhysicalHeight;

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
      handleTaps: false,
      trackingImagePaths: [
        "Images/augmented-images-earth.jpg",
      ],
    );
    this.arObjectManager!.onInitialize();
    this.arSessionManager!.onImageDetected = onImageDetected;
    this.arSessionManager!.onImageLost = onImageLost;
  }

  void onImageDetected(String imageName, Matrix4 transformation, double physicalWidth, double physicalHeight) {
    print("Image detected: $imageName");
    print("Physical size: ${physicalWidth}m x ${physicalHeight}m");

    // 마커의 실제 크기 저장
    markerPhysicalWidth = physicalWidth;
    markerPhysicalHeight = physicalHeight;

    // Convert transformation matrix to position
    Vector3 position = transformation.getTranslation();
    print("Image '$imageName' detected at position: $position");

    // Automatically place an object on the detected image
    placeObjectOnImage(imageName, transformation, physicalWidth, physicalHeight);
  }

  void onImageLost(String imageName) {
    print("Image lost: $imageName");

    // 이미지가 사라지면 즉시 3D 노드 숨기기
    if (node != null) {
      arObjectManager?.removeNode(node!);
      node = null;
    }
    if (anchor != null) {
      arAnchorManager?.removeAnchor(anchor!);
      anchor = null;
    }
  }

  Future<void> placeObjectOnImage(
      String imageName, Matrix4 transformation, double physicalWidth, double physicalHeight) async {
    try {
      // Create a new anchor at the image position
      var imageAnchor = ARPlaneAnchor(transformation: transformation);

      bool? didAddAnchor = await arAnchorManager!.addAnchor(imageAnchor);
      if (didAddAnchor == true) {
        // Remove any existing anchor and node
        if (anchor != null) {
          arAnchorManager?.removeAnchor(anchor!);
        }
        if (node != null) {
          arObjectManager?.removeNode(node!);
        }

        anchor = imageAnchor;

        var modelUrl = "Models/Chicken_01/Chicken_01.gltf";

        // 마커 이미지의 실제 크기에 맞게 3D 모델 스케일 계산
        // physicalWidth는 마커의 실제 너비 (미터 단위)
        // 모델이 마커와 동일한 크기가 되도록 스케일 조정
        // 기본 모델 크기를 1m로 가정하고, 마커 크기에 맞춰 스케일링
        double baseModelSize = 1.0; // 모델의 기본 크기 (미터 단위, 필요시 조정)
        double scale = physicalWidth / baseModelSize;

        print("Marker physical width: ${physicalWidth}m, Model scale: $scale");

        var imageNode = ARNode(
          type: NodeType.localGLTF2,
          uri: modelUrl,
          scale: Vector3(scale, scale, scale),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNodeToAnchor =
            await arObjectManager!.addNode(imageNode, planeAnchor: imageAnchor);

        if (didAddNodeToAnchor == true) {
          node = imageNode;
          print("Successfully placed object on image: $imageName with scale: $scale");
        } else {
          //arSessionManager!.onError("Adding Node to Image Anchor failed");
        }
      } else {
        //arSessionManager!.onError("Adding Image Anchor failed");
      }
    } catch (e) {
      print("Error placing object on image: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Marker Tracking'),
      ),
      body: ARView(
        onARViewCreated: onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }
}
