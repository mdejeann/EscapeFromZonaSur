# 🎨 Art Pipeline — Blender → Godot

> Escape From Zona Sur · Godot 4.4 · Blender 3.6+ LTS

---

## 1. Convenciones generales

| Regla | Detalle |
|-------|---------|
| Escala | **1 unidad = 1 metro** en Blender y Godot |
| Origin | Centro de masa del objeto (Apply All Transforms antes de exportar) |
| Nombrado | `snake_case` para todos los archivos (`fp_arms.glb`, `pistol_9mm.glb`) |
| Orientación | Forward = **-Z** (convención Godot), Up = **+Y** |
| Formato de export | `.glb` (GLTF Binary) — animaciones embebidas |

---

## 2. Pipeline de exportación

### Paso 1: Modelado en Blender

1. Modelar el asset respetando la escala de 1 unidad = 1 metro.
2. Aplicar todas las transformaciones: `Ctrl+A → All Transforms`.
3. Nombrar meshes, materiales y armatures en `snake_case`.
4. Verificar normales (`Display → Face Orientation` en viewport overlay).

### Paso 2: Rig y animaciones (si aplica)

1. Crear armature con huesos nombrados en `snake_case` (ej: `hand_l`, `hand_r`, `finger_index_l`).
2. Crear acciones (Actions) separadas para cada animación (`idle`, `fire`, `reload`, `walk`).
3. Habilitar **Stash** en cada acción para no perderlas al exportar.
4. Verificar que las animaciones funcionen con `Push Down` a la NLA Strip.

### Paso 3: Exportación a .glb

1. `File → Export → glTF 2.0 (.glb/.gltf)`.
2. Configuración de exportación:
   - Format: **glTF Binary (.glb)**
   - Include: ☑ Selected Objects (si exportás un solo asset)
   - Transform: +Y Up (default)
   - Mesh: ☑ Apply Modifiers, ☑ UVs, ☑ Normals, ☑ Tangents, ☑ Vertex Colors
   - Animation: ☑ Animations, ☑ Limit to Playback Range, ☑ Always Sample Animations
3. Guardar en la carpeta correspondiente dentro de `assets/models/`.

### Paso 4: Importación en Godot

1. Godot detecta automáticamente archivos `.glb` y genera el `.import`.
2. Seleccionar el asset en FileSystem y configurar:
   - **Meshes → Light Baking**: `Static` para props estáticos.
   - **Animation → Import**: Verificar que todas las animaciones se importaron.
   - **Scale**: Debe ser `1.0` si la escala en Blender era correcta.
3. Crear escena derivada (`.tscn`) si se necesita agregar colisiones o scripts.

---

## 3. Estructura de carpetas para assets

```
assets/
├── models/
│   ├── player/
│   │   └── fp_arms.glb          # Brazos FP (3 huesos: shoulder, elbow, wrist)
│   ├── weapons/
│   │   └── pistol_9mm.glb       # Placeholder geométrico de pistola
│   └── environment/
│       ├── props/                # Objetos sueltos (sillas, mesas, etc.)
│       ├── buildings/            # Estructuras grandes
│       └── vegetation/           # Árboles, arbustos
├── textures/
│   ├── environment/
│   │   └── adrogue_atlas.png    # Atlas 2048×2048
│   └── ui/
└── audio/
```

---

## 4. Atlas de texturas de entorno

### Especificaciones del atlas de Adrogue

| Propiedad | Valor |
|-----------|-------|
| Resolución | 2048 × 2048 px |
| Formato | PNG (sRGB) |
| Tiles | Grid de 4×4 (512px cada tile) |
| Filtering | Linear Mipmap en Godot |

### Tiles del atlas

| Posición | Tile | Uso |
|----------|------|-----|
| (0,0) | Vereda gris | Veredas de Adrogue |
| (1,0) | Asfalto | Calles y rutas |
| (2,0) | Ladrillo rojo | Paredes de casas |
| (3,0) | Ladrillo pintado | Paredes con grafiti/pintura |
| (0,1) | Reja metálica | Rejas de casas y portones |
| (1,1) | Pared con humedad | Paredes interiores deterioradas |
| (2,1) | Baldosa rota | Pisos interiores |
| (3,1) | Chapa oxidada | Techos y paredes de zona industrial |
| (0,2) | Cemento liso | Pisos de galpón |
| (1,2) | Tierra | Terrenos baldíos |
| (2,2) | Pasto seco | Jardines abandonados |
| (3,2) | Madera vieja | Puertas y muebles |
| (0,3) | Metal pintado | Containers y vehículos |
| (1,3) | Vidrio roto | Ventanas de locales |
| (2,3) | Tela/lona | Carpas y cubiertas improvisadas |
| (3,3) | Agua sucia | Charcos y cunetas |

---

## 5. Convenciones de nombrado de assets

### Archivos

```
[tipo]_[nombre]_[variante].[ext]

Ejemplos:
  prop_chair_broken.glb
  weapon_pistol_9mm.glb
  tex_adrogue_atlas.png
  mat_brick_red.tres
  sfx_footstep_concrete_01.wav
```

### Materiales en Blender

```
mat_[surface]_[color/variant]

Ejemplos:
  mat_brick_red
  mat_concrete_wet
  mat_metal_rusty
```

### Huesos de armature

```
[nombre]_[lado]

Ejemplos:
  hand_l, hand_r
  finger_index_l
  shoulder_l
```

---

## 6. Reglas para todos los agentes

1. **Nunca bloquear desarrollo por falta de arte** — usar CSG o `MeshInstance3D` con primitivas.
2. **Todo asset final pasa por este pipeline** antes de integrarse al proyecto.
3. **No committear archivos `.blend`** — solo `.glb` exportados.
4. **Los `.import` se versionan** (Godot los necesita para configuración de importación).
5. **El atlas de texturas es compartido** — coordinar cambios con `@world` y `@art`.
