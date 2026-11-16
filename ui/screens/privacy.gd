extends Screen

const TEXT := """TEMPLATE - have this reviewed by a lawyer and fill in your company details before publishing.

What we store
- Game progress, scores, settings and purchases are stored on your device.
- If you create an account or sign in as a guest, your email (if provided), display name, scores and cloud save are stored on our servers (Supabase) so rankings and cloud save work.

Advertising
- If ads are enabled in your version, our ad partner may collect your advertising ID and device information to show ads. Personalised ads are only enabled if you accept in the consent prompt. You can change your choice at any time in Settings > Privacy.

Purchases
- Purchases are processed by Google Play. We receive a purchase token to verify the purchase; we never see your payment details.

Your choices
- You can reset local data in Settings. To delete your online account and data, contact support.

Children
- This game is not directed at children under 13 and does not knowingly collect their data.

Contact
- See Support and Feedback in the app."""

func on_back() -> void:
	main.go("settings")

func build() -> void:
	begin_page("Privacy Policy", false, "settings")
	add_text(TEXT, 24, "text", HORIZONTAL_ALIGNMENT_LEFT, false)
	var url := str(Settings_app().get("privacy_url", ""))
	if url != "":
		add_button("Open full policy online", func(): Platform.open_url(url), "secondary")

func Settings_app() -> Dictionary:
	return preload("res://ui/screens/settings.gd")._app_info()
