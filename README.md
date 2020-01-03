# Y.E.A.R.-3044
Yet Even Another Racer 3044. Antigravity hovership racer. Made with Godot Engine for Github Face off 2019.

--------------------------------
#Create new tracks for the game.
Open the with Blender 2.8 the file in models road_test.blend
Leave only visible the colection road_2
Select Road2-col.002 and all of it's children.
Douplicate it and move it in a new collection with the name of your track.
Leave only the new colection visible.
Build the new track by duplicating and editting the part you moved. Keep in mind that you must manualy add the same count in the array modifier for the col and colonly parts of the road.
After you build the track you must select from the bottom to the first all the NurbsPath and Duplicate them and merge them and unparent the new nurb.
Edit the new nurb so there is no gaps.
Convert the NurbPath to polygons (keep the original cause sometimes you will have to fix it for proper ai) and then convert the polygons to curve.
Select everythink and export as gltf 2.0 the model in the models dir.
Select the Curve and export it with Better Collada as "name_of_the_track"_path.dae.
Open Godot.
Open the .glb of your track and save it as a .tscn in track dir.
Open the .dae of the path change the name of the "Scene Root" to "RoadPath" and save it as _path.tscn in track dir.
Open track_1.tscn 
Delete the track and the path of track_1 and place those you created and the save as "your_track_name".tscn
Open main_split.gd and and the name of your track in the array track_paths
Save and play.
