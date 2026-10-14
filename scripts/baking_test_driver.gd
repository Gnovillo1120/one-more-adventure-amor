extends RefCounted
## QA driver for physical actions; never called by normal gameplay.
func bake(s: RefCounted, perfect: bool = true) -> void:
	if s.state.phase=="intro":s.act("start")
	while s.state.phase=="quiz":s.act("quiz",0)
	if s.state.phase=="gather":
		for item in s.data.ingredients:s.act("ingredient",item.id)
		if not perfect:s.act("ingredient","pepper")
		s.act("gather")
	while s.state.phase=="measure":
		for i in range(5 if perfect else 2):s.act("pour",.2)
		s.act("measure")
	for phase in ["dry","cream"]:
		if s.state.phase==phase:
			for i in range(10):s.act("mix",.15)
			s.act("mixed")
	while s.state.phase=="eggs":
		s.act("tap")
		if perfect:s.act("tap")
		s.act("crack")
	for phase in ["combine","oats"]:
		if s.state.phase==phase:
			for i in range(3):s.act("add")
			for i in range(10):s.act("mix",.15)
			s.act("mixed")
	if s.state.phase=="chill":s.act("chill")
	if s.state.phase=="preheat":s.act("temperature",190 if perfect else 220);s.act("preheat")
	if s.state.phase=="tray":
		if perfect:s.act("spray")
		for pos in s.default_portions():s.act("portion",pos if perfect else [.5,.5])
		s.act("portioned")
	if s.state.phase=="flatten":
		for i in range(6):s.act("dip");s.act("flatten",i)
	if s.state.phase=="oven":
		s.act("insert");s.act("mitts");s.tick(36 if perfect else 60)
		if perfect:s.act("swap")
		s.act("pull")
	if s.state.phase=="cool":s.tick(5);s.act("rack")
	if s.state.phase=="taste":s.act("taste")
