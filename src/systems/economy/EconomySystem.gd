# EconomySystem.gd
# Autoload — gestiona la moneda del jugador y las transacciones de compra/venta con NPCs.
# Los precios se calculan desde base_value del ItemData con multiplicadores por vendedor.
# Agente responsable: @gameplay
extends Node


## Ruta del archivo donde se persiste la billetera del jugador.
const WALLET_PATH: String = "user://wallet.json"

## Multiplicador sobre base_value que paga el vendedor al comprarle al jugador.
@export var sell_price_multiplier: float = 0.5

## Multiplicador sobre base_value que cobra el vendedor al jugador.
@export var buy_price_multiplier: float = 1.2

## Moneda actual del jugador (pesos).
var currency: int = 0


func _ready() -> void:
	_load_wallet()


# ── API pública ───────────────────────────────────────────────────────────────

## Retorna el precio de venta (jugador → NPC) de un ítem.
func get_sell_price(item_data: Resource, quantity: int = 1) -> int:
	return int(item_data.base_value * sell_price_multiplier) * quantity


## Retorna el precio de compra (NPC → jugador) de un ítem.
func get_buy_price(item_data: Resource, quantity: int = 1) -> int:
	return int(item_data.base_value * buy_price_multiplier) * quantity


## El jugador vende un ítem de su inventario al NPC.
## Retorna true si la transacción fue exitosa.
func sell_item(item_data: Resource, quantity: int, inventory: Node) -> bool:
	if not inventory.has_item(item_data.id, quantity):
		EventBus.hud_message_requested.emit("No tenés ese ítem en el inventario", 1.5)
		return false

	var earnings := get_sell_price(item_data, quantity)
	inventory.remove_item(item_data.id, quantity)
	_add_currency(earnings)
	EventBus.item_sold.emit(item_data, quantity, earnings)
	return true


## El jugador compra un ítem al NPC agregándolo al inventario.
## Retorna true si la transacción fue exitosa.
func buy_item(item_data: Resource, quantity: int, inventory: Node) -> bool:
	var cost := get_buy_price(item_data, quantity)
	if currency < cost:
		EventBus.hud_message_requested.emit("No tenés plata suficiente", 1.5)
		return false

	if not inventory.add_item(item_data, quantity):
		EventBus.hud_message_requested.emit("El inventario está lleno", 1.5)
		return false

	_spend_currency(cost)
	EventBus.item_purchased.emit(item_data, quantity, cost)
	return true


## Agrega moneda directamente (recompensas, loot de cash_pesos, etc.).
func add_currency(amount: int) -> void:
	_add_currency(amount)


## Retorna la moneda actual del jugador.
func get_currency() -> int:
	return currency


# ── Privado ───────────────────────────────────────────────────────────────────

func _add_currency(amount: int) -> void:
	currency += amount
	_save_wallet()
	EventBus.currency_changed.emit(currency)


func _spend_currency(amount: int) -> void:
	if amount > currency:
		push_warning("EconomySystem: intento de gastar %d pero solo hay %d disponibles." % [amount, currency])
	currency = max(0, currency - amount)
	_save_wallet()
	EventBus.currency_changed.emit(currency)


func _save_wallet() -> void:
	var file := FileAccess.open(WALLET_PATH, FileAccess.WRITE)
	if not file:
		push_warning("EconomySystem: no se pudo escribir en '%s'" % WALLET_PATH)
		return
	file.store_string(JSON.stringify({"currency": currency}))


func _load_wallet() -> void:
	if not FileAccess.file_exists(WALLET_PATH):
		return
	var file := FileAccess.open(WALLET_PATH, FileAccess.READ)
	if not file:
		push_warning("EconomySystem: no se pudo leer '%s'" % WALLET_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		currency = int(json.data.get("currency", 0))
	else:
		push_warning("EconomySystem: error al parsear wallet.json")
