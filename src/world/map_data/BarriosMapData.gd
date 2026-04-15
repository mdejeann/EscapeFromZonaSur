## Map data for "Barrios de Adrogué" - first playable level.
## Based on satellite reference of Adrogué, Buenos Aires.
## Map area: ~800m (E-W) x 600m (N-S), origin at center.
## Coordinate system: X = East-West, Z = North-South (Godot 3D convention).
## North = -Z, South = +Z, East = +X, West = -X.
class_name BarriosMapData
extends RefCounted

# ── Map Bounds ──────────────────────────────────────────────
const MAP_SIZE := Vector2(800.0, 600.0) # x, z
const MAP_HALF := Vector2(400.0, 300.0)
const GROUND_Y := 0.0
const BUILDING_MIN_HEIGHT := 3.0
const BUILDING_MAX_HEIGHT := 7.0

# ── Street Definitions ─────────────────────────────────────
# Streets are cobblestone (empedrado). Width in meters.
const STREET_WIDTH := 8.0
const ALLEY_WIDTH := 4.0

# East-West streets (constant Z positions, run along X axis)
const STREETS_EW := [
	{"name": "30_de_Septiembre", "z": -280.0, "x_start": -400.0, "x_end": 200.0, "width": 10.0},
	{"name": "Frias", "z": -220.0, "x_start": -400.0, "x_end": 100.0, "width": 8.0},
	{"name": "Amenedo_Norte", "z": -150.0, "x_start": -400.0, "x_end": 300.0, "width": 8.0},
	{"name": "Amenedo_Sur", "z": -80.0, "x_start": -400.0, "x_end": 350.0, "width": 8.0},
	{"name": "Gral_Roca", "z": 0.0, "x_start": -400.0, "x_end": 350.0, "width": 10.0},
	{"name": "Pres_Uriburu", "z": 80.0, "x_start": -400.0, "x_end": 350.0, "width": 8.0},
	{"name": "Adrogue_Centro", "z": 160.0, "x_start": -400.0, "x_end": 350.0, "width": 10.0},
	{"name": "Bartolome_Mitre", "z": 260.0, "x_start": -400.0, "x_end": 350.0, "width": 10.0},
]

# North-South streets (constant X positions, run along Z axis)
const STREETS_NS := [
	{"name": "Cordero", "x": -380.0, "z_start": -280.0, "z_end": 260.0, "width": 8.0},
	{"name": "Avellaneda", "x": -300.0, "z_start": -280.0, "z_end": 260.0, "width": 8.0},
	{"name": "Jose_M_Estrada", "x": -200.0, "z_start": -280.0, "z_end": 260.0, "width": 8.0},
	{"name": "Somellera", "x": -100.0, "z_start": -280.0, "z_end": 260.0, "width": 8.0},
	{"name": "Centro", "x": 0.0, "z_start": -280.0, "z_end": 260.0, "width": 10.0},
	{"name": "Canale", "x": 120.0, "z_start": -280.0, "z_end": 260.0, "width": 8.0},
	{"name": "Ruta_210", "x": 280.0, "z_start": -300.0, "z_end": 300.0, "width": 14.0},
	{"name": "Drumond", "x": 380.0, "z_start": -280.0, "z_end": 260.0, "width": 8.0},
]

# ── Zone Definitions ───────────────────────────────────────
# rect = [x_min, z_min, x_max, z_max]
const ZONES := {
	"green_zone": {
		"rect": [50.0, -300.0, 260.0, -80.0],
		"type": "plains",
		"description": "Llanura con árboles - zona abierta NE",
		"tree_density": 0.02, # trees per sq meter
		"grass": true,
	},
	"residential_west": {
		"rect": [-400.0, -280.0, 0.0, 260.0],
		"type": "residential",
		"description": "Barrio residencial - casas bajas con rejas y patios",
		"building_coverage": 0.55,
		"building_height_range": [3.0, 5.0],
	},
	"residential_east": {
		"rect": [0.0, -80.0, 260.0, 260.0],
		"type": "residential",
		"description": "Zona residencial este - cerca de las vías",
		"building_coverage": 0.45,
		"building_height_range": [3.0, 6.0],
	},
	"commercial_center": {
		"rect": [-200.0, 100.0, 120.0, 200.0],
		"type": "commercial",
		"description": "Centro comercial de Adrogué - kioscos, almacenes",
		"building_coverage": 0.65,
		"building_height_range": [4.0, 8.0],
	},
	"train_station": {
		"rect": [220.0, 80.0, 340.0, 200.0],
		"type": "station",
		"description": "Estación Adrogué - andenes, sala de espera",
		"building_coverage": 0.30,
		"building_height_range": [5.0, 10.0],
	},
	"hospital_area": {
		"rect": [260.0, -20.0, 400.0, 100.0],
		"type": "medical",
		"description": "Zona de Clínica Espora - edificio médico",
		"building_coverage": 0.50,
		"building_height_range": [6.0, 12.0],
	},
	"club_deportivo": {
		"rect": [-380.0, -280.0, -220.0, -180.0],
		"type": "recreation",
		"description": "Club Social y Deportivo José Manuel",
		"building_coverage": 0.20,
		"building_height_range": [3.0, 5.0],
	},
}

# ── Train Tracks ───────────────────────────────────────────
const TRACKS := {
	"position_x": 280.0, # Same as Ruta 210
	"width": 14.0,
	"z_start": -300.0,
	"z_end": 300.0,
	"rail_count": 2,
	"rail_spacing": 4.0,
	"platform_positions": [
		{"z": 140.0, "length": 60.0, "side": "west"},
		{"z": 140.0, "length": 60.0, "side": "east"},
	],
}

# ── Extraction Points (along the train tracks) ────────────
const EXTRACTION_POINTS := [
	{
		"name": "Extracción Norte - Vías",
		"position": Vector3(280.0, 0.0, -250.0),
		"radius": 5.0,
		"timer": 12.0,
		"description": "Final norte de las vías del Roca",
	},
	{
		"name": "Extracción Estación",
		"position": Vector3(280.0, 0.0, 140.0),
		"radius": 6.0,
		"timer": 15.0,
		"description": "Andén de la Estación Adrogué",
	},
	{
		"name": "Extracción Sur - Vías",
		"position": Vector3(280.0, 0.0, 280.0),
		"radius": 5.0,
		"timer": 10.0,
		"description": "Final sur de las vías",
	},
	{
		"name": "Extracción Clínica",
		"position": Vector3(350.0, 0.0, 40.0),
		"radius": 4.0,
		"timer": 20.0,
		"description": "Salida trasera de la Clínica Espora",
	},
]

# ── Player Spawn Points ───────────────────────────────────
const SPAWN_POINTS := [
	Vector3(-350.0, 1.0, -250.0),   # NW corner - residential
	Vector3(-350.0, 1.0, 230.0),    # SW corner - residential
	Vector3(-100.0, 1.0, -200.0),   # N center
	Vector3(50.0, 1.0, 230.0),      # S center
]

# ── Enemy Spawn Zones ─────────────────────────────────────
const ENEMY_SPAWNS := [
	{
		"faction": "bonaerense",
		"zone": "commercial_center",
		"count_range": [2, 4],
		"patrol_points": [
			Vector3(-100.0, 0.0, 150.0),
			Vector3(0.0, 0.0, 160.0),
			Vector3(50.0, 0.0, 140.0),
		],
	},
	{
		"faction": "la_banda",
		"zone": "residential_west",
		"count_range": [3, 5],
		"patrol_points": [
			Vector3(-300.0, 0.0, 0.0),
			Vector3(-250.0, 0.0, -100.0),
			Vector3(-200.0, 0.0, 50.0),
		],
	},
	{
		"faction": "sobrevivientes",
		"zone": "green_zone",
		"count_range": [1, 3],
		"patrol_points": [
			Vector3(150.0, 0.0, -200.0),
			Vector3(200.0, 0.0, -150.0),
		],
	},
	{
		"faction": "los_narcos",
		"zone": "train_station",
		"count_range": [2, 4],
		"patrol_points": [
			Vector3(260.0, 0.0, 120.0),
			Vector3(300.0, 0.0, 160.0),
			Vector3(280.0, 0.0, 180.0),
		],
	},
]

# ── Loot Container Placements ─────────────────────────────
const CONTAINER_PLACEMENTS := [
	{"position": Vector3(-300.0, 0.0, -100.0), "table": "residential_house", "type": "drawer"},
	{"position": Vector3(-250.0, 0.0, 50.0), "table": "residential_house", "type": "wardrobe"},
	{"position": Vector3(-150.0, 0.0, -50.0), "table": "residential_house", "type": "drawer"},
	{"position": Vector3(-100.0, 0.0, 150.0), "table": "generic", "type": "crate"},
	{"position": Vector3(0.0, 0.0, 160.0), "table": "generic", "type": "crate"},
	{"position": Vector3(50.0, 0.0, 140.0), "table": "police_station", "type": "locker"},
	{"position": Vector3(260.0, 0.0, 130.0), "table": "train_station", "type": "luggage"},
	{"position": Vector3(290.0, 0.0, 150.0), "table": "train_station", "type": "luggage"},
	{"position": Vector3(300.0, 0.0, 60.0), "table": "generic", "type": "medical_cabinet"},
	{"position": Vector3(-200.0, 0.0, -200.0), "table": "residential_house", "type": "drawer"},
	{"position": Vector3(100.0, 0.0, -180.0), "table": "generic", "type": "crate"},
	{"position": Vector3(-50.0, 0.0, 200.0), "table": "industrial_zone", "type": "toolbox"},
	{"position": Vector3(350.0, 0.0, 50.0), "table": "generic", "type": "medical_cabinet"},
	{"position": Vector3(-320.0, 0.0, -220.0), "table": "residential_house", "type": "wardrobe"},
	{"position": Vector3(200.0, 0.0, -120.0), "table": "generic", "type": "backpack"},
]

# ── Points of Interest ────────────────────────────────────
const POIS := [
	{"name": "Club Social y Deportivo", "position": Vector3(-300.0, 0.0, -230.0), "type": "landmark"},
	{"name": "Estación Adrogué", "position": Vector3(280.0, 0.0, 140.0), "type": "station"},
	{"name": "Clínica Espora", "position": Vector3(330.0, 0.0, 40.0), "type": "hospital"},
	{"name": "La Veneciana", "position": Vector3(200.0, 0.0, -30.0), "type": "shop"},
	{"name": "Escuela Secundaria", "position": Vector3(300.0, 0.0, 220.0), "type": "school"},
	{"name": "Plaza Central", "position": Vector3(-50.0, 0.0, 160.0), "type": "plaza"},
]

# ── Ambient Zone Audio ────────────────────────────────────
const AUDIO_ZONES := {
	"green_zone": {
		"ambient": "res://assets/audio/ambient/birds_suburban.ogg",
		"music": "",
		"reverb": "outdoor_open",
	},
	"residential_west": {
		"ambient": "res://assets/audio/ambient/suburban_desolate.ogg",
		"music": "",
		"reverb": "outdoor_street",
	},
	"commercial_center": {
		"ambient": "res://assets/audio/ambient/urban_abandoned.ogg",
		"music": "",
		"reverb": "outdoor_enclosed",
	},
	"train_station": {
		"ambient": "res://assets/audio/ambient/train_wind.ogg",
		"music": "",
		"reverb": "large_hall",
	},
	"hospital_area": {
		"ambient": "res://assets/audio/ambient/hospital_eerie.ogg",
		"music": "",
		"reverb": "indoor_large",
	},
}
