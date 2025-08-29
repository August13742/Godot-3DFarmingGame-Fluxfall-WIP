extends RefCounted
class_name IJobTask

func post(_job: FarmJob) -> void: pass
func try_reserve_best(_worker_id: int) -> FarmJob: return null
func release(_job: FarmJob) -> void: pass
func complete(_job: FarmJob, _success: bool) -> void: pass
func can_execute(_worker, _job: FarmJob) -> bool: return false
func execute(_worker, _job: FarmJob) -> bool: return false   # return success/fail
