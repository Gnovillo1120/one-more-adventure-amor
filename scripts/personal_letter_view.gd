extends Panel
## The body is the supplied text, verbatim; headings and controls are separate.
var body: RichTextLabel

func setup(text: String) -> void:
	size=Vector2(1000,590)
	var paper:=StyleBoxFlat.new();paper.bg_color=Color("f4ead5");paper.border_color=Color("b59665");paper.set_border_width_all(3);add_theme_stylebox_override("panel",paper)
	var heading:=Label.new();heading.text="Para Anami";heading.position=Vector2(40,22);heading.size=Vector2(920,45);heading.add_theme_font_size_override("font_size",31);heading.add_theme_color_override("font_color",Color("6a4635"));add_child(heading)
	body=RichTextLabel.new();body.name="VerbatimLetter";body.position=Vector2(40,85);body.size=Vector2(920,410)
	body.bbcode_enabled=false;body.text=text;body.scroll_active=true;body.scroll_following=false;body.focus_mode=Control.FOCUS_ALL
	body.add_theme_font_size_override("normal_font_size",23);body.add_theme_color_override("default_color",Color("352c2b"));body.add_theme_constant_override("line_separation",7);add_child(body)
	var hint:=Label.new();hint.text="Lee a tu ritmo · Rueda / ↑ ↓ / RePág / AvPág / Inicio / Fin";hint.position=Vector2(40,525);hint.size=Vector2(590,40);hint.add_theme_font_size_override("font_size",16);hint.add_theme_color_override("font_color",Color("6a4635"));add_child(hint)

func scroll_key(code: int) -> bool:
	var bar:=body.get_v_scroll_bar()
	match code:
		KEY_HOME:bar.value=0
		KEY_END:bar.value=bar.max_value
		KEY_UP:bar.value-=40
		KEY_DOWN:bar.value+=40
		KEY_PAGEUP:bar.value-=bar.page*.85
		KEY_PAGEDOWN:bar.value+=bar.page*.85
		_:return false
	return true
