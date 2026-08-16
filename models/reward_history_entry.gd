class_name RewardHistoryEntry
extends Resource

var reward_record_id := ""
var activity_record_id := ""
var activity_id := ""
var coin_reward := 0
var item_rewards: Dictionary = {}
var generated_at := 0.0
var applied_at := 0.0
var is_applied := false

func to_dict() -> Dictionary:
	return {
		"reward_record_id": reward_record_id,
		"activity_record_id": activity_record_id,
		"activity_id": activity_id,
		"coin_reward": coin_reward,
		"item_rewards": item_rewards.duplicate(true),
		"generated_at": generated_at,
		"applied_at": applied_at,
		"is_applied": is_applied
	}

static func from_dict(data: Dictionary) -> RewardHistoryEntry:
	var entry := RewardHistoryEntry.new()
	entry.reward_record_id = str(data.get("reward_record_id", ""))
	entry.activity_record_id = str(data.get("activity_record_id", ""))
	entry.activity_id = str(data.get("activity_id", ""))
	entry.coin_reward = maxi(0, int(data.get("coin_reward", 0)))
	if data.get("item_rewards", {}) is Dictionary:
		for raw_id: Variant in data.get("item_rewards", {}).keys():
			var amount := maxi(0, int(data.get("item_rewards", {})[raw_id]))
			if amount > 0:
				entry.item_rewards[str(raw_id)] = amount
	entry.generated_at = maxf(0.0, float(data.get("generated_at", 0.0)))
	entry.applied_at = maxf(0.0, float(data.get("applied_at", 0.0)))
	entry.is_applied = bool(data.get("is_applied", false))
	return entry
