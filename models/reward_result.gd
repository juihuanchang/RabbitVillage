class_name RewardResult
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
	return {"reward_record_id": reward_record_id, "activity_record_id": activity_record_id,
		"activity_id": activity_id, "coin_reward": coin_reward, "item_rewards": item_rewards.duplicate(),
		"generated_at": generated_at, "applied_at": applied_at, "is_applied": is_applied}

static func from_dict(data: Dictionary) -> RewardResult:
	var result := RewardResult.new(); result.reward_record_id = str(data.get("reward_record_id", ""))
	result.activity_record_id = str(data.get("activity_record_id", "")); result.activity_id = str(data.get("activity_id", ""))
	result.coin_reward = maxi(0, int(data.get("coin_reward", 0)))
	if data.get("item_rewards", {}) is Dictionary: result.item_rewards = data.get("item_rewards", {}).duplicate()
	result.generated_at = float(data.get("generated_at", 0.0)); result.applied_at = float(data.get("applied_at", 0.0))
	result.is_applied = bool(data.get("is_applied", false)); return result
