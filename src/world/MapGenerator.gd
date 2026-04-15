@tool
## Procedural CSG blockout generator for "Barrios de Adrogué" level.
## Attach to a Node3D in the editor, then click "Generate Map" in the inspector.
## Generates: ground, streets (empedrado), building volumes, green zone,
## train tracks, extraction zones, and environment.
extends Node3D

const _BarriosMapData = preload("res://src/world/map_data/BarriosMapData.gd")

@export var regenerate: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_clear_generated()
			_generate_map()
			regenerate = false

@export_group("Map Settings")
@export var seed_value: int = 42
@export var building_detail: int = 1 ## 0=boxes only, 1=with roofs, 2=with openings

@export_group("Debug")
@export var show_zone_colors: bool = true
@export var show_extraction_markers: bool = true

var _rng := RandomNumberGenerator.new()

# ── Material cache ────────────────────────────────────────
var _mat_ground: StandardMaterial3D
var _mat_street: StandardMaterial3D
var _mat_building_residential: StandardMaterial3D
var _mat_building_commercial: StandardMaterial3D
var _mat_building_station: StandardMaterial3D
var _mat_building_medical: StandardMaterial3D
var _mat_building_recreation: StandardMaterial3D
var _mat_grass: StandardMaterial3D
var _mat_tracks: StandardMaterial3D
var _mat_platform: StandardMaterial3D
var _mat_extraction: StandardMaterial3D
var _mat_sidewalk: StandardMaterial3D
var _mat_roof: StandardMaterial3D
var _mat_fence: StandardMaterial3D
var _mat_abandoned_vehicle: StandardMaterial3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		# Runtime: generate the map procedurally
		_clear_generated()
		_generate_map()


func _create_materials() -> void:
	# Ground - dry dirt/earth (post-apocalyptic)
	_mat_ground = StandardMaterial3D.new()
	_mat_ground.albedo_color = Color(0.35, 0.28, 0.20) # dry earth
	_mat_ground.roughness = 0.95

	# Streets - cobblestone / empedrado (Poly Haven stone_pathway_02 PBR)
	_mat_street = StandardMaterial3D.new()
	var street_diff := load("res://assets/textures/streets/stone_pathway_02_diff_1k.jpg") as Texture2D
	var street_normal := load("res://assets/textures/streets/stone_pathway_02_nor_gl_1k.jpg") as Texture2D
	var street_rough := load("res://assets/textures/streets/stone_pathway_02_rough_1k.jpg") as Texture2D
	if street_diff:
		_mat_street.albedo_texture = street_diff
		_mat_street.albedo_color = Color(0.85, 0.82, 0.78)
	else:
		_mat_street.albedo_color = Color(0.32, 0.30, 0.28)
	if street_normal:
		_mat_street.normal_enabled = true
		_mat_street.normal_texture = street_normal
	if street_rough:
		_mat_street.roughness_texture = street_rough
	_mat_street.roughness = 0.85
	_mat_street.uv1_scale = Vector3(4.0, 4.0, 4.0) # tile the texture across large surfaces

	# Sidewalk - vereda
	_mat_sidewalk = StandardMaterial3D.new()
	_mat_sidewalk.albedo_color = Color(0.55, 0.52, 0.48) # concrete grey
	_mat_sidewalk.roughness = 0.80

	# Residential buildings - faded paint, worn walls
	_mat_building_residential = StandardMaterial3D.new()
	_mat_building_residential.albedo_color = Color(0.60, 0.55, 0.45) # yellowish worn
	_mat_building_residential.roughness = 0.90

	# Commercial buildings - peeling plaster
	_mat_building_commercial = StandardMaterial3D.new()
	_mat_building_commercial.albedo_color = Color(0.50, 0.48, 0.52) # grey plaster
	_mat_building_commercial.roughness = 0.85

	# Train station - old brick/concrete
	_mat_building_station = StandardMaterial3D.new()
	_mat_building_station.albedo_color = Color(0.55, 0.40, 0.35) # reddish brick
	_mat_building_station.roughness = 0.88

	# Medical - clinical white gone grimy
	_mat_building_medical = StandardMaterial3D.new()
	_mat_building_medical.albedo_color = Color(0.65, 0.65, 0.60) # dirty white
	_mat_building_medical.roughness = 0.75

	# Recreation/club - painted concrete
	_mat_building_recreation = StandardMaterial3D.new()
	_mat_building_recreation.albedo_color = Color(0.45, 0.50, 0.40) # faded green
	_mat_building_recreation.roughness = 0.85

	# Grass - overgrown, wild
	_mat_grass = StandardMaterial3D.new()
	_mat_grass.albedo_color = Color(0.30, 0.45, 0.20) # wild grass green
	_mat_grass.roughness = 0.95

	# Train tracks - rusted metal
	_mat_tracks = StandardMaterial3D.new()
	_mat_tracks.albedo_color = Color(0.35, 0.25, 0.18) # rust
	_mat_tracks.metallic = 0.6
	_mat_tracks.roughness = 0.70

	# Platform - old concrete
	_mat_platform = StandardMaterial3D.new()
	_mat_platform.albedo_color = Color(0.50, 0.47, 0.43)
	_mat_platform.roughness = 0.85

	# Extraction marker (debug)
	_mat_extraction = StandardMaterial3D.new()
	_mat_extraction.albedo_color = Color(1.0, 0.6, 0.0, 0.5)
	_mat_extraction.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Roof material
	_mat_roof = StandardMaterial3D.new()
	_mat_roof.albedo_color = Color(0.40, 0.30, 0.25) # dark tile/tin
	_mat_roof.roughness = 0.80

	# Fence / reja
	_mat_fence = StandardMaterial3D.new()
	_mat_fence.albedo_color = Color(0.25, 0.25, 0.25) # dark metal
	_mat_fence.metallic = 0.7
	_mat_fence.roughness = 0.60

	# Abandoned vehicle
	_mat_abandoned_vehicle = StandardMaterial3D.new()
	_mat_abandoned_vehicle.albedo_color = Color(0.40, 0.35, 0.30) # rusted car
	_mat_abandoned_vehicle.metallic = 0.4
	_mat_abandoned_vehicle.roughness = 0.75


# ── Main Generation ───────────────────────────────────────
func _generate_map() -> void:
	_rng.seed = seed_value
	_create_materials()

	_generate_ground()
	_generate_streets()
	_generate_zones()
	_generate_green_zone()
	_generate_train_tracks()
	_generate_extraction_zones()
	_generate_abandoned_vehicles()
	_generate_environment()
	_generate_navigation_region()
	_generate_grass_patches()

	print("[MapGenerator] Barrios de Adrogué generated (seed: %d)" % seed_value)


func _clear_generated() -> void:
	for child in get_children():
		child.queue_free()


# ── Ground ────────────────────────────────────────────────
func _generate_ground() -> void:
	var ground := CSGBox3D.new()
	ground.name = "Ground"
	ground.size = Vector3(_BarriosMapData.MAP_SIZE.x + 40.0, 0.5, _BarriosMapData.MAP_SIZE.y + 40.0)
	ground.position = Vector3(0.0, -0.25, 0.0)
	ground.material = _mat_ground
	ground.use_collision = true
	ground.set_meta("surface_type", "dirt")
	add_child(ground)
	ground.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Streets (empedrado) ───────────────────────────────────
func _generate_streets() -> void:
	var streets_parent := Node3D.new()
	streets_parent.name = "Streets"
	add_child(streets_parent)
	streets_parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# East-West streets
	for street_data in _BarriosMapData.STREETS_EW:
		var length: float = street_data["x_end"] - street_data["x_start"]
		var center_x: float = (street_data["x_start"] + street_data["x_end"]) / 2.0
		var w: float = street_data["width"]

		# Street surface
		var street := CSGBox3D.new()
		street.name = "Street_EW_%s" % street_data["name"]
		street.size = Vector3(length, 0.15, w)
		street.position = Vector3(center_x, 0.05, street_data["z"])
		street.material = _mat_street
		street.use_collision = true
		street.set_meta("surface_type", "cobblestone")
		streets_parent.add_child(street)
		street.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		# Sidewalks (veredas) on both sides
		for side in [-1.0, 1.0]:
			var sidewalk := CSGBox3D.new()
			sidewalk.name = "Sidewalk_%s_%s" % [street_data["name"], "N" if side < 0 else "S"]
			sidewalk.size = Vector3(length, 0.25, 1.5)
			sidewalk.position = Vector3(center_x, 0.1, street_data["z"] + side * (w / 2.0 + 0.75))
			sidewalk.material = _mat_sidewalk
			sidewalk.use_collision = true
			sidewalk.set_meta("surface_type", "concrete")
			streets_parent.add_child(sidewalk)
			sidewalk.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# North-South streets
	for street_data in _BarriosMapData.STREETS_NS:
		var length: float = street_data["z_end"] - street_data["z_start"]
		var center_z: float = (street_data["z_start"] + street_data["z_end"]) / 2.0
		var w: float = street_data["width"]

		var street := CSGBox3D.new()
		street.name = "Street_NS_%s" % street_data["name"]
		street.size = Vector3(w, 0.15, length)
		street.position = Vector3(street_data["x"], 0.05, center_z)
		street.material = _mat_street
		street.use_collision = true
		street.set_meta("surface_type", "cobblestone")
		streets_parent.add_child(street)
		street.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		for side in [-1.0, 1.0]:
			var sidewalk := CSGBox3D.new()
			sidewalk.name = "Sidewalk_%s_%s" % [street_data["name"], "W" if side < 0 else "E"]
			sidewalk.size = Vector3(1.5, 0.25, length)
			sidewalk.position = Vector3(street_data["x"] + side * (w / 2.0 + 0.75), 0.1, center_z)
			sidewalk.material = _mat_sidewalk
			sidewalk.use_collision = true
			sidewalk.set_meta("surface_type", "concrete")
			streets_parent.add_child(sidewalk)
			sidewalk.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Zone Building Generation ──────────────────────────────
func _generate_zones() -> void:
	for zone_name in _BarriosMapData.ZONES:
		var zone: Dictionary = _BarriosMapData.ZONES[zone_name]
		if zone["type"] == "plains":
			continue # handled by _generate_green_zone

		var zone_parent := Node3D.new()
		zone_parent.name = "Zone_%s" % zone_name
		add_child(zone_parent)
		zone_parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		var rect: Array = zone["rect"]
		var zone_mat := _get_zone_material(zone["type"])

		_generate_buildings_in_zone(zone_parent, rect, zone, zone_mat)


func _generate_buildings_in_zone(parent: Node3D, rect: Array, zone: Dictionary, mat: StandardMaterial3D) -> void:
	var x_min: float = rect[0]
	var z_min: float = rect[1]
	var x_max: float = rect[2]
	var z_max: float = rect[3]

	var height_range: Array = zone.get("building_height_range", [3.0, 6.0])
	var coverage: float = zone.get("building_coverage", 0.5)

	# Generate blocks within this zone
	# Each block is ~70-90m, subdivided by streets
	var block_size := 70.0
	var x := x_min + 10.0
	var block_id := 0

	while x < x_max - 10.0:
		var z := z_min + 10.0
		while z < z_max - 10.0:
			# Skip if this position is on a street
			if _is_on_street(x + block_size / 2.0, z + block_size / 2.0):
				z += block_size + _BarriosMapData.STREET_WIDTH
				continue

			_generate_block(parent, x, z, block_size, height_range, coverage, mat, block_id)
			block_id += 1
			z += block_size + _BarriosMapData.STREET_WIDTH
		x += block_size + _BarriosMapData.STREET_WIDTH


func _generate_block(parent: Node3D, bx: float, bz: float, block_size: float,
		height_range: Array, coverage: float, mat: StandardMaterial3D, block_id: int) -> void:
	# Generate several buildings within this block
	var buildings_count := int(coverage * _rng.randf_range(3.0, 7.0))
	var margin := 3.0

	for i in range(buildings_count):
		var bw := _rng.randf_range(8.0, 18.0) # building width
		var bd := _rng.randf_range(10.0, 22.0) # building depth
		var bh := _rng.randf_range(height_range[0], height_range[1])

		var local_x := bx + _rng.randf_range(margin, block_size - bw - margin)
		var local_z := bz + _rng.randf_range(margin, block_size - bd - margin)

		# Main building volume
		var building := CSGBox3D.new()
		building.name = "Building_%d_%d" % [block_id, i]
		building.size = Vector3(bw, bh, bd)
		building.position = Vector3(local_x + bw / 2.0, bh / 2.0, local_z + bd / 2.0)
		building.material = mat
		building.use_collision = true
		building.set_meta("surface_type", "concrete")
		parent.add_child(building)
		building.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		# Roof (slightly larger, thin)
		if building_detail >= 1:
			var roof := CSGBox3D.new()
			roof.name = "Roof_%d_%d" % [block_id, i]
			roof.size = Vector3(bw + 0.4, 0.3, bd + 0.4)
			roof.position = Vector3(local_x + bw / 2.0, bh + 0.15, local_z + bd / 2.0)
			roof.material = _mat_roof
			roof.use_collision = true
			parent.add_child(roof)
			roof.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		# Front fence/reja (typical Argentine house)
		if _rng.randf() < 0.6:
			var fence := CSGBox3D.new()
			fence.name = "Fence_%d_%d" % [block_id, i]
			fence.size = Vector3(bw, 2.0, 0.1)
			fence.position = Vector3(local_x + bw / 2.0, 1.0, local_z - 0.5)
			fence.material = _mat_fence
			fence.use_collision = true
			parent.add_child(fence)
			fence.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Green Zone (Llanura) ──────────────────────────────────
func _generate_green_zone() -> void:
	var zone: Dictionary = _BarriosMapData.ZONES["green_zone"]
	var rect: Array = zone["rect"]
	var parent := Node3D.new()
	parent.name = "GreenZone"
	add_child(parent)
	parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Grass ground overlay
	var grass := CSGBox3D.new()
	grass.name = "GrassGround"
	var gw: float = rect[2] - rect[0]
	var gd: float = rect[3] - rect[1]
	grass.size = Vector3(gw, 0.2, gd)
	grass.position = Vector3((rect[0] + rect[2]) / 2.0, 0.08, (rect[1] + rect[3]) / 2.0)
	grass.material = _mat_grass
	grass.use_collision = true
	grass.set_meta("surface_type", "grass")
	parent.add_child(grass)
	grass.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Tree placeholders (CSG cylinders + spheres)
	var tree_count := int(gw * gd * zone["tree_density"])
	tree_count = min(tree_count, 120) # cap for performance

	for i in range(tree_count):
		var tx := _rng.randf_range(rect[0] + 5.0, rect[2] - 5.0)
		var tz := _rng.randf_range(rect[1] + 5.0, rect[3] - 5.0)
		var trunk_h := _rng.randf_range(4.0, 8.0)
		var crown_r := _rng.randf_range(2.0, 4.0)

		# Trunk
		var trunk := CSGCylinder3D.new()
		trunk.name = "TreeTrunk_%d" % i
		trunk.radius = _rng.randf_range(0.15, 0.3)
		trunk.height = trunk_h
		trunk.position = Vector3(tx, trunk_h / 2.0, tz)
		trunk.sides = 6
		var trunk_mat := StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.35, 0.25, 0.15)
		trunk_mat.roughness = 0.95
		trunk.material = trunk_mat
		trunk.use_collision = true
		parent.add_child(trunk)
		trunk.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		# Crown
		var crown := CSGSphere3D.new()
		crown.name = "TreeCrown_%d" % i
		crown.radius = crown_r
		crown.radial_segments = 8
		crown.rings = 4
		crown.position = Vector3(tx, trunk_h + crown_r * 0.5, tz)
		var crown_mat := StandardMaterial3D.new()
		crown_mat.albedo_color = Color(
			_rng.randf_range(0.15, 0.30),
			_rng.randf_range(0.35, 0.55),
			_rng.randf_range(0.10, 0.20)
		)
		crown_mat.roughness = 0.95
		crown.material = crown_mat
		parent.add_child(crown)
		crown.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Train Tracks ──────────────────────────────────────────
func _generate_train_tracks() -> void:
	var parent := Node3D.new()
	parent.name = "TrainTracks"
	add_child(parent)
	parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	var tracks: Dictionary = _BarriosMapData.TRACKS
	var tx: float = tracks["position_x"]
	var tz_start: float = tracks["z_start"]
	var tz_end: float = tracks["z_end"]
	var track_length: float = tz_end - tz_start
	var tz_center: float = (tz_start + tz_end) / 2.0

	# Track bed (gravel)
	var bed := CSGBox3D.new()
	bed.name = "TrackBed"
	bed.size = Vector3(tracks["width"], 0.3, track_length)
	bed.position = Vector3(tx, 0.12, tz_center)
	var bed_mat := StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.40, 0.35, 0.30)
	bed_mat.roughness = 0.95
	bed.material = bed_mat
	bed.use_collision = true
	bed.set_meta("surface_type", "gravel")
	parent.add_child(bed)
	bed.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Rails (2 tracks x 2 rails = 4 rails)
	for track_idx in range(tracks["rail_count"]):
		var track_offset: float = (track_idx - 0.5) * tracks["rail_spacing"]
		for rail_side in [-0.75, 0.75]: # rail gauge ~1.5m
			var rail := CSGBox3D.new()
			rail.name = "Rail_%d_%s" % [track_idx, "L" if rail_side < 0 else "R"]
			rail.size = Vector3(0.08, 0.15, track_length)
			rail.position = Vector3(tx + track_offset + rail_side, 0.38, tz_center)
			rail.material = _mat_tracks
			rail.use_collision = true
			parent.add_child(rail)
			rail.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Sleepers/durmientes (every 2m along the track)
	var sleeper_spacing := 2.0
	var sleeper_z := tz_start
	var sleeper_id := 0
	while sleeper_z < tz_end:
		var sleeper := CSGBox3D.new()
		sleeper.name = "Sleeper_%d" % sleeper_id
		sleeper.size = Vector3(tracks["width"] - 2.0, 0.12, 0.25)
		sleeper.position = Vector3(tx, 0.28, sleeper_z)
		var sleeper_mat := StandardMaterial3D.new()
		sleeper_mat.albedo_color = Color(0.30, 0.22, 0.15)
		sleeper_mat.roughness = 0.95
		sleeper.material = sleeper_mat
		sleeper.use_collision = true
		parent.add_child(sleeper)
		sleeper.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
		sleeper_z += sleeper_spacing
		sleeper_id += 1

	# Platforms (andenes)
	for plat_data in tracks["platform_positions"]:
		var plat := CSGBox3D.new()
		var side_offset: float = -tracks["width"] / 2.0 - 3.0 if plat_data["side"] == "west" else tracks["width"] / 2.0 + 3.0
		plat.name = "Platform_%s" % plat_data["side"]
		plat.size = Vector3(5.0, 1.0, plat_data["length"])
		plat.position = Vector3(tx + side_offset, 0.5, plat_data["z"])
		plat.material = _mat_platform
		plat.use_collision = true
		plat.set_meta("surface_type", "concrete")
		parent.add_child(plat)
		plat.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Station building (Estación Adrogué)
	var station := CSGBox3D.new()
	station.name = "EstacionAdrogue"
	station.size = Vector3(20.0, 8.0, 30.0)
	station.position = Vector3(tx - tracks["width"] / 2.0 - 15.0, 4.0, 140.0)
	station.material = _mat_building_station
	station.use_collision = true
	parent.add_child(station)
	station.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	var station_roof := CSGBox3D.new()
	station_roof.name = "EstacionAdrogue_Roof"
	station_roof.size = Vector3(22.0, 0.4, 32.0)
	station_roof.position = Vector3(tx - tracks["width"] / 2.0 - 15.0, 8.2, 140.0)
	station_roof.material = _mat_roof
	station_roof.use_collision = true
	parent.add_child(station_roof)
	station_roof.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Platform roof/techo (long canopy over platform)
	var canopy := CSGBox3D.new()
	canopy.name = "PlatformCanopy"
	canopy.size = Vector3(6.0, 0.15, 50.0)
	canopy.position = Vector3(tx - tracks["width"] / 2.0 - 3.0, 4.5, 140.0)
	canopy.material = _mat_tracks
	canopy.use_collision = false
	parent.add_child(canopy)
	canopy.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Extraction Zones ──────────────────────────────────────
func _generate_extraction_zones() -> void:
	var parent := Node3D.new()
	parent.name = "ExtractionZones"
	add_child(parent)
	parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	var _ExtractionZoneScript = preload("res://src/world/ExtractionZone.gd")
	for ext_data in _BarriosMapData.EXTRACTION_POINTS:
		var ext_zone := Area3D.new()
		ext_zone.name = ext_data["name"].replace(" ", "_").replace("-", "_")
		ext_zone.set_script(_ExtractionZoneScript)
		ext_zone.set("zone_name", ext_data["name"])
		ext_zone.set("extraction_time", ext_data.get("timer", 12.0))
		ext_zone.position = ext_data["position"]
		parent.add_child(ext_zone)
		ext_zone.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = ext_data["radius"]
		cylinder.height = 3.0
		shape.shape = cylinder
		shape.name = "CollisionShape"
		ext_zone.add_child(shape)
		shape.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		# Visual marker (debug)
		if show_extraction_markers:
			var marker := CSGCylinder3D.new()
			marker.name = "Marker"
			marker.radius = ext_data["radius"]
			marker.height = 0.05
			marker.position = Vector3(0.0, 0.02, 0.0)
			marker.material = _mat_extraction
			ext_zone.add_child(marker)
			marker.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Abandoned Vehicles ────────────────────────────────────
func _generate_abandoned_vehicles() -> void:
	var parent := Node3D.new()
	parent.name = "AbandonedVehicles"
	add_child(parent)
	parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Scatter cars along streets
	var vehicle_positions := [
		Vector3(-250.0, 0.0, -150.0), Vector3(-180.0, 0.0, 0.0),
		Vector3(-100.0, 0.0, 80.0), Vector3(-50.0, 0.0, -80.0),
		Vector3(50.0, 0.0, 160.0), Vector3(120.0, 0.0, -30.0),
		Vector3(-300.0, 0.0, 100.0), Vector3(-150.0, 0.0, 200.0),
		Vector3(200.0, 0.0, 80.0), Vector3(-80.0, 0.0, -200.0),
		Vector3(100.0, 0.0, -150.0), Vector3(-200.0, 0.0, 250.0),
	]

	for i in range(vehicle_positions.size()):
		var vp: Vector3 = vehicle_positions[i]
		var car := CSGBox3D.new()
		car.name = "Vehicle_%d" % i
		var car_w := _rng.randf_range(1.8, 2.2)
		var car_h := _rng.randf_range(1.3, 1.6)
		var car_l := _rng.randf_range(3.5, 5.0)
		car.size = Vector3(car_w, car_h, car_l)
		car.position = Vector3(vp.x, car_h / 2.0, vp.z)
		car.rotation.y = _rng.randf_range(-0.3, 0.3) # slightly rotated
		car.material = _mat_abandoned_vehicle
		car.use_collision = true
		car.set_meta("surface_type", "metal")
		parent.add_child(car)
		car.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Environment (Post-Apocalyptic) ────────────────────────
func _generate_environment() -> void:
	# DirectionalLight3D - overcast sun
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	sun.light_color = Color(0.85, 0.80, 0.70) # warm but muted
	sun.light_energy = 0.7 # overcast
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	sun.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# WorldEnvironment
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env := Environment.new()

	# Sky - overcast
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.42, 0.38) # grey overcast sky

	# Ambient light - low
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.40, 0.38, 0.35)
	env.ambient_light_energy = 0.4

	# Tonemap - gritty
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9

	# Fog - atmospheric haze
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.47, 0.42)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.8

	# Volumetric fog for mood
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.02
	env.volumetric_fog_albedo = Color(0.55, 0.50, 0.45)
	env.volumetric_fog_emission = Color(0.05, 0.04, 0.03)
	env.volumetric_fog_length = 300.0

	# SSAO for depth
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 2.0

	# SSR
	env.ssr_enabled = true
	env.ssr_max_steps = 64

	# SSIL
	env.ssil_enabled = true
	env.ssil_radius = 3.0
	env.ssil_intensity = 0.8

	# Glow - subtle
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1

	env_node.environment = env
	add_child(env_node)
	env_node.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


# ── Navigation ────────────────────────────────────────────
func _generate_navigation_region() -> void:
	var nav := NavigationRegion3D.new()
	nav.name = "NavigationRegion"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.2
	# Geometry will be baked from CSG collision shapes
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav.navigation_mesh = nav_mesh
	add_child(nav)
	nav.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Bake the navmesh after the tree is ready (deferred to allow CSG to finalize)
	if not Engine.is_editor_hint():
		nav.bake_navigation_mesh.call_deferred()


# ── Helpers ───────────────────────────────────────────────
func _is_on_street(x: float, z: float) -> bool:
	for street in _BarriosMapData.STREETS_EW:
		if abs(z - street["z"]) < street["width"] / 2.0 + 2.0:
			if x > street["x_start"] and x < street["x_end"]:
				return true
	for street in _BarriosMapData.STREETS_NS:
		if abs(x - street["x"]) < street["width"] / 2.0 + 2.0:
			if z > street["z_start"] and z < street["z_end"]:
				return true
	return false


func _get_zone_material(zone_type: String) -> StandardMaterial3D:
	match zone_type:
		"residential": return _mat_building_residential
		"commercial": return _mat_building_commercial
		"station": return _mat_building_station
		"medical": return _mat_building_medical
		"recreation": return _mat_building_recreation
		_: return _mat_building_residential


# ── Grass Patches (MultiMesh based) ───────────────────────

func _generate_grass_patches() -> void:
	var parent := Node3D.new()
	parent.name = "GrassPatches"
	add_child(parent)
	parent.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Zones that get grass coverage
	var grass_zones := {
		"green_zone": {"density": 400, "scale_h": 1.2, "scale_w": 1.0, "color": Color(0.30, 0.50, 0.20)},
		"residential_west": {"density": 120, "scale_h": 0.7, "scale_w": 0.8, "color": Color(0.25, 0.40, 0.18)},
		"residential_east": {"density": 100, "scale_h": 0.6, "scale_w": 0.8, "color": Color(0.22, 0.38, 0.16)},
		"club_deportivo": {"density": 200, "scale_h": 1.0, "scale_w": 1.0, "color": Color(0.28, 0.48, 0.20)},
	}

	for zone_name in grass_zones:
		if not _BarriosMapData.ZONES.has(zone_name):
			continue
		var zone_rect: Array = _BarriosMapData.ZONES[zone_name]["rect"]
		var cfg: Dictionary = grass_zones[zone_name]
		_create_grass_patch(parent, zone_name, zone_rect, cfg)

	print("[MapGenerator] Grass patches generated")


func _create_grass_patch(parent: Node3D, zone_name: String, rect: Array, cfg: Dictionary) -> void:
	var grass_node := MultiMeshInstance3D.new()
	grass_node.name = "Grass_%s" % zone_name

	# Position at center of zone, on ground level
	var cx: float = (rect[0] + rect[2]) / 2.0
	var cz: float = (rect[1] + rect[3]) / 2.0
	grass_node.position = Vector3(cx, 0.15, cz)

	parent.add_child(grass_node)
	grass_node.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	# Create grass material
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = cfg["color"]
	grass_mat.roughness = 0.95
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # visible from both sides

	# Create a simple quad mesh for grass blades
	var quad := QuadMesh.new()
	quad.size = Vector2(0.3, 0.6)
	quad.material = grass_mat

	# Generate grass instances spread across the zone
	var density: int = cfg["density"]
	var x_min: float = rect[0]
	var z_min: float = rect[1]
	var x_max: float = rect[2]
	var z_max: float = rect[3]

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = density
	mm.use_colors = true
	mm.mesh = quad

	for i in range(density):
		var gx: float = _rng.randf_range(x_min, x_max) - cx
		var gz: float = _rng.randf_range(z_min, z_max) - cz
		var rot_y: float = _rng.randf_range(0.0, TAU)
		var scale_var: float = _rng.randf_range(0.7, 1.3)

		var t := Transform3D()
		t = t.scaled(Vector3(cfg["scale_w"] * scale_var, cfg["scale_h"] * scale_var, cfg["scale_w"] * scale_var))
		t = t.rotated(Vector3.UP, rot_y)
		t.origin = Vector3(gx, 0.0, gz)
		mm.set_instance_transform(i, t)

		# Slight color variation per instance
		var color_var: Color = cfg["color"]
		color_var.r += _rng.randf_range(-0.03, 0.03)
		color_var.g += _rng.randf_range(-0.05, 0.05)
		color_var.b += _rng.randf_range(-0.02, 0.02)
		mm.set_instance_color(i, color_var)

	grass_node.multimesh = mm
