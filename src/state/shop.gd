class_name Shop
extends RefCounted
## The Versalhes merchant (scene r05; prices from economia-progressao.json
## "precos"). Every purchase is one [method GameState.apply] call: the Bronze
## is spent only if the goods are delivered, so a full bag of bread or no
## empty flask never costs anything (auditoria-e-decisoes.md item 14).

## Offers in display order: id, label, price, effects (without the payment).
var offers: Array = []


## Builds the offers from [param config]'s prices and item data.
func _init(config: GameConfig) -> void:
	var prices: Dictionary = config.progression.get("precos", {})
	var bread: Dictionary = config.items.get("pao_porto", {})
	offers = [
		{
			"id": "pao_porto",
			"label": "%s (+%d de vida)" % [config.item_name("pao_porto"), int(config.progression.get("recuperacao", {}).get("pao_vida", 1))],
			"price": int(prices.get("pao_de_porto", 5)),
			"effects": [{"op": "add_item", "item_id": "pao_porto", "quantity": 1, "stack_limit": int(bread.get("stack_limit", 10))}],
		},
		{
			"id": "recarga_restauradora",
			"label": "Recarga restauradora (enche um frasco)",
			"price": int(prices.get("recarga_restauradora", 20)),
			"effects": [{"op": "refill_flask"}],
		},
		{
			# Sold only once the player has had charges (ferramentas.md §3).
			"id": "tres_cargas",
			"label": "Três %s" % config.item_name("carga_bronze").replace("Carga", "Cargas"),
			"price": int(prices.get("tres_cargas", 12)),
			"requires_flag": "gear.cargas",
			"effects": [{"op": "add_item", "item_id": "carga_bronze", "quantity": 3, "stack_limit": int(config.items.get("carga_bronze", {}).get("stack_limit", 9))}],
		},
	]


## The offers shown to the player now: one that needs a flag
## ("requires_flag") stays hidden until it is set.
func for_state(state: GameState) -> Array:
	return offers.filter(func(o: Dictionary) -> bool:
		var need := str(o.get("requires_flag", ""))
		return need.is_empty() or state.has_flag(need))


## Why [param offer] cannot be bought now, or "" when it can.
func refusal(state: GameState, offer: Dictionary) -> String:
	if state.bronze < int(offer["price"]):
		return "Bronze insuficiente."
	if str(offer["id"]) == "recarga_restauradora":
		if state.flasks().is_empty():
			return "Você não tem frasco."
		if state.full_flask_count() >= state.flasks().size():
			return "Seus frascos já estão cheios."
	if str(offer["id"]) == "pao_porto" and state.item_count("pao_porto") >= int(offer["effects"][0]["stack_limit"]):
		return "Não cabe mais pão."
	if str(offer["id"]) == "tres_cargas":
		var fx: Dictionary = offer["effects"][0]
		if state.item_count(str(fx["item_id"])) + int(fx["quantity"]) > int(fx["stack_limit"]):
			return "Não cabem mais cargas (máximo %d)." % int(fx["stack_limit"])
	return ""


## Buys [param offer] in one transaction. Returns true when delivered.
func buy(state: GameState, offer: Dictionary) -> bool:
	if not for_state(state).has(offer) or not refusal(state, offer).is_empty():
		return false
	var effects: Array = [{"op": "spend_bronze", "amount": int(offer["price"])}]
	effects.append_array(offer["effects"])
	return state.apply(effects)
