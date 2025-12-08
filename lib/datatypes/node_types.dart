/// Determines which types of nodes the plugin supports
enum NodeType {
  localGLTF2, // Node with renderable with fileending .gltf in the Flutter asset folder
  localGLB, // Node with renderable with fileending .glb in the Flutter asset folder
  webGLB, // Node with renderable with fileending .glb loaded from the internet during runtime
  fileSystemAppFolderGLB, // Node with renderable with fileending .glb in the documents folder of the current app
  fileSystemAppFolderGLTF2, // Node with renderable with fileending .gltf in the documents folder of the current app
  localUSDZ, // Node with renderable with file ending .usdz in the Flutter asset folder
  webGLTF, // Node with renderable with file ending .gltf in the Flutter asset folder of the web URL
  webUSDZ // Node with renderable with file ending .gltf in the Flutter asset folder of the web URL
}
